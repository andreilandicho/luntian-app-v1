import 'package:flutter/material.dart';

class FeedbackPostCard extends StatefulWidget {
  final String reporterName;
  final String profileImage;
  final String reportTime;
  final String reportDate;
  final String? badge;
  final String postImage;
  final String description;

  const FeedbackPostCard({
    super.key,
    required this.reporterName,
    required this.profileImage,
    required this.reportTime,
    required this.reportDate,
    required this.badge,
    required this.postImage,
    required this.description,
  });

  @override
  State<FeedbackPostCard> createState() => _FeedbackPostCardState();
}

class _FeedbackPostCardState extends State<FeedbackPostCard> {
  
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row - Profile + Name + Time
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.profileImage),
                  radius: 20,
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
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.badge != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(widget.badge!,
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
            ],

            const SizedBox(height: 12),

            /// Clickable Post Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenImageView(imagePath: widget.postImage),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(widget.postImage, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 12),
            /// Description Text
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 14,
              ),
              textAlign: TextAlign.justify,
            )

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
