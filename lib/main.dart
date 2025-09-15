import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screen/user/loading_screen.dart';
import 'screen/official_mobile/official.dart';
import 'screen/admin/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Simulate logged-in role
  final String role = 'secretary'; // change this to 'official' or 'secretary' to test

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
    if (role == 'user') {
      // ✅ User role always works (mobile & web)
      return const LoadingPage();
    }

    if (role == 'official') {
      // ✅ Official only works on mobile
      if (!kIsWeb) {
        return const OfficialDashboard();
      } else {
        return const WebNotSupported();
      }
    }

    if (role == 'secretary') {
      // ✅ Secretary only works on web
      if (kIsWeb) {
        return const LoginPage();
      } else {
        return const UnknownRole();
      }
    }

    // ✅ Fallback for unknown roles
    return const UnknownRole();
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
