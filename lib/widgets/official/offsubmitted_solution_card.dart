// submitted_solution_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/maintenance/submitted_solutions.dart';
import 'package:flutter_application_1/screen/official_mobile/review_submission_page.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmittedSolutionCard extends StatefulWidget {
  final SubmittedSolution solution;

  const SubmittedSolutionCard({super.key, required this.solution});

  @override
  State<SubmittedSolutionCard> createState() => _SubmittedSolutionCardState();
}

class _SubmittedSolutionCardState extends State<SubmittedSolutionCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Color and icon for approval status
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _pill({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 12, 
              fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Descriptive Location: ${widget.solution.descriptiveLocation ?? 'No location provided'}"),
            Text("Category: ${widget.solution.reportCategory}"),
            Text("Hazardous: ${widget.solution.isHazardous ? "Yes" : "No"}"),
            Text("Priority: ${widget.solution.priority}"),
            Text("Assigned to: ${widget.solution.assignedOfficials.isNotEmpty ? 
              widget.solution.assignedOfficials.join(', ') : 'None'}"),
            Text("Report Date: ${widget.solution.reportDate}"),
            Text("Solution Date: ${widget.solution.solutionDate}"),
            Text("Report Status: ${widget.solution.reportStatus}"),
            Text("Approval Status: ${widget.solution.approvalStatus}"),
            Text(
              "Deadline: ${widget.solution.reportDeadline != null ? 
                DateFormat('yyyy-MM-dd').format(widget.solution.reportDeadline!) : 'No deadline'}",
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showReviewSubmission() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewSubmissionPage(solution: widget.solution),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(1),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.solution.profileImage),
                  radius: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.solution.reporterName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.solution.reportDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Approval status badge (replaces safe badge)
                _pill(
                  label: widget.solution.approvalStatus.toUpperCase(),
                  color: _statusColor(widget.solution.approvalStatus),
                  icon: _statusIcon(widget.solution.approvalStatus),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Solution Images Carousel
            if (widget.solution.solutionImages.isNotEmpty)
  Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.solution.solutionImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final img = widget.solution.solutionImages[index];
                  return Hero(
                    tag: img,
                    child: Image.network(
                      img,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
            // Tap to fullscreen - ADD THIS OVERLAY
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenSolutionImageView(
                          images: widget.solution.solutionImages,
                          initialIndex: _currentImageIndex,
                        ),
                      ),
                    );
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
      if (widget.solution.solutionImages.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.solution.solutionImages.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == entry.key
                      ? Colors.blue
                      : Colors.grey,
                ),
              );
            }).toList(),
          ),
        ),
    ],
  ),

            const SizedBox(height: 12),

            // Location Row (without underline)
            if (widget.solution.lat != null && widget.solution.lon != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      final url = 'https://www.google.com/maps/place/${widget.solution.lat},'
                          '${widget.solution.lon}/@${widget.solution.lat},'
                          '${widget.solution.lon},20z/data=!3m1!1e3';
                      launchUrl(Uri.parse(url));
                    },
                    child: Text(
                      'View on Map',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue, // Blue color, no underline
                      ),
                    ),
                  ),
                ],
              ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(widget.solution.description),
            ),

            // Report Details Button (Green)
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showReportDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Report Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Review Submission Button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showReviewSubmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 5, 102, 181),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Review Submission",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// Full-screen image view with carousel for Solution Images
class FullScreenSolutionImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenSolutionImageView({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenSolutionImageView> createState() => _FullScreenSolutionImageViewState();
}

class _FullScreenSolutionImageViewState extends State<FullScreenSolutionImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for images with swipe navigation
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final img = widget.images[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Hero(
                  tag: img,
                  child: Center(
                    child: Image.network(
                      img,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Image indicators (if multiple images)
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.images.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.white
                          : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}