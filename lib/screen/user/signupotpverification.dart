import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'signup_screen.dart';
import 'reset_password_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final bool isResetPassword;
  const OTPVerificationScreen({Key? key, required this.email, this.isResetPassword = false}) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();
  bool isResending = false;
  int resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startResendTimer();
  }

  void startResendTimer() {
    setState(() {
      resendSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (resendSeconds > 0) {
          resendSeconds -= 1;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> verifyOtp() async {
  final response = await http.post(
    Uri.parse('http://10.0.2.2:3000/api/verify-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': widget.email, 'otp': otpController.text.trim()}),
  );
  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['verified'] == true) {
    if (widget.isResetPassword) {
      // Navigate to ResetPasswordScreen for password reset flow
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else {
      // Go to signup page with locked email for signup flow
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpPage(lockedEmail: widget.email),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['error'] ?? 'Invalid OTP')),
    );
  }
}

  Future<void> resendOtp() async {
    setState(() => isResending = true);
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.email}),
    );
    setState(() => isResending = false);
    startResendTimer();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent. Check your email.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resend OTP.')),
      );
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
      body: Center(
        child: SingleChildScrollView(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 50),
                padding: const EdgeInsets.all(20),
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      const Text(
                        "EMAIL VERIFICATION",
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'Marykate',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "We sent a code to ${widget.email}",
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Enter OTP";
                          if (value.length != 6) return "OTP should be 6 digits";
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF328D6E)),
                          hintText: "Enter OTP",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            verifyOtp();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF328D6E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          "VERIFY",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: resendSeconds == 0 && !isResending ? resendOtp : null,
                        child: Text(
                          resendSeconds == 0 && !isResending
                              ? "Resend OTP"
                              : "Resend in $resendSeconds sec",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 50,
                child: Image(
                  image: AssetImage('assets/logo only luntian.png'),
                  height: 70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}