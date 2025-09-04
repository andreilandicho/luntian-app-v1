import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/admin/luntian_header.dart';
import 'package:flutter_application_1/widgets/admin/luntian_footer.dart';
import 'package:flutter_application_1/widgets/admin/backlogs_post_card.dart'; // Import the widget file

class BacklogsReportsPage extends StatefulWidget {
  const BacklogsReportsPage({super.key});

  @override
  State<BacklogsReportsPage> createState() => _BacklogsReportsPageState();
}

class _BacklogsReportsPageState extends State<BacklogsReportsPage> {
  int selectedIndex = 0;
  bool isNavVisible = true;
  String _currentAddress = 'Your Address';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
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
                'IN PROGRESS REPORTS',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 15),

              /// Example of calling PendingPostCard
              BacklogsPostCard(
                reporterName: 'Juan Dela Cruz',
                profileImage: 'assets/profilepicture.png',
                reportTime: '7:30 PM',
                reportDate: 'Aug 15, 2025', // <-- Date here
                priority: 'High',
                badge: 'Top Reporter',
                postImage: 'assets/garbage.png',
                description: 'There’s a water leak near the community park. Needs urgent attention!',
                initialUpvotes: 12,
                initialDownvotes: 2,
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
        },
      ),
    );
  }
}
