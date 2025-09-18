import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: isWideScreen
          ? Row(
              children: [
                // LEFT PANEL
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0xFF90C67C),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/logo only luntian.png', height: 200),
                          const SizedBox(height: 20),
                          const Text(
                            "LUNTIAN",
                            style: TextStyle(
                              fontSize: 50,
                              fontFamily: 'Marykate',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // RIGHT PANEL
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 50),
                              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    const Text(
                                      "FORGOT PASSWORD",
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontFamily: 'Marykate',
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    const Text(
                                      "Enter your email address to receive password reset instructions.",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      icon: Icons.email,
                                      hintText: "Email address...",
                                      controller: emailController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please enter your email";
                                        }
                                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                        if (!emailRegex.hasMatch(value)) {
                                          return "Enter a valid email address";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 25),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Password reset link sent!"),
                                            ),
                                          );
                                          Future.delayed(const Duration(seconds: 1), () {
                                            Navigator.pop(context);
                                          });
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
                                        "RESET PASSWORD",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "Back to Login",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontFamily: 'Poppins',
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
                  ),
                ),
              ],
            )
          : _buildMobileLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90C67C),
      body: Center(
        child: SingleChildScrollView(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 50),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "FORGOT PASSWORD",
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: 'Marykate',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Enter your email address to receive password reset instructions.",
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        icon: Icons.email,
                        hintText: "Email address...",
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email";
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password reset link sent!"),
                              ),
                            );
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.pop(context);
                            });
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
                          "RESET PASSWORD",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(
                            color: Colors.blue,
                            fontFamily: 'Poppins',
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

// Reusable text field widget
Widget _buildTextField({
  required IconData icon,
  required String hintText,
  required TextEditingController controller,
  required String? Function(String?) validator,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF328D6E)),
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[200],
    ),
    validator: validator,
  );
}
