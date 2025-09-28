import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter_application_1/screen/admin/report_pdf.dart';
import 'dart:typed_data';
import 'dart:io' show File, Directory; // only for mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/screen/admin/web_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';




class ReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final Color priorityColor;
  final String timeAgo;
  final VoidCallback onMarkInProgress;
  final double? fixedHeight;
  final Function(double) onHeightMeasured;
  final VoidCallback onCompleted;

  const ReportCard({
    super.key,
    required this.report,
    required this.priorityColor,
    required this.timeAgo,
    required this.onMarkInProgress,
    this.fixedHeight,
    required this.onHeightMeasured,
    required this.onCompleted,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  
  List<Map<String, dynamic>> _assignments = [];
  bool _loadingAssignments = true;
  DateTime? _reportDeadline;
  bool _loadingDeadline = true;
  int _currentImageIndex = 0;
  late PageController _pageController;
  final GlobalKey _cardKey = GlobalKey();

  bool? _actionAccepted;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
    _loadAssignments();
    _loadDeadline();
  }

//calling the controller
  Future<void> _notifyCitizenStatusChange(String reportId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/notif/reportStatusChange"), // your backend endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "report_id": reportId,
          "newStatus": newStatus,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Citizen notification triggered successfully");
      } else {
        print("❌ Citizen notification failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Error notifying citizen: $e");
    }
  }


  Future<void> _loadDeadline() async {
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('reports')
          .select('report_deadline')
          .eq('report_id', widget.report['reportId'])
          .maybeSingle();

      if (!mounted) return; // 👈 guard before touching setState

      if (result == null || result['report_deadline'] == null) {
        setState(() {
          _reportDeadline = null;
          _loadingDeadline = false;
        });
        return;
      }

      // parse timestamp directly
      setState(() {
        _reportDeadline = DateTime.parse(result['report_deadline']);
        _loadingDeadline = false;
      });
    } catch (e) {
      print("Error fetching report_deadline: $e");
      if (!mounted) return; // 👈 guard inside catch too
      setState(() => _loadingDeadline = false);
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Get assignments for this report
      final assignments = await supabase
          .from('report_assignments')
          .select('official_id, assigned_at')
          .eq('report_id', widget.report['reportId'])
          .order('assigned_at', ascending: false);

      if (!mounted) return; // 👈 guard immediately after async call

      if (assignments.isEmpty) {
        setState(() {
          _assignments = [];
          _loadingAssignments = false;
          widget.report["proofImage"] = null; // clear proof if no assignments
        });
        return;
      }

      List<Map<String, dynamic>> enriched = [];

      for (var a in assignments) {
        final userId = a['official_id'];

        try {
          // Get user details directly
          final user = await supabase
              .from('users')
              .select('name, user_profile_url')
              .eq('user_id', userId)
              .maybeSingle();

          if (user != null) {
            enriched.add({
              'assigned_at': a['assigned_at'],
              'name': user['name'] ?? 'User ID: $userId',
              'avatar': user['user_profile_url'] ?? 'assets/profile picture.png',
            });
          } else {
            // fallback: official
            final official = await supabase
                .from('officials')
                .select('name')
                .eq('user_id', userId)
                .maybeSingle();

            enriched.add({
              'assigned_at': a['assigned_at'],
              'name': official?['name'] ?? 'User ID: $userId',
              'avatar': 'assets/profile picture.png',
            });
          }
        } catch (e) {
          print("Error fetching user $userId: $e");
          enriched.add({
            'assigned_at': a['assigned_at'],
            'name': 'User ID: $userId (Error)',
            'avatar': 'assets/profile picture.png',
          });
        }
      }

      // 2. Fetch proof (after photos) from report_solutions
      try {
        final solution = await supabase
            .from('report_solutions')
            .select('after_photo_urls')
            .eq('report_id', widget.report['reportId'])
            .order('updated_at', ascending: false)
            .maybeSingle();

        if (solution != null && solution['after_photo_urls'] != null) {
          final List<dynamic> urls = solution['after_photo_urls'];
          if (urls.isNotEmpty) {
            // Store first photo (or use urls.last for latest)
            widget.report["proofImage"] = urls.first as String;
          }
        }
      } catch (e) {
        print("Error fetching proof image: $e");
        widget.report["proofImage"] = null;
      }

      if (!mounted) return; // 👈 guard again before final setState
      setState(() {
        _assignments = enriched;
        _loadingAssignments = false;
      });
    } catch (e) {
      print("Error fetching assignments: $e");
      if (!mounted) return;
      setState(() => _loadingAssignments = false);
    }
  }



  


  void _measureHeight() {
    final context = _cardKey.currentContext;
    if (context != null) {
      final height = context.size?.height ?? 0;
      widget.onHeightMeasured(height);
    }
  }

  void _goToImage(int index) {
    final imgs = List<String>.from(widget.report["images"]);
    if (index >= 0 && index < imgs.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openImageDialog({Uint8List? bytes, String? url, String? path}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center( // 👈 ensures it's centered and takes available space
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.8, // take 80% of screen
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildProofImage(bytes, url ?? path, BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showDecisionBar({
    required bool accepted,
    required StateSetter setModalState,
    required BuildContext messengerCtx,
  }) {
    final messenger = ScaffoldMessenger.of(messengerCtx);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: accepted ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(
              accepted ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(accepted ? "Action accepted" : "Action rejected"),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _actionAccepted = null);
            setModalState(() {});
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openActionModal(BuildContext context) {
  String getDeadlineSubtitle() {
    if (_loadingDeadline) return "Loading...";
    if (_reportDeadline == null) return "Deadline: N/A";

    final now = DateTime.now();
    final difference = _reportDeadline!.difference(now);

    if (difference.isNegative) return "Deadline Passed";

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days == 0 && hours == 0) return "Deadline: Less than an hour left";
    if (days == 0) return "Deadline: $hours hour${hours > 1 ? 's' : ''} left";
    if (hours == 0) return "Deadline: $days day${days > 1 ? 's' : ''} left";

    return "Deadline: $days day${days > 1 ? 's' : ''}, $hours hour${hours > 1 ? 's' : ''} left";
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final bool hasProof = true;
          final bool stepAssignedCompleted = true;
          final bool stepWaitingCompleted =
              (widget.report["status"]?.toString().toLowerCase() ?? "") != "waiting";
          final bool stepProofCompleted = hasProof && (_actionAccepted == true);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Report Action",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (Navigator.of(sheetCtx).canPop()) {
                            Navigator.of(sheetCtx).pop();
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Timeline steps
                  _buildTimelineStep(
                    title: "Deployment personnel assigned",
                    subtitle: _loadingAssignments
                        ? "Loading..."
                        : _assignments.isNotEmpty
                            ? "Assigned to: ${_assignments.map((a) => a['name']).join(', ')}"
                            : "Assigned to: N/A",
                    completed: stepAssignedCompleted,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Waiting for action",
                    subtitle: getDeadlineSubtitle(),
                    completed: stepWaitingCompleted || hasProof,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Proof of Action",
                    subtitle: (_actionAccepted == null
                        ? "Awaiting decision"
                        : (_actionAccepted == true ? "Accepted" : "Rejected")),
                    completed: _actionAccepted == true,
                    trailing: GestureDetector(
                      onTap: () {
                        _openImageDialog(
                          url: widget.report["proofImage"],
                        );
                      },
                      child: buildProofImage(null, widget.report["proofImage"]),
                    ),
                    isLast: true,
                  ),
                  const SizedBox(height: 16),

                  // Decision buttons
                  if (_actionAccepted == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final supabase = Supabase.instance.client;
                                final int reportId =
                                    int.parse(widget.report['reportId'].toString());

                                // Update report status
                                await supabase
                                    .from('report_solutions')
                                    .update({'new_status': 'resolved'})
                                    .eq('report_id', reportId);

                                // Notify citizen
                                await _notifyCitizenStatusChange(reportId.toString(), 'resolved');

                                if (!mounted) return;
                                setState(() => _actionAccepted = true);
                                setModalState(() {});

                                // Show snack
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text("Action Accepted ✅"),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Inform parent
                                widget.onCompleted();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text("Error updating status: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.thumb_up),
                            label: const Text("Accept"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final supabase = Supabase.instance.client;
                                final int reportId =
                                    int.parse(widget.report['reportId'].toString());

                                await supabase
                                    .from('reports')
                                    .update({'status': 'in_progress'})
                                    .eq('report_id', reportId);

                                if (!mounted) return;
                                setState(() => _actionAccepted = false);
                                setModalState(() {});

                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text("Action Rejected ❌"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  SnackBar(
                                    content: Text("Error updating status: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.thumb_down),
                            label: const Text("Reject"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Chip status
                  if (_actionAccepted != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: Icon(
                          _actionAccepted == true ? Icons.check_circle : Icons.cancel,
                        ),
                        label: Text(
                          _actionAccepted == true ? "Action Accepted" : "Action Rejected",
                        ),
                        backgroundColor: _actionAccepted == true
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        side: BorderSide(
                          color: _actionAccepted == true ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Generate PDF
                  if (_actionAccepted == true)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final pdfBytes = await ReportPdf.generate(context, widget.report);
                          if (pdfBytes == null) return;

                          if (kIsWeb) {
                            downloadPdfWeb(pdfBytes, "report.pdf");
                          } else {
                            await Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) async => pdfBytes,
                            );
                          }

                          widget.onCompleted();
                          if (Navigator.of(sheetCtx).canPop()) {
                            Navigator.of(sheetCtx).pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              SnackBar(
                                content: Text("Error generating PDF: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Generate Report"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildTimelineStep({
    required String title,
    String? subtitle,
    required bool completed,
    Widget? trailing,
    bool isLast = false,
  }) {
    final Color activeColor = completed ? Colors.green : Colors.grey;
    final Color lineColor = completed ? Colors.green : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: activeColor,
              size: 22,
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: lineColor),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(height: 8),
                trailing,
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hazardous = widget.report["hazardous"] == true;
    final images = List<String>.from(widget.report["images"]);

    final cardContent = Container(
      key: _cardKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image area
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                        );
                      },
                    );
                  },
                ),
              ),
              // Priority ribbon
              Positioned(
                top: 8,
                right: -28,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 90),
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    color: widget.priorityColor,
                    child: Center(
                      child: Text(
                        widget.report["priority"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Image nav arrows
              if (_currentImageIndex > 0)
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _goToImage(_currentImageIndex - 1),
                    child: const SizedBox(
                      width: 40,
                      child: Icon(Icons.chevron_left,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              if (_currentImageIndex < images.length - 1)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _goToImage(_currentImageIndex + 1),
                    child: const SizedBox(
                      width: 40,
                      child: Icon(Icons.chevron_right,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              // Dots
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final bool active = _currentImageIndex == index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: active ? 8 : 6,
                      height: active ? 8 : 6,
                      decoration: BoxDecoration(
                        color:
                            active ? Colors.white : Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          // Text + Action button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User + location + hazard + time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage("assets/profile picture.png"),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.report["userName"],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.report["location"],
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        hazardous ? Colors.red : Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    hazardous ? "Hazardous" : "Safe",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "• ${widget.timeAgo}",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.report["description"],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.25),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openActionModal(context),
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text("Make an Action"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.fixedHeight != null) {
      return SizedBox(height: widget.fixedHeight, child: cardContent);
    }
    return cardContent;
  }
}