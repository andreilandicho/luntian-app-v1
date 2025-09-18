import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Secretary dashboard is not available on mobile.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
