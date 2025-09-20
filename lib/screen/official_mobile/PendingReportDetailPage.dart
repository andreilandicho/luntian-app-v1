import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'package:flutter_application_1/widgets/official/offpending_post_card.dart';

class PendingReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;

  const PendingReportDetailPage({super.key, required this.report});

  @override
  State<PendingReportDetailPage> createState() => _PendingReportDetailPageState();
}

class _PendingReportDetailPageState extends State<PendingReportDetailPage> {
  int selectedIndex = 0;
  bool isNavVisible = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),

      /// ✅ Header
      appBar: LuntianHeader(
        isSmallScreen: isSmallScreen,
      ),

      /// ✅ Single Post (No list anymore)
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500, // prevent stretching horizontally
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: IntrinsicHeight(
            child: IntrinsicWidth(
              child: PendingPostCard(
                reporterName: widget.report['reporterName'],
                profileImage: widget.report['profileImage'],
                reportTime: widget.report['reportTime'],
                reportDate: widget.report['reportDate'],
                priority: widget.report['priority'],
                isHazardous: widget.report['isHazardous'],
                badge: widget.report['badge'],
                postImage: widget.report['postImage'],
                description: widget.report['description'],
                location: widget.report['location'],
              ),
            ),
          ),
        ),
      ),
    ),



      /// ✅ Footer
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
