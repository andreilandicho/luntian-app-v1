import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:math' as math;

class ReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final Color priorityColor;
  final String timeAgo;
  final VoidCallback onMarkInProgress;
  final double? fixedHeight;
  final Function(double) onHeightMeasured;

  const ReportCard({
    super.key,
    required this.report,
    required this.priorityColor,
    required this.timeAgo,
    required this.onMarkInProgress,
    this.fixedHeight,
    required this.onHeightMeasured,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  int _currentImageIndex = 0;
  late PageController _pageController;
  final GlobalKey _cardKey = GlobalKey();

  final dateFormat = DateFormat("dd MMM yyyy, hh:mm a");

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeight();
    });
  }

  void _measureHeight() {
    final context = _cardKey.currentContext;
    if (context != null) {
      final height = context.size?.height ?? 0;
      widget.onHeightMeasured(height);
    }
  }

  void _goToImage(int index) {
    if (index >= 0 && index < widget.report["images"].length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

void _showFeedbackDialog(Map<String, dynamic> report) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header with profile ---
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage("assets/profile picture.png"),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report["userName"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 17)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        report["location"],
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey[600]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(widget.timeAgo,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[500])),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- Rating ---
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < (report["rating"] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 22,
                                  );
                                }),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${report["rating"]}/5",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // --- Feedback message ---
                      _sectionHeader("Feedback", Icons.feedback_outlined),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          report["feedback"] ?? "No feedback provided.",
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // --- Before & After photos ---
                      _sectionHeader("Photos", Icons.photo_library_outlined),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _photoCard("Before", "assets/garbage.png"),
                            const SizedBox(width: 12),
                            _photoCard("After", "assets/clean.jpg"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- Report Details ---
                      _sectionHeader("Report Details", Icons.info_outline),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                "Date Reported",
                                report["createdAt"] is DateTime
                                    ? dateFormat.format(report["createdAt"])
                                    : (report["createdAt"] ?? "Unknown"),
                              ),
                              _buildDetailRow(
                                "Date Solved",
                                report["dateSolved"] is DateTime
                                    ? dateFormat.format(report["dateSolved"])
                                    : (report["dateSolved"] ?? "Pending"),
                              ),
                              _buildDetailRow("Cleaned by",
                                  report["cleanedBy"] ?? "Unassigned"),
                              _buildDetailRow(
                                  "Location", report["location"] ?? "N/A"),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // --- Generate Document button ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Document generation started...")));
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text("Generate Report PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // --- Close button (X) ---
                Positioned(
                  right: 10,
                  top: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.grey.shade200),
                      ),
                      icon: const Icon(Icons.close, size: 22, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Reusable Section Header with Icon
Widget _sectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: Colors.blue.shade600, size: 18),
      const SizedBox(width: 6),
      Text(
        title,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.blue.shade800),
      ),
    ],
  );
}

/// Reusable Photo Card
Widget _photoCard(String label, String imagePath) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => _showImageFullScreen(imagePath),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(imagePath,
              height: 120, width: 160, fit: BoxFit.cover),
        ),
      ),
    ],
  );
}

void _showImageFullScreen(String imagePath) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// helper widget for details rows
Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text("$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

    @override
  Widget build(BuildContext context) {
    final hazardous = widget.report["hazardous"] == true;
    final images = List<String>.from(widget.report["images"]);
    final hasRating = widget.report.containsKey("rating");

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
          // --- Image Carousel with priority banner + arrows ---
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
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: _currentImageIndex == index ? 8 : 6,
                      height: _currentImageIndex == index ? 8 : 6,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          // --- Content section ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User + location row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            AssetImage("assets/profile picture.png"),
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

                  // Description
                  Text(
                    widget.report["description"],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.25),
                  ),
                  const Spacer(),

                  // --- Rating & feedback button ---
                  if (hasRating) ...[
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < (widget.report["rating"] ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 18,
                              color: Colors.orange,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text("${widget.report["rating"]}/5",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _showFeedbackDialog(widget.report),
                          child: const Text("View"),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Icon(Icons.star_border,
                        size: 20, color: Colors.grey),
                  ]
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