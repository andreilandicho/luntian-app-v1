import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'package:flutter_application_1/widgets/official/offpending_post_card.dart';
import 'package:flutter_application_1/models/maintenance/pending_report.dart';

class PendingReportDetailPage extends StatelessWidget {
  final PendingReport report;

  const PendingReportDetailPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      appBar: LuntianHeader(isSmallScreen: isSmallScreen),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: IntrinsicHeight(
              child: IntrinsicWidth(
                child: PendingPostCard(
                  reportId: report.reportId,
                  reporterName: report.reporterName,
                  profileImage: report.profileImage,
                  reportDate: report.reportDate,
                  priority: report.priority,
                  postImages: report.postImages,
                  description: report.description,
                  descriptiveLocation: report.descriptiveLocation,
                  isHazardous: report.isHazardous,
                  reportCategory: report.reportCategory,
                  assignedOfficials: report.assignedOfficials,
                  status: report.status,
                  reportDeadline: report.reportDeadline,
                  lat: report.lat,
                  lon: report.lon,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: LuntianFooter(
        selectedIndex: 0,
        isNavVisible: true,
        isSmallScreen: isSmallScreen,
        onItemTapped: (int index) {},
      ),
    );
  }
}