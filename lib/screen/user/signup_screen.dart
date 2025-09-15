import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _hasPassword = false;
  bool _hasConfirm = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Please enter email";
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value)) return "Enter a valid email address";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Please enter password";
    if (value.length < 8) return "Minimum 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(value)) return "Must include uppercase letter";
    if (!RegExp(r'[a-z]').hasMatch(value)) return "Must include lowercase letter";
    if (!RegExp(r'[0-9]').hasMatch(value)) return "Must include number";
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != passController.text) return "Passwords do not match";
    return null;
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
                width: 340,
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
                          fontSize: 35,
                          fontFamily: 'Marykate',
                          letterSpacing: 1.5,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              icon: Icons.person,
                              hintText: "First name...",
                              controller: firstNameController,
                              validator: (value) =>
                                  value == null || value.isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              icon: Icons.person,
                              hintText: "Last name...",
                              controller: lastNameController,
                              validator: (value) =>
                                  value == null || value.isEmpty ? "Required" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: Icons.email,
                        hintText: "Email address...",
                        controller: emailController,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: Icons.lock,
                        hintText: "Password...",
                        controller: passController,
                        obscureText: !_isPasswordVisible,
                        validator: _validatePassword,
                        onChanged: (value) {
                          setState(() {
                            _hasPassword = value.isNotEmpty;
                          });
                        },
                        suffixIcon: _hasPassword
                            ? IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              )
                            : null,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: Icons.lock_outline,
                        hintText: "Confirm Password...",
                        controller: confirmPassController,
                        obscureText: !_isConfirmVisible,
                        validator: _validateConfirm,
                        onChanged: (value) {
                          setState(() {
                            _hasConfirm = value.isNotEmpty;
                          });
                        },
                        suffixIcon: _hasConfirm
                            ? IconButton(
                                icon: Icon(
                                  _isConfirmVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmVisible = !_isConfirmVisible;
                                  });
                                },
                              )
                            : null,
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sign-up successful!"),
                              ),
                            );

                            // Wait 1 second before navigating back
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.pop(context); // Goes back to login screen
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
                          "SIGN UP",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already a member? ",
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
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

Widget _buildTextField({
  required IconData icon,
  required String hintText,
  required TextEditingController controller,
  required String? Function(String?) validator,
  bool obscureText = false,
  Widget? suffixIcon,
  void Function(String)? onChanged,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    onChanged: onChanged,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF328D6E)),
      suffixIcon: suffixIcon,
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