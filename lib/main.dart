import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/screen/official_mobile/official.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screen/user/loading_screen.dart';

import 'screen/admin/admin_dashboard_stub.dart'
    if (dart.library.html) 'screen/admin/admin_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Simulate logged-in role
  final String role = 'secretary'; // Change to 'user' or 'official' to test different roles

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Luntian',
          theme: ThemeData(
            fontFamily: 'Poppins',
            primarySwatch: Colors.green,
          ),
          home: getHomeScreen(role),
        );
      },
    );
  }

  Widget getHomeScreen(String role) {
    if (kIsWeb) {
      if (role == 'secretary') {
        return const AdminDashboard();
      } else {
        return const WebNotSupported();
      }
    } else {
      if (role == 'user') return const LoadingPage();
      if (role == 'official') return const OfficialDashboard();
      return const UnknownRole();
    }
  }
}

class UnknownRole extends StatelessWidget {
  const UnknownRole({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.help_outline, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Unknown role selected.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class WebNotSupported extends StatelessWidget {
  const WebNotSupported({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Web platform is not supported for this role.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}