import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'package:flutter_application_1/widgets/official/offviewreport.dart';

class ViewReport extends StatefulWidget {
  final Map<String, dynamic> report;
  final String status;

  const ViewReport({
    super.key,
    required this.report,
    required this.status,
  });

  @override
  State<ViewReport> createState() => _ViewReportState();
}


class _ViewReportState extends State<ViewReport> {
  int selectedIndex = 0;
  bool isNavVisible = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      appBar: LuntianHeader(
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
                'VIEW PROOF',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),

              const SizedBox(height: 15),

              ViewReportPage(
                reporterName: widget.report['reporterName'] ?? "Unknown",
                profileImage: widget.report['profileImage'] ?? "assets/profile picture.png",
                description: widget.report['description'] ?? "No description",
                postImage: widget.report['postImage'] ?? "assets/placeholder.png",
                status: widget.status, // ✅ Dynamic
                reportDate: widget.report['reportDate'] ?? "N/A",
                reportTime: widget.report['reportTime'] ?? "N/A",
                statusDescription: widget.report['statusDescription'] ?? "",
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
