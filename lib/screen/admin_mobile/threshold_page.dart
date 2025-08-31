import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/admin/luntian_header.dart';
import 'package:flutter_application_1/widgets/admin/luntian_footer.dart';
import 'package:flutter_application_1/widgets/admin/threshold_item.dart';

class ThresholdPage extends StatefulWidget {
  const ThresholdPage({super.key});

  @override
  State<ThresholdPage> createState() => _ThresholdPageState();
}

class _ThresholdPageState extends State<ThresholdPage> {
  int selectedIndex = 0;
  bool isNavVisible = true;
  String _currentAddress = 'Your Address';

  List<Map<String, String>> thresholdReports = [
    {
      'imageUrl': 'assets/garbage.png',
      'reportId': '12345',
      'location': 'Community Park',
      'category': 'Garbage',
      'hazardous': 'No',
      'priority': 'High',
      'deadline': '7 days left',
    },
    {
      'imageUrl': 'assets/garbage.png',
      'reportId': '67890',
      'location': 'Main Street',
      'category': 'Water Leak',
      'hazardous': 'Yes',
      'priority': 'Medium',
      'deadline': '3 days left',
    },
    {
      'imageUrl': 'assets/garbage.png',
      'reportId': '54321',
      'location': 'River Bank',
      'category': 'Flood Risk',
      'hazardous': 'Yes',
      'priority': 'High',
      'deadline': '1 day left',
    },
  ];

  int _parseDeadline(String deadline) {
    // Extract number from "X days left"
    return int.tryParse(deadline.split(' ').first) ?? 999;
  }

  @override
  void initState() {
    super.initState();
    // Automatically sort by nearest deadline
    thresholdReports.sort(
      (a, b) =>
          _parseDeadline(a['deadline']!).compareTo(_parseDeadline(b['deadline']!)),
    );
  }

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
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              Text(
                'THRESHOLD REPORTS',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MaryKate',
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              /// Render sorted list
              ...thresholdReports.map((report) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ThresholdItem(
                    imageUrl: report['imageUrl']!,
                    reportId: report['reportId']!,
                    location: report['location']!,
                    category: report['category']!,
                    hazardous: report['hazardous']!,
                    priority: report['priority']!,
                    deadline: report['deadline']!,
                  ),
                );
              }).toList(),
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
