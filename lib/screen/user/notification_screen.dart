import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/screen/user/widget notif/report_notification.dart';
import 'package:flutter_application_1/screen/user/widget notif/event_notification.dart';
import 'package:flutter_application_1/screen/user/widget notif/review.dart';
import 'package:flutter_application_1/screen/user/widget notif/post_report.dart';

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
      'read': false,
      'post': {
        'username': 'Kristel Cruz',
        'userProfile': 'assets/profile picture.png',
        'postContent': 'There’s a lot of garbage near the street.',
        'images': ['assets/garbage.png'],
        'priorityColor': Colors.red,
        'priorityLabel': 'High',
        'upvotes': 12,
        'downvotes': 3,
        'upvoted': false,
        'downvoted': false,
      },
    },
    {
      'type': 'resolved',
      'username': 'Admin',
      'message': 'Report updated: In progress → Resolved.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'read': false,
      'post': {
        'description': 'Trash was collected by waste management team.',
        'image': 'https://picsum.photos/400/200',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    },
    {
      'type': 'escalated',
      'username': 'Admin',
      'message': 'Report updated: In progress → Escalated.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'read': false,
    },
    {
      'type': 'event_posted',
      'username': 'Kristel Cruz',
      'message': 'There is a posted event in your barangay.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'read': false,
    },
    {
      'type': 'event_approved',
      'username': 'Admin',
      'message': 'Your initiated event got approved!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'read': false,
    },
    {
      'type': 'event_rejected',
      'username': 'Admin',
      'message': 'Your initiated event got rejected.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 7)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications',
            style: TextStyle(fontSize: responsiveSize(context, 24), fontFamily: 'Marykate')),
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

          return Dismissible(
            key: Key(notif['timestamp'].toString()),
            onDismissed: (_) => deleteNotification(index),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: responsiveSize(context, 20)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: responsiveSize(context, 20)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: notif['type'].toString().contains("event")
                ? EventNotificationWidget(
                    notification: notif,
                    markAsRead: () => markAsRead(index),
                    onTap: () {
                      // ✅ Just mark as read, no navigation
                      markAsRead(index);
                    },
                  )
                : ReportNotificationWidget(
                    notification: notif,
                    markAsRead: () => markAsRead(index),
                    onTap: () {
                      final post = notif['post'];
                      if (notif['type'] == 'resolved' && post != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewPage(post: post),
                          ),
                        );
                      } else if (post != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailPage(post: post),
                          ),
                        );
                      }
                    },
                  ),
          );
        },
      ),
    );
  }
}
