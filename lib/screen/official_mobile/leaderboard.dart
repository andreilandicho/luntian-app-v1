import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'package:flutter_application_1/widgets/official/offleaderboard.dart'; // Import your new widget

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  int selectedIndex = 1;
  bool isNavVisible = true;
  String _currentAddress = 'Your Address';

  // Example data for leaderboard
  final List<Map<String, dynamic>> barangayRatings = [
    {'barangay': 'Brgy 360', 'ratings': [5, 5, 4, 4, 5], 'activityScore': 8},
    {'barangay': 'Brgy 310', 'ratings': [3, 3, 4, 5], 'activityScore': 12},
    {'barangay': 'Brgy 143', 'ratings': [5, 5, 4, 4, 3], 'activityScore': 5},
    {'barangay': 'Brgy 123', 'ratings': [4, 3, 5], 'activityScore': 6},
    {'barangay': 'Brgy 456', 'ratings': [2, 3, 3, 3], 'activityScore': 7},
    {'barangay': 'Brgy 789', 'ratings': [5, 4, 5], 'activityScore': 4},
    {'barangay': 'Brgy 001', 'ratings': [4, 4, 4], 'activityScore': 9},
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
              // Leaderboard title
              Text(
                'LEADERBOARD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // The leaderboard widget
              LeaderboardWidget(
                data: barangayRatings,
                width: screenWidth,
              ),
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
