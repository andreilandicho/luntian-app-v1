import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/user/login_screen.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo only luntian.png', width: 200, height: 200),
            const SizedBox(height: 20),
            const Text(
              'Luntian',
              style: TextStyle(
                fontFamily: 'Marykate',
                fontSize: 60,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

