import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;

import 'screen/user/loading_screen.dart';
import 'screen/user/signup_screen.dart';
import 'screen/user/login_screen.dart'; // 👈 added this import
import 'screen/admin/login_screen.dart';
import 'package:flutter_application_1/screen/official_mobile/official.dart';
import 'package:flutter_application_1/screen/user/home_screen.dart';

import 'screen/admin/admin_dashboard_stub.dart'
    if (dart.library.html) 'screen/admin/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ewogpmjmlefwzddoldwb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV3b2dwbWptbGVmd3pkZG9sZHdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzNTk5OTgsImV4cCI6MjA2OTkzNTk5OH0.WdaKfVVirpGhDYB-NKSGTpsIkMNZsKF21fcybIaKe3E',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SupabaseClient supabase;
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkSession(); // Check if user already logged in
      _initAppLinks(); // Listen for magic links
    });

    // Listen for auth changes (e.g., sign out)
    supabase.auth.onAuthStateChange.listen((data) async {
      await _handleAuth(data.session);
    });
  }

  // Initialize App Links listener
  void _initAppLinks() async {
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleMagicLinkUri(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }

    _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) _handleMagicLinkUri(uri);
    });
  }

  // Handle magic link URI
  Future<void> _handleMagicLinkUri(Uri uri) async {
    final code = uri.queryParameters['code'];
    if (code == null) return;

    debugPrint("Magic link code: $code");

    try {
      final response = await supabase.auth.getSessionFromUrl(uri);
      if (response.session != null) {
        // Pass flag: this session came from magic link
        await _handleAuth(response.session, fromMagicLink: true);
      } else {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignUpPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Magic link error: $e");
    }
  }

  // Check if current session exists
  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;

    if (session != null) {
      await _handleAuth(session);
    } else {
      debugPrint("❌ No session");

      Widget redirectPage;

      if (kIsWeb) {
        // Web (Chrome)
        redirectPage = const AdminLoginPage();
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile (Android/iOS)
        redirectPage = const LoginPage();
      } else {
        // Other platforms (desktop)
        redirectPage = const LoginPage();
      }

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => redirectPage),
        (route) => false,
      );
    }
  }


  // Handle auth and route based on user existence & role
  Future<void> _handleAuth(Session? session, {bool fromMagicLink = false}) async {
    if (session == null) {
      debugPrint("❌ No session (handled)");
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), // 👈 go to login
        (route) => false,
      );
      return;
    }

    final email = session.user.email;
    if (email == null) return;

    // Navigate to loading
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoadingPage()),
      (route) => false,
    );

    try {
      final stopwatch = Stopwatch()..start();
      debugPrint("⏳ Querying users table for $email ...");

      final response = await supabase
          .from('users')
          .select('role')
          .eq('email', email)
          .maybeSingle();

      debugPrint("✅ Users query finished in ${stopwatch.elapsedMilliseconds} ms");

      if (response == null) {
        debugPrint("⚠️ No user row found for $email");
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => fromMagicLink ? const SignUpPage() : const LoginPage(),
          ),
          (route) => false,
        );
        return;
      }

      final role = response['role'] as String;
      debugPrint("👤 User role = $role");

      if (kIsWeb) {
        if (role == 'secretary') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        } else {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WebNotSupported()),
            (route) => false,
          );
        }
      } else {
        if (role == 'citizen') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UserHomePage()),
            (route) => false,
          );
        } else if (role == 'official') {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OfficialDashboard()),
            (route) => false,
          );
        } else {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UnknownRole()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Auth handling error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Luntian',
          theme: ThemeData(
            fontFamily: 'Poppins',
            primarySwatch: Colors.green,
          ),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

class UnknownRole extends StatelessWidget {
  const UnknownRole({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
      body: const Center(
        child: Text(
          'Unknown role selected.',
          style: TextStyle(fontSize: 20, color: Colors.white),
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
      body: const Center(
        child: Text(
          'Web platform not supported for this role.',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
