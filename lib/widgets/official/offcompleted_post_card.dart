import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/official_mobile/view_report.dart';

 // Import the view report page

class CompletedPostCard extends StatefulWidget {
  final String reporterName;
  final String profileImage;
  final String reportTime;
  final String reportDate;
  final String priority; // "High", "Medium", "Low"
  final String? badge;
  final String postImage;
  final String description;
  final String location; // Optional location field

  /// NEW: safety flag
  final bool isHazardous; // true = Hazardous, false = Safe

  const CompletedPostCard({
    super.key,
    required this.reporterName,
    required this.profileImage,
    required this.reportTime,
    required this.reportDate,
    required this.priority,
    this.badge,
    required this.postImage,
    required this.description,
    required this.location,
    this.isHazardous = false,
  });

  @override
  State<CompletedPostCard> createState() => _CompletedPostCardState();
}

class _CompletedPostCardState extends State<CompletedPostCard> {
  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
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
      margin: const EdgeInsets.only(bottom: 2), // spacing between stacked pills
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
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safetyLabel = widget.isHazardous ? 'Not Safe' : 'Safe';
    final safetyColor = widget.isHazardous ? Colors.red : Colors.green;
    final safetyIcon = widget.isHazardous ? Icons.warning_amber_rounded : Icons.verified_rounded;

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
            /// Top Row - Profile + Name/Time + Safety & Priority
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.profileImage),
                  radius: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.reporterName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "${widget.reportDate} • ${widget.reportTime}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (widget.badge != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.grey, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              widget.badge!,
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                /// Right side (Safety + Priority stacked vertically)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pill(label: safetyLabel, color: safetyColor, icon: safetyIcon),
                    _pill(label: widget.priority, color: _priorityColor(widget.priority)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Clickable Post Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageView(imagePath: widget.postImage),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Hero(
                  tag: widget.postImage,
                  child: Image.asset(widget.postImage, fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  widget.location,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            /// Description
            Text(widget.description),

            const SizedBox(height: 5),

            /// Action Row (for completed, you might want different button text?)
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewReport()
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 5, 102, 181),
                    padding: const EdgeInsets.symmetric(horizontal: 125, vertical: 6),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "View Proof",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen image view
class FullScreenImageView extends StatelessWidget {
  final String imagePath;

  const FullScreenImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imagePath,
            child: Image.asset(imagePath),
          ),
        ),
      ),
    );
  }
}
