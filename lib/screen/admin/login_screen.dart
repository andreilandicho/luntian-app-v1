import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/admin/signup_screen.dart';
import 'package:flutter_application_1/screen/admin/forgot_screen.dart';
import 'package:flutter_application_1/screen/admin/admin_dashboard.dart' as admin_dashboard;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart'; // Add bcrypt import
import 'package:flutter_application_1/screen/super_admin/super_admin_dashboard.dart' as super_admin_dashboard;

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _hasPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: isWideScreen
          ? Row(
              children: [
                // LEFT PANEL (Green with logo)
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

                // RIGHT PANEL (Background image + login card)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/background.png'), // Replace with your bg
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
                                      "LOG IN",
                                      style: TextStyle(
                                        fontSize: 35,
                                        fontFamily: 'Marykate',
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextField(
                                      icon: Icons.email,
                                      hintText: "Email...",
                                      controller: emailController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return "Please enter your email";
                                        final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                                        if (!emailRegex.hasMatch(value)) return "Enter a valid email address";
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 15),
                                    _buildTextField(
                                      icon: Icons.lock,
                                      hintText: "Password...",
                                      controller: passwordController,
                                      obscureText: !_isPasswordVisible,
                                      validator: (value) => value == null || value.isEmpty ? "Please enter your password" : null,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasPassword = value.isNotEmpty;
                                        });
                                      },
                                      suffixIcon: _hasPassword
                                          ? IconButton(
                                              icon: Icon(
                                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                                    const SizedBox(height: 25),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          try {
                                            final email = emailController.text.trim();
                                            final password = passwordController.text.trim();

                                            // 1️⃣ Fetch user by email
                                            final user = await Supabase.instance.client
                                                .from('users')
                                                .select('user_id, role, password, barangay_id')
                                                .eq('email', email)
                                                .maybeSingle();

                                            if (user == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("❌ No account found with this email"),
                                                  backgroundColor: Color.fromARGB(255, 0, 0, 0),
                                                ),
                                              );
                                              return;
                                            }

                                            final storedPassword = user['password'] as String? ?? "";
                                            
                                            // 2️⃣ Check password using bcrypt
                                            bool passwordMatches = false;
                                            
                                            // Check if password is hashed (starts with $2a$ or $2b$)
                                            if (storedPassword.startsWith(r"$2a$") || storedPassword.startsWith(r"$2b$")) {
                                              // Password is hashed - use bcrypt to verify
                                              try {
                                                passwordMatches = BCrypt.checkpw(password, storedPassword);
                                              } catch (e) {
                                                debugPrint("❌ BCrypt error: $e");
                                                passwordMatches = false;
                                              }
                                            } else {
                                              // Password is plain text (for backward compatibility)
                                              passwordMatches = storedPassword == password;
                                            }

                                            if (!passwordMatches) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("❌ Incorrect password"),
                                                  backgroundColor: Color.fromARGB(255, 0, 0, 0),
                                                ),
                                              );
                                              return;
                                            }

                                            // 3️⃣ Check role and navigate accordingly
                                            final role = user['role'];
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setInt('user_id', user['user_id']);

                                            if (role == 'barangay') {
                                              final barangayId = user['barangay_id'];
                                              await prefs.setInt('barangay_id', barangayId);

                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const admin_dashboard.AdminDashboard()),
                                              );
                                              return;
                                            } else if (role == 'admin') {

                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (_) => const super_admin_dashboard.SuperAdminDashboard()),
                                              );
                                              return;
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("❌ Access denied. Only admin or barangay accounts can log in."),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                          } catch (e) {
                                            debugPrint("❌ Login error: $e");
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Something went wrong during login"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
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
                                        "LOG IN",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                        );
                                      },
                                      child: const Text(
                                        "Forgot your password?",
                                        style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "© Luntian 2025. All rights reserved.",
                                          style: TextStyle(fontFamily: 'Poppins'),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const SignUpPage()),
                                            );
                                          },
                                          child: const Text(
                                            "",
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
                  ),
                ),
              ],
            )
          : _buildMobileLayout(context), // Keep old stacked layout for mobile
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
                        "LOG IN",
                        style: TextStyle(
                          fontSize: 35,
                          fontFamily: 'Marykate',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        icon: Icons.email,
                        hintText: "Email...",
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter your email";
                          final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                          if (!emailRegex.hasMatch(value)) return "Enter a valid email address";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: Icons.lock,
                        hintText: "Password...",
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: (value) => value == null || value.isEmpty ? "Please enter your password" : null,
                        onChanged: (value) {
                          setState(() {
                            _hasPassword = value.isNotEmpty;
                          });
                        },
                        suffixIcon: _hasPassword
                            ? IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();

                              // 1️⃣ Fetch user by email
                              final user = await Supabase.instance.client
                                  .from('users')
                                  .select('user_id, role, password, barangay_id')
                                  .eq('email', email)
                                  .maybeSingle();

                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("❌ No account found with this email"),
                                    backgroundColor: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                );
                                return;
                              }

                              final storedPassword = user['password'] as String? ?? "";
                              
                              // 2️⃣ Check password using bcrypt
                              bool passwordMatches = false;
                              
                              // Check if password is hashed (starts with $2a$ or $2b$)
                              if (storedPassword.startsWith(r"$2a$") || storedPassword.startsWith(r"$2b$")) {
                                // Password is hashed - use bcrypt to verify
                                try {
                                  passwordMatches = BCrypt.checkpw(password, storedPassword);
                                } catch (e) {
                                  debugPrint("❌ BCrypt error: $e");
                                  passwordMatches = false;
                                }
                              } else {
                                // Password is plain text (for backward compatibility)
                                passwordMatches = storedPassword == password;
                              }

                              if (!passwordMatches) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("❌ Incorrect password"),
                                    backgroundColor: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                );
                                return;
                              }

                              // 3️⃣ Check role
                              if (user['role'] != 'barangay') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("❌ Only barangay accounts are allowed to log in"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // ✅ Passed all checks → navigate to dashboard
                              final barangayId = user['barangay_id'];
                              final userId = user['user_id'];

                              // store globally or in SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setInt('barangay_id', barangayId);
                              await prefs.setInt('user_id', userId); //add para magfetch yung events

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const admin_dashboard.AdminDashboard()),
                              );

                            } catch (e) {
                              debugPrint("❌ Login error: $e");
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Something went wrong during login"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
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
                          "LOG IN",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text(
                          "Forgot your password?",
                          style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "© Luntian 2025. All rights reserved.",
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpPage()),
                              );
                            },
                            child: const Text(
                              "",
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