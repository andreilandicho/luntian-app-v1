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
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  final TextEditingController _commentController = TextEditingController();


  bool? _actionAccepted;

  Map<String, dynamic>? _latestSolution;
  bool _loadingSolution = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
    _loadAssignments();
    _loadDeadline();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  //Helper services for accepting and rejticng solution submissions
  // Helper: Get latest solution for this report
  Future<Map<String, dynamic>?> _fetchLatestSolution(int reportId) async {
    setState(() => _loadingSolution = true);
    final supabase = Supabase.instance.client;
    final solution = await supabase
        .from('report_solutions')
        .select()
        .eq('report_id', reportId)
        .eq('approval_status', 'pending')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    setState(() {
      _latestSolution = solution;
      _loadingSolution = false;
    });
    return solution;
  }

  // Accept solution
  Future<void> _acceptLatestSolution(int reportId, String comment) async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");

    // 1. Fetch latest solution
    final latestSolution = await _fetchLatestSolution(reportId);
    if (latestSolution == null) throw Exception("No solution found for this report");
    final solutionId = latestSolution['update_id'];

    // 2. Update reports table
    await supabase.from('reports')
        .update({'status': 'resolved'})
        .eq('report_id', reportId);

    // 3. Update report_solutions table
    await supabase.from('report_solutions')
        .update({'new_status': 'resolved', 'approval_status': 'approved'})
        .eq('update_id', solutionId);

    // 4. Insert into solution_approvals
    await supabase.from('solution_approvals').insert({
      'solution_id': solutionId,
      'reviewed_by': userId,
      'status': 'approved',
      'comments': comment.isEmpty ? 'Approved by admin' : comment,
    });

    // ✅ Notify citizen
    await _notifyCitizenStatusChange(reportId.toString(), 'resolved');
  }

  // Reject solution
  Future<void> _rejectLatestSolution(int reportId, String comment) async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");

    // 1. Fetch latest solution
    final latestSolution = await _fetchLatestSolution(reportId);
    if (latestSolution == null) throw Exception("No solution found for this report");
    final solutionId = latestSolution['update_id'];

    // 2. Update reports table
    await supabase.from('reports')
        .update({'status': 'in_progress'})
        .eq('report_id', reportId);

    // 3. Update report_solutions table
    await supabase.from('report_solutions')
        .update({'new_status': 'in_progress', 'approval_status': 'rejected'})
        .eq('update_id', solutionId);

    // 4. Insert into solution_approvals
    await supabase.from('solution_approvals').insert({
      'solution_id': solutionId,
      'reviewed_by': userId,
      'status': 'rejected',
      'comments': comment.isEmpty ? 'Rejected by admin' : comment,
    });
  }


//calling the controller
  Future<void> _notifyCitizenStatusChange(String reportId, String newStatus) async {
    try {
      //request url
      final response = await http.post(
        Uri.parse("http://luntian-app-v1-production.up.railway.app/notif/reportStatusChange"), // your backend endpoint
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

  Future<void> _openMap(String location) async {
    final query = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query&t=k");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open map")),
      );
    }
  }

  bool hasValidLocation(dynamic loc) {
    if (loc == null) return false;
    if (loc is! String) return false;
    final trimmed = loc.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return false;
    return true;
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
        final solutions = await supabase
            .from('report_solutions')
            .select('after_photo_urls, cleanup_notes')
            .eq('report_id', widget.report['reportId'])
            .order('updated_at', ascending: false);

        List<String> allImages = [];
        String? cleanupNotes; // 👈 Add variable to store cleanup notes

        for (var s in solutions) {
          // Collect proof images
          if (s['after_photo_urls'] != null) {
            final List<dynamic> urls = s['after_photo_urls'];
            allImages.addAll(urls.cast<String>());
          }

          // Capture cleanup_notes (take the first non-empty one)
          if (s['cleanup_notes'] != null &&
              s['cleanup_notes'].toString().trim().isNotEmpty &&
              cleanupNotes == null) {
            cleanupNotes = s['cleanup_notes'];
          }
        }

        // Save to widget.report
        widget.report["proofImages"] = allImages.isNotEmpty ? allImages : [];
        widget.report["cleanupNotes"] = cleanupNotes ?? ""; // 👈 Store the notes
      } catch (e) {
        print("Error fetching proof images: $e");
        widget.report["proofImages"] = [];
        widget.report["cleanupNotes"] = ""; // also handle this in error case
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
          if (_loadingSolution) {
              return const Center(child: CircularProgressIndicator());
            }
          final List proofImages = _latestSolution?["after_photo_urls"] as List? ?? [];
            final String cleanupNotes = _latestSolution?["cleanup_notes"] ?? "No cleanup notes.";
            final bool hasProof = proofImages.isNotEmpty;

          final bool stepAssignedCompleted = _assignments.isNotEmpty;
            final bool stepWaitingCompleted =
                (widget.report["status"]?.toString().toLowerCase() ?? "") != "waiting";
           

          // Step proof should be completed if there is proof, regardless of accept/reject
          final bool stepProofCompleted = hasProof;


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
                        ? (hasProof ? "Proof submitted, awaiting decision" : "Awaiting proof")
                        : (_actionAccepted == true ? "Accepted" : "Rejected")),
                    completed: stepProofCompleted,
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasProof)
                          SizedBox(
                            height: 60,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: proofImages.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final url = proofImages[index];
                                  return GestureDetector(
                                    onTap: () => _openImageDialog(url: url),
                                    child: buildProofImage(null, url),
                                );
                              },
                            ),
                          )
                        else
                          const Text("No proof available"),

                        const SizedBox(height: 12),

                        // ✅ Styled cleanup notes
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.sticky_note_2_outlined, color: Colors.blueGrey, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cleanupNotes.isNotEmpty ? cleanupNotes : "No cleanup notes provided.",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    isLast: true,
                  ),
                  const SizedBox(height: 16),

                  // 📝 Admin Comment Input
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Add Comment",
                      hintText: "Write your feedback or remarks here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
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
                                  final int reportId = int.parse(widget.report['reportId'].toString());
                                  await _acceptLatestSolution(reportId, _commentController.text.trim());
                                  if (!mounted) return;
                                  setState(() => _actionAccepted = true);
                                  setModalState(() {});
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    const SnackBar(content: Text("Action Accepted ✅"), backgroundColor: Colors.green),
                                  );
                                  widget.onCompleted();
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
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
                                  final int reportId = int.parse(widget.report['reportId'].toString());
                                  await _rejectLatestSolution(reportId, _commentController.text.trim());
                                  if (!mounted) return;
                                  setState(() => _actionAccepted = false);
                                  setModalState(() {});
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    const SnackBar(content: Text("Action Rejected ❌"), backgroundColor: Colors.red),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
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
                                  child: widget.report["location"] != null && widget.report["location"].isNotEmpty
                                      ? TextButton.icon(
                                          onPressed: () => _openMap(widget.report["location"]),
                                          icon: const Icon(Icons.location_on, size: 16, color: Colors.blue),
                                          label: const Text(
                                            "View on Map",
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        )
                                      : TextButton.icon(
                                          onPressed: null, // This properly disables the button
                                          icon: const Icon(Icons.location_off, size: 16, color: Colors.grey),
                                          label: const Text(
                                            "Not Available",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
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
                      onPressed: () async {
  await _fetchLatestSolution(int.parse(widget.report['reportId'].toString()));
  _openActionModal(context);
},
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