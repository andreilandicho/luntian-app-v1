import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/admin/admin_dashboard.dart';

void main() {
  runApp(const LuntianAdminApp());
}

class LuntianAdminApp extends StatelessWidget {
  const LuntianAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luntian Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF328E6E),
        scaffoldBackgroundColor: const Color(0xFFF3F7F6),
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AdminDashboard(),
    );
  }
}
