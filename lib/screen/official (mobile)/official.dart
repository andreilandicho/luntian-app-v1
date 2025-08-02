import 'package:flutter/material.dart';

class OfficialDashboard extends StatelessWidget {
  const OfficialDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF328D6E),
        title: const Text(
          'Official Dashboard',
          style: TextStyle(
            fontFamily: 'MaryKate',
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDashboardCard(Icons.report, "Reports", () {
              // onTap logic here
            }),
            const SizedBox(height: 10),
            _buildDashboardCard(Icons.people, "Residents", () {
              // onTap logic here
            }),
            const SizedBox(height: 10),
            _buildDashboardCard(Icons.analytics, "Analytics", () {
              // onTap logic here
            }),
            const SizedBox(height: 10),
            _buildDashboardCard(Icons.settings, "Settings", () {
              // onTap logic here
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(IconData icon, String label, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, color: const Color(0xFF328D6E), size: 30),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
