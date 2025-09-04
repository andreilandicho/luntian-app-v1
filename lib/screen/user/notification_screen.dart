import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

double responsiveSize(BuildContext context, double size) {
  final sizeFactor = MediaQuery.of(context).orientation == Orientation.portrait
      ? MediaQuery.of(context).size.width / 375
      : MediaQuery.of(context).size.height / 375;
  return size * sizeFactor;
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> notifications = [
    {
      'type': 'upvote',
      'username': 'Kristel Cruz',
      'message': 'Kristel Cruz upvoted your post.',
      'timestamp': DateTime.now(),
      'post': {
        'username': 'Kristel Cruz',
        'userProfile': 'assets/profilepicture.png',
        'postContent': 'There’s a lot of garbage near the street.',
        'images': ['assets/garbage.png', 'assets/garbage.png'],
        'priorityColor': Colors.red,
        'priorityLabel': 'High',
        'upvotes': 12,
        'downvotes': 3,
        'upvoted': false,
        'downvoted': false,
      },
      'read': false,
    },
    {
      'type': 'resolved',
      'username': 'Admin',
      'message': 'Admin marked your report as resolved.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'read': false,
      'post': {
        'description': 'Trash was collected by waste management team.',
        'image': 'https://qns.com/wp-content/uploads/2022/06/52138679498_edbe89e44b_4k-scaled.jpg?quality=51&resize=900,600',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    },
    {
      'type': 'event',
      'username': 'Kristel Cruz',
      'message': 'Kristel Cruz posted an event near your location.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'post': {
        'username': 'Kristel Cruz',
        'userProfile': 'assets/profilepicture.png',
        'postContent': 'Tree Planting this Sunday at 7AM',
        'images': ['assets/garbage.png'],
        'priorityColor': Colors.green,
        'priorityLabel': 'Event',
        'interested': false,
        'interestedCount': 27,
      },
      'read': false,
    },
  ];

  void markAsRead(int index) => setState(() => notifications[index]['read'] = true);

  void deleteNotification(int index) => setState(() => notifications.removeAt(index));

  void markAllAsRead() => setState(() {
        for (var notif in notifications) {
          notif['read'] = true;
        }
      });

  void showPostFullScreen(BuildContext context, Map<String, dynamic> post) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;

    bool isEvent = (post['priorityLabel']?.toString().toLowerCase() ?? '') == 'event';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(
              title: const Text("", style: TextStyle(fontFamily: 'Poppins')),
              leading: const BackButton(),
            ),
            body: OrientationBuilder(
              builder: (context, orientation) => Padding(
                padding: EdgeInsets.all(responsiveSize(context, 16)),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(post['userProfile']),
                          radius: responsiveSize(context, 24),
                        ),
                        title: Row(
                          children: [
                            Text(
                              post['username'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                fontSize: responsiveSize(context, 14),
                              ),
                            ),
                            SizedBox(width: responsiveSize(context, 6)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsiveSize(context, 8),
                                vertical: responsiveSize(context, 2),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text("Top Reporter", style: TextStyle(fontSize: responsiveSize(context, 10))),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsiveSize(context, 10),
                            vertical: responsiveSize(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: post['priorityColor'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post['priorityLabel'],
                            style: TextStyle(color: Colors.white, fontSize: responsiveSize(context, 12)),
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now()),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveSize(context, 12)),
                        ),
                      ),
                      SizedBox(height: responsiveSize(context, 10)),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: PageView(
                          children: post['images']
                              .map<Widget>((img) => GestureDetector(
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        backgroundColor: Colors.black,
                                        child: PhotoView(imageProvider: AssetImage(img)),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(img, fit: BoxFit.cover),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      SizedBox(height: responsiveSize(context, 10)),
                      Text(post['postContent'], style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveSize(context, 14))),
                      SizedBox(height: responsiveSize(context, 16)),
                      isEvent
                          ? ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  bool currentlyInterested = post['interested'] ?? false;
                                  post['interested'] = !currentlyInterested;
                                  post['interestedCount'] = (post['interestedCount'] ?? 0) + (currentlyInterested ? -1 : 1);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: post['interested'] ? Colors.green : Colors.grey[300],
                                foregroundColor: post['interested'] ? Colors.white : Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsiveSize(context, 16),
                                  vertical: responsiveSize(context, 10),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Icon(post['interested'] ? Icons.favorite : Icons.favorite_border),
                              label: Text("${post['interestedCount'] ?? 0} Interested", style: TextStyle(fontSize: responsiveSize(context, 14))),
                            )
                          : Row(
                              children: [
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          bool wasUpvoted = post['upvoted'] ?? false;
                                          bool wasDownvoted = post['downvoted'] ?? false;

                                          if (wasUpvoted) {
                                            post['upvoted'] = false;
                                            post['upvotes'] = (post['upvotes'] ?? 1) - 1;
                                          } else {
                                            post['upvoted'] = true;
                                            post['upvotes'] = (post['upvotes'] ?? 0) + 1;
                                            if (wasDownvoted) {
                                              post['downvoted'] = false;
                                              post['downvotes'] = (post['downvotes'] ?? 1) - 1;
                                            }
                                          }
                                        });
                                      },
                                      child: Icon(
                                        Icons.arrow_upward_rounded,
                                        size: responsiveSize(context, 32),
                                        color: post['upvoted'] ? Colors.green : Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: responsiveSize(context, 4)),
                                    Text("${post['upvotes'] ?? 0}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsiveSize(context, 14))),
                                  ],
                                ),
                                SizedBox(width: responsiveSize(context, 40)),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          bool wasDownvoted = post['downvoted'] ?? false;
                                          bool wasUpvoted = post['upvoted'] ?? false;

                                          if (wasDownvoted) {
                                            post['downvoted'] = false;
                                            post['downvotes'] = (post['downvotes'] ?? 1) - 1;
                                          } else {
                                            post['downvoted'] = true;
                                            post['downvotes'] = (post['downvotes'] ?? 0) + 1;
                                            if (wasUpvoted) {
                                              post['upvoted'] = false;
                                              post['upvotes'] = (post['upvotes'] ?? 1) - 1;
                                            }
                                          }
                                        });
                                      },
                                      child: Icon(
                                        Icons.arrow_downward_rounded,
                                        size: responsiveSize(context, 32),
                                        color: post['downvoted'] ? Colors.red : Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: responsiveSize(context, 4)),
                                    Text("${post['downvotes'] ?? 0}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsiveSize(context, 14))),
                                  ],
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(fontSize: responsiveSize(context, 24), fontFamily: 'Marykate')),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all') markAllAsRead();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'mark_all', child: Text('Mark all as read')),
            ],
          )
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(responsiveSize(context, 12)),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final post = notif['post'];

          return Dismissible(
            key: Key(notif['timestamp'].toString()),
            onDismissed: (_) => deleteNotification(index),
            background: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: EdgeInsets.only(left: responsiveSize(context, 20)), child: const Icon(Icons.delete, color: Colors.white)),
            secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: EdgeInsets.only(right: responsiveSize(context, 20)), child: const Icon(Icons.delete, color: Colors.white)),
            child: Card(
              margin: EdgeInsets.symmetric(vertical: responsiveSize(context, 8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: ListTile(
                onTap: () {
                  markAsRead(index);
                  if (notif['type'] == 'resolved') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReviewPage(post: notif['post'])),
                    );
                  } else if (post != null) {
                    showPostFullScreen(context, post);
                  }
                },
                leading: CircleAvatar(backgroundImage: AssetImage(post?['userProfile'] ?? 'assets/logoonlyluntian.png')),
                title: Text(
                  notif['message'],
                  style: TextStyle(
                    fontWeight: notif['read'] ? FontWeight.normal : FontWeight.bold,
                    fontFamily: 'Poppins',
                    fontSize: responsiveSize(context, 14),
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy • h:mm a').format(notif['timestamp']),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveSize(context, 12)),
                ),
                trailing: notif['read'] ? null : Icon(Icons.circle, size: responsiveSize(context, 10), color: Colors.blue),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReviewPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const ReviewPage({super.key, required this.post});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _rating = 0;
  String _responseTime = '';
  final TextEditingController _commentController = TextEditingController();

  List<String> responseOptions = ['Fast', 'Moderate', 'Slow'];

  void _submitReview() {
    if (_rating == 0 || _responseTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please rate and select response time")),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review submitted!")),
    );
  }

  double responsiveSize(BuildContext context, double size) {
    final width = MediaQuery.of(context).size.width;
    return size * (width < 360 ? 0.85 : width < 480 ? 0.95 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final String description = post['description'] ?? 'No description';
    final String imageUrl = post['image'] ?? '';
    final String dateTime = post['createdAt'] ?? '';
    final String formattedDate = dateTime.isNotEmpty
        ? DateFormat.yMMMd().add_jm().format(DateTime.parse(dateTime))
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Response"),
        backgroundColor: const Color(0xFF328E6E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsiveSize(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imageUrl),
              ),
            SizedBox(height: responsiveSize(context, 10)),
            Text(
              description,
              style: TextStyle(fontSize: responsiveSize(context, 16)),
            ),
            SizedBox(height: responsiveSize(context, 6)),
            if (formattedDate.isNotEmpty)
              Text(
                "Posted: $formattedDate",
                style: TextStyle(fontSize: responsiveSize(context, 12), color: Colors.grey),
              ),
            const Divider(height: 30),
            Text(
              "Rate the Response:",
              style: TextStyle(fontSize: responsiveSize(context, 16), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: responsiveSize(context, 10)),
            Center(
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: responsiveSize(context, 4)),
                itemSize: responsiveSize(context, 30),
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            SizedBox(height: responsiveSize(context, 30)),
            Text(
              "How fast was the response?",
              style: TextStyle(fontSize: responsiveSize(context, 16), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: responsiveSize(context, 10)),
            Wrap(
              spacing: responsiveSize(context, 10),
              children: responseOptions.map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: _responseTime == option,
                  selectedColor: const Color(0xFF328E6E),
                  onSelected: (_) {
                    setState(() {
                      _responseTime = option;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: responsiveSize(context, 30)),
            Text(
              "Additional Comments (optional):",
              style: TextStyle(fontSize: responsiveSize(context, 16), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: responsiveSize(context, 10)),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Type your comments here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(fontSize: responsiveSize(context, 14)),
            ),
            SizedBox(height: responsiveSize(context, 30)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF328E6E),
                  padding: EdgeInsets.symmetric(vertical: responsiveSize(context, 14)),
                ),
                child: Text(
                  "Submit Review",
                  style: TextStyle(fontSize: responsiveSize(context, 16), color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}