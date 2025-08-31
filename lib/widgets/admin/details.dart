import 'package:flutter/material.dart';

class ReportDetailsCard extends StatelessWidget {
  final String reportDate;
  final String solvedDate;
  final String personnelName;
  final String location;

  const ReportDetailsCard({
    super.key,
    required this.reportDate,
    required this.solvedDate,
    required this.personnelName,
    required this.location,
  });

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical:2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Report Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 2),
            _buildInfoRow("Date Reported", reportDate),
            _buildInfoRow("Date Solved", solvedDate),
            _buildInfoRow("Cleaned By", personnelName),
            _buildInfoRow("Location", location),
          ],
        ),
      ),
    );
  }
}
