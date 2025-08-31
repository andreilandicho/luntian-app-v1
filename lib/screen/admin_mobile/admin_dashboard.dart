import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/admin/luntian_header.dart';
import 'package:flutter_application_1/widgets/admin/luntian_footer.dart';
import 'package:flutter_application_1/widgets/admin/pie_chart_section.dart';
import 'package:flutter_application_1/widgets/admin/weekly_trash_analytics.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                'DASHBOARD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: Colors.white,
                ),
              ),
            ),

            /// Date & Time
            StreamBuilder<DateTime>(
              stream: Stream.periodic(
                const Duration(seconds: 1),
                (_) => DateTime.now().toUtc().add(const Duration(hours: 8)),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final now = snapshot.data!;
                final formattedDate =
                    DateFormat('MMMM dd, yyyy – hh:mm:ss a').format(now);
                return Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            /// First Widget
            const PieChartSection(),
            const SizedBox(height: 10),

            /// Second Widget
            const WeeklyTrashAnalytics(),
          ],
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
