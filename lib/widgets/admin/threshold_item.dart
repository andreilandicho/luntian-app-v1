import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/admin_mobile/view_report.dart';

class ThresholdItem extends StatelessWidget {
  final String imageUrl;
  final String reportId;
  final String location;
  final String category;
  final String hazardous;
  final String priority;
  final String deadline;

  const ThresholdItem({
    super.key,
    required this.imageUrl,
    required this.reportId,
    required this.location,
    required this.category,
    required this.hazardous,
    required this.priority,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to post detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewReportPage(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Left: Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageUrl,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 10),

            /// Right: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Report ID: $reportId",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Location: $location",
                      style: const TextStyle(fontSize: 13)),
                  Text("Category: $category",
                      style: const TextStyle(fontSize: 13)),
                  Text("Hazardous: $hazardous",
                      style: const TextStyle(fontSize: 13)),
                  Text("Priority: $priority",
                      style: const TextStyle(fontSize: 13)),

                  /// Action Deadline with alert style
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: Text(
                      "Action Deadline: $deadline",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
