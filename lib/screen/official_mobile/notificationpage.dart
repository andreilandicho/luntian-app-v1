import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'package:flutter_application_1/widgets/official/offnotification.dart'; // <- our reusable widget
import 'PendingReportDetailPage.dart'; // ✅ import detail page
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
    'message': 'A new report has been assigned to you.',
    'timestamp': DateTime.now(),
    'report': {
      'reporterName': 'Juan Dela Cruz',
      'profileImage': 'assets/profilepicture.png',
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
    'message': 'Your report was rejected by the admin.',
    'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
    'report': {
      'reporterName': 'Maria Santos',
      'profileImage': 'assets/profilepicture.png',
      'reportTime': '2:00 PM',
      'reportDate': 'Aug 14, 2025',
      'postImage': 'assets/garbage.png',
      'description': 'Garbage pile-up near the market.',
      'statusDescription': 'Photo is unclear, please upload again.',
    }
  },
  {
    'type': 'accepted',
    'message': 'Your report has been accepted and will be processed.',
    'timestamp': DateTime.now().subtract(const Duration(days: 1)),
    'report': {
      'reporterName': 'Pedro Cruz',
      'profileImage': 'assets/profilepicture.png',
      'reportTime': '9:00 AM',
      'reportDate': 'Aug 13, 2025',
      'postImage': 'assets/garbage.png',
      'description': 'Streetlights not working in Zone 5.',
    }
  },
];


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
              /// Title
              Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 15),

              /// Notification list
              ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return NotificationCard(
                  type: notif['type'],
                  message: notif['message'],
                  timestamp: notif['timestamp'],
                  onTap: () {
                    // normalize notif type
                    final type = (notif['type'] as String).toLowerCase().trim();

                    if (type == 'assigned' && notif['report'] != null) {
                      // ✅ Assigned → Pending details page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PendingReportDetailPage(
                            report: notif['report'],
                          ),
                        ),
                      );
                    } else if (type == 'rejected' && notif['report'] != null) {
                      // ✅ Rejected → ViewReport page with status Rejected
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewReport(
                            report: notif['report'],
                            status: "Rejected",
                          ),
                        ),
                      );
                    } else if (type == 'accepted' && notif['report'] != null) {
                      // ✅ Accepted → ViewReport page with status Accepted
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewReport(
                            report: notif['report'],
                            status: "Accepted",
                          ),
                        ),
                      );
                    } else {
                      // ✅ Fallback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Clicked: ${notif['message']}")),
                      );
                    }
                  },
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

          // Navigate to other pages based on index
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
              // Navigate to Notifications
            });
          }
        },
      ),
    );
  }
}
