import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offpending_post_card.dart';
import 'package:flutter_application_1/models/maintenance/pending_report.dart';
import 'package:flutter_application_1/services/maintenance/pending_report_service.dart';

class PendingReportsPage extends StatefulWidget {
  const PendingReportsPage({super.key});

  @override
  State<PendingReportsPage> createState() => _PendingReportsPageState();
}

class _PendingReportsPageState extends State<PendingReportsPage> {
  late Future<List<PendingReport>> _futureReports;

  @override
  void initState() {
    super.initState();
    _futureReports = PendingReportService().fetchAssignedReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      body: FutureBuilder<List<PendingReport>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No pending reports.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return PendingPostCard(
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
              );
            },
          );
        },
      ),
    );
  }
}