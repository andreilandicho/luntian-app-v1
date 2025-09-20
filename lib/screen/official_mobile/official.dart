import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';
import 'pending_reports_page.dart';
import 'completed_reports_page.dart';

class OfficialDashboard extends StatefulWidget {
  const OfficialDashboard({super.key});

  @override
  State<OfficialDashboard> createState() => _OfficialDashboardState();
}

class _OfficialDashboardState extends State<OfficialDashboard> {
  int selectedIndex = 0; // bottom nav
  int tabIndex = 0; // 0 = Pending, 1 = Completed
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
      body: Column(
        children: [
          // Tabs Row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      tabIndex = 0; // show pending
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: const Border(
                        right: BorderSide(color: Colors.grey, width: 1),
                        bottom: BorderSide(color: Colors.green, width: 2),
                      ),
                      color: tabIndex == 0
                          ? Colors.white
                          : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        "Pending Reports (5)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tabIndex == 0 ? Colors.green : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      tabIndex = 1; // show completed
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: const Border(
                        left: BorderSide(color: Colors.grey, width: 1),
                        bottom: BorderSide(color: Colors.green, width: 2),
                      ),
                      color: tabIndex == 1
                          ? Colors.white
                          : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        "Completed Reports (3)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tabIndex == 1 ? Colors.green : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Area
          Expanded(
            child: tabIndex == 0
                ? const PendingReportsPage()
                : const CompletedReportsPage(),
          ),
        ],
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
