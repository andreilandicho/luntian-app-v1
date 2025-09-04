import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'screen/user/loading_screen.dart';
import 'screen/official (mobile)/official.dart';
import 'screen/admin/admin_dashboard.dart';
import 'models/user_model.dart';
import 'screen/user/login_screen.dart';
import 'screen/user/home_screen.dart';  // Add this import

// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ewogpmjmlefwzddoldwb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3b2dwbWptbGVmd3pkZG9sZHdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzNTk5OTgsImV4cCI6MjA2OTkzNTk5OH0.WdaKfVVirpGhDYB-NKSGTpsIkMNZsKF21fcybIaKe3E',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    
    if (userData != null) {
      setState(() {
        currentUser = UserModel.fromJson(jsonDecode(userData));
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

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
          home: isLoading 
            ? const LoadingPage() 
            : (currentUser == null 
                ? const LoginPage()
                : getHomeScreen(currentUser!.role)),
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
      if (role == 'citizen') return const UserHomePage();
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