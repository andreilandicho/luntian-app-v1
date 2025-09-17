import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';

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
        // Remove the logout IconButton from here
      ),
      body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: SingleChildScrollView(
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
          //create an ontap logout logic here
        }),
        const SizedBox(height: 10),
        _buildDashboardCard(Icons.settings, "Settings", () {
          
        }),
        const SizedBox(height: 10),
        _buildDashboardCard(
          Icons.logout,
          "Logout",
          () async {
            await AuthService().logout();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
          color: Colors.red,
          iconColor: Colors.red,
        ),
      ],
    ),
  ),
),
    );
  }

  Widget _buildDashboardCard(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
    Color? iconColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, color: iconColor ?? const Color(0xFF328D6E), size: 30),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}