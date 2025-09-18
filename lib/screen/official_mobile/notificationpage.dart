import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'package:flutter_application_1/widgets/official/offnotification.dart'; // <- reusable widget
import 'PendingReportDetailPage.dart'; 
import 'view_report.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int selectedIndex = 2;
  bool isNavVisible = true;
  String _currentAddress = "Your Address";

  final List<Map<String, dynamic>> notifications = [
    {
      'type': 'assigned',
      'message': 'New report assigned',
      'timestamp': DateTime.now(),
      'isRead': false,
      'report': {
        'reporterName': 'Juan Dela Cruz',
        'profileImage': 'assets/profile picture.png',
        'reportTime': '7:30 PM',
        'reportDate': 'Aug 15, 2025',
        'priority': 'Medium',
        'isHazardous': false,
        'badge': 'Top Reporter',
        'postImage': 'assets/garbage.png',
        'description': 'There’s a water leak near the community park.',
        'location': 'Community Park',
      }
    },
    {
      'type': 'rejected',
      'message': 'Your uploaded solution was rejected',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
      'report': {
        'reporterName': 'Maria Santos',
        'profileImage': 'assets/profile picture.png',
        'reportTime': '2:00 PM',
        'reportDate': 'Aug 14, 2025',
        'postImage': 'assets/garbage.png',
        'description': 'Garbage pile-up near the market.',
        'statusDescription': 'Photo is unclear, please upload again.',
      }
    },
    {
      'type': 'accepted',
      'message': 'Your uploaded solution was approved',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': false,
      'report': {
        'reporterName': 'Pedro Cruz',
        'profileImage': 'assets/profile picture.png',
        'reportTime': '9:00 AM',
        'reportDate': 'Aug 13, 2025',
        'postImage': 'assets/garbage.png',
        'description': 'Streetlights not working in Zone 5.',
      }
    },
  ];

  bool get _hasUnread => notifications.any((n) => n['isRead'] == false);

  void _deleteNotification(int index) {
    final deletedNotif = notifications[index];

    setState(() {
      notifications.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Notification deleted"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            setState(() {
              notifications.insert(index, deletedNotif);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      appBar: LuntianHeader(
        currentAddress: _currentAddress,
        isSmallScreen: isSmallScreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title + Mark All as Read
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MaryKate',
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  if (_hasUnread)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var notif in notifications) {
                            notif['isRead'] = true;
                          }
                        });
                      },
                      child: const Text(
                        "Mark all as read",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),

              /// Notification list with swipe-to-delete
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];

                  return Dismissible(
                    key: Key(notif['message'] + notif['timestamp'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _deleteNotification(index);
                    },
                    child: NotificationCard(
                      type: notif['type'],
                      message: notif['message'],
                      timestamp: notif['timestamp'],
                      isRead: notif['isRead'],
                      onTap: () {
                        setState(() {
                          notifications[index]['isRead'] = true;
                        });
                      },
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: LuntianFooter(
        selectedIndex: selectedIndex,
        isNavVisible: isNavVisible,
        isSmallScreen: isSmallScreen,
        onItemTapped: (int index) {
          setState(() {
            selectedIndex = index;
          });

          if (index == 0) {
            Future.microtask(() {
              // Navigate to Dashboard
            });
          } else if (index == 1) {
            Future.microtask(() {
              // Navigate to Leaderboard
            });
          } else if (index == 2) {
            Future.microtask(() {
              // Notifications page
            });
          }
        },
      ),
    );
  }
}
