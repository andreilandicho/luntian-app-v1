import 'package:flutter/material.dart';
import '../../screen/admin_mobile/feedback.dart';

class CompletedPostCard extends StatefulWidget {
  final String reporterName;
  final String profileImage;
  final String reportTime;
  final String reportDate;
  final String priority;
  final String? badge;
  final String postImage;
  final String description;
  final int initialUpvotes;
  final int initialDownvotes;
  final double rating; // <-- Added for star rating

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
    required this.initialUpvotes,
    required this.initialDownvotes,
    required this.rating,
  });

  @override
  State<CompletedPostCard> createState() => _CompletedPostCardState();
}

class _CompletedPostCardState extends State<CompletedPostCard> {
  late int upvotes;
  late int downvotes;
  bool upvoted = false;
  bool downvoted = false;

  @override
  void initState() {
    super.initState();
    upvotes = widget.initialUpvotes;
    downvotes = widget.initialDownvotes;
  }

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
                      Text(
                        widget.reporterName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${widget.reportDate} • ${widget.reportTime}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.priority.toLowerCase() == 'high'
                        ? Colors.red
                        : widget.priority.toLowerCase() == 'medium'
                            ? Colors.orange
                            : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.priority,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                    builder: (_) => FullScreenImageView(imagePath: widget.postImage),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(widget.postImage, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 12),

            /// Description
            Text(widget.description),

            const SizedBox(height: 8),

            /// ⭐ Rating display with View button
              Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 40),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.rating.toStringAsFixed(1)}/5",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 150), // Adjust this for space between rating and button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "View",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
                        const SizedBox(height: 0),

                        /// Upvote / Downvote Row
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_upward,
                                  color: upvoted ? Colors.blue : Colors.grey),
                              onPressed: null,
                            ),
                            Text('$upvotes'),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(Icons.arrow_downward,
                                  color: downvoted ? Colors.red : Colors.grey),
                              onPressed: null,
                            ),
                            Text('$downvotes'),
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

