import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/admin/feedback.dart';
import 'package:flutter_application_1/widgets/admin/generate_doc.dart';
import 'package:flutter_application_1/widgets/admin/luntian_header.dart';
import 'package:flutter_application_1/widgets/admin/luntian_footer.dart';
import 'package:flutter_application_1/widgets/admin/details.dart'; // Import the report details card

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
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
                'FEEDBACK',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// Example FeedbackPostCard with mock data
              FeedbackPostCard(
                reporterName: 'John Doe',
                profileImage: 'assets/profilepicture.png',
                reportTime: '10:45 AM',
                reportDate: 'Aug 15, 2025',
                postImage: 'assets/garbage.png',
                badge: 'Top Contributor',
                description:
                    'Great app! I love how easy it is to report issues in our community. Keep up the good work! The recent garbage collection delay was quickly resolved after my report, and I appreciate how fast the team acted to deploy additional trucks.',
              ),

              const SizedBox(height:0),

              /// Report details
              ReportDetailsCard(
                reportDate: "Aug 15, 2025",
                solvedDate: "Aug 16, 2025",
                personnelName: "Barangay Clean-up Crew",
                location: "Zone 3, Purok 5",
              ),

              const SizedBox(height: 5),

              /// Generate document button
              GenerateDocumentButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Document generated successfully!'),
                    ),
                  );
                },
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
