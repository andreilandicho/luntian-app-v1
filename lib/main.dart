import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screen/user/loading_screen.dart';
import 'screen/official_mobile/official.dart';
import 'models/user_model.dart';
import 'screen/user/login_screen.dart';
import 'screen/user/home_screen.dart';
import 'screen/user/signup_screen.dart';
import 'screen/user/signupemailscreen.dart';

import 'screen/admin/login_screen.dart';

import 'screen/admin/admin_dashboard_stub.dart'
    if (dart.library.html) 'screen/admin/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  late final SupabaseClient supabase;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();

    supabase = Supabase.instance.client;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkSession();
    });

    supabase.auth.onAuthStateChange.listen((data) async {
      await _handleAuth(data.session);
    });
  }

  Future<void> _checkSession() async {
    if (kIsWeb) {
      // Web: use Supabase Auth
      final session = supabase.auth.currentSession;
      if (session != null) {
        await _handleAuth(session);
      } else {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
          (route) => false,
        );
      }
    } else {
      // Mobile: use SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        setState(() {
          currentUser = UserModel.fromJson(jsonDecode(userData));
          isLoading = false;
        });
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => getHomeScreen(currentUser!.role)),
          (route) => false,
        );
      } else {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _storeUserDataForMobile(Map<String, dynamic> user, String role) async {
    final prefs = await SharedPreferences.getInstance();
    if (role == 'official') {
      await prefs.setString('official_data', jsonEncode(user));
    } else {
      await prefs.setString('user_data', jsonEncode(user));
    }
  }

  Future<void> _handleAuth(Session? session, {bool fromMagicLink = false}) async {
    if (session == null) {
      debugPrint("❌ No session (handled)");
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    final email = session.user.email;
    if (email == null) return;

    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoadingPage()),
      (route) => false,
    );

    try {
      final stopwatch = Stopwatch()..start();
      debugPrint("⏳ Querying users table for $email ...");

      final userRow = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      debugPrint("✅ Users query finished in ${stopwatch.elapsedMilliseconds} ms");

      if (userRow == null) {
        debugPrint("⚠️ No user row found for $email");
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );
        return;
      }

      final role = userRow['role'] as String;
      debugPrint("👤 User role = $role");

      // HYBRID: Store user info in SharedPreferences for mobile roles
      if (!kIsWeb && (role == 'citizen' || role == 'official')) {
        await _storeUserDataForMobile(userRow, role);
        await _loadUserData(); // Refresh local user for home screen
      }

      if (kIsWeb) {
        if (role == 'secretary') {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        } else {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WebNotSupported()),
            (route) => false,
          );
        }
      } else {
        if (role == 'citizen') {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UserHomePage()),
            (route) => false,
          );
        } else if (role == 'official') {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OfficialDashboard()),
            (route) => false,
          );
        } else {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UnknownRole()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Auth handling error: $e");
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data') ?? prefs.getString('official_data');
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
          navigatorKey: _navigatorKey,
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