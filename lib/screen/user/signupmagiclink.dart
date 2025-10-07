import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MagicLinkSignUpPage extends StatefulWidget {
  const MagicLinkSignUpPage({super.key});

  @override
  State<MagicLinkSignUpPage> createState() => _MagicLinkSignUpPageState();
}

class _MagicLinkSignUpPageState extends State<MagicLinkSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  Future<void> sendMagicLink() async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.signInWithOtp(
        email: emailController.text.trim(),
        emailRedirectTo: "io.supabase.flutter://login-callback",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification link sent to ${emailController.text}")),
      );

      // Close page after sending
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
                        "SIGN UP",
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'Marykate',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Enter email";
                          final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                          if (!emailRegex.hasMatch(value)) return "Invalid email";
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF328D6E)),
                          hintText: "Email address",
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
                            sendMagicLink();
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
                          "SIGN UP",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Back to Log In",
                          style: TextStyle(
                            fontSize: 14,
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