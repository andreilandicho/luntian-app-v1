import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter_application_1/screen/admin/report_pdf.dart';
import 'dart:typed_data';
import 'dart:io' show File, Directory; // only for mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // ✅ only works for web


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
  int _currentImageIndex = 0;
  late PageController _pageController;
  final GlobalKey _cardKey = GlobalKey();

  bool? _actionAccepted;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: buildProofImage(bytes, url ?? path, BoxFit.contain), // ✅ bytes/url/asset
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
          final bool hasProof = true; // always true since we use asset image
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
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Timeline
                  _buildTimelineStep(
                    title: "Deployment personnel assigned",
                    subtitle:
                        "Assigned to: ${widget.report["personnelName"] ?? "N/A"}",
                    completed: stepAssignedCompleted,
                    isLast: false,
                  ),
                  _buildTimelineStep(
                    title: "Waiting for action",
                    subtitle: "Deadline: 7 days",
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
                          url: widget.report["proofImage"], // or pass bytes/path if needed
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
                            onPressed: () {
                              setState(() => _actionAccepted = true);
                              setModalState(() {});
                              _showDecisionBar(
                                accepted: true,
                                setModalState: setModalState,
                                messengerCtx: sheetCtx,
                              );
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
                            onPressed: () {
                              setState(() => _actionAccepted = false);
                              setModalState(() {});
                              _showDecisionBar(
                                accepted: false,
                                setModalState: setModalState,
                                messengerCtx: sheetCtx,
                              );
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
                          _actionAccepted == true
                              ? Icons.check_circle
                              : Icons.cancel,
                        ),
                        label: Text(
                          _actionAccepted == true
                              ? "Action Accepted"
                              : "Action Rejected",
                        ),
                        backgroundColor: _actionAccepted == true
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        side: BorderSide(
                          color: _actionAccepted == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Generate Report
                  if (_actionAccepted == true)
                    ElevatedButton.icon(
                     onPressed: () async {
                      try {
                        final pdfBytes = await ReportPdf.generate(context, widget.report);
                        if (pdfBytes == null) return;

                        if (kIsWeb) {
                          // ✅ Web: trigger browser download
                          final blob = html.Blob([pdfBytes]);
                          final url = html.Url.createObjectUrlFromBlob(blob);
                          final anchor = html.AnchorElement(href: url)
                            ..setAttribute("download", "report.pdf")
                            ..click();
                          html.Url.revokeObjectUrl(url);
                        } else {
                          // ✅ Mobile / Desktop: use printing package
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async => pdfBytes,
                          );
                        }

                        widget.onCompleted();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
                    return Image.asset(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
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
                        backgroundImage: AssetImage("assets/profilepicture.png"),
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