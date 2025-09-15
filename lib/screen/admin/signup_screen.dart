import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/admin/login_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _hasPassword = false;

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
                                      "SIGN UP",
                                      style: TextStyle(
                                        fontSize: 35,
                                        fontFamily: 'Marykate',
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // First & Last Name Row
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

                                    // Email
                                    _buildTextField(
                                      icon: Icons.email,
                                      hintText: "Email...",
                                      controller: emailController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return "Required";
                                        final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                                        if (!emailRegex.hasMatch(value)) return "Invalid email";
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 15),

                                    // Password
                                    _buildTextField(
                                      icon: Icons.lock,
                                      hintText: "Password...",
                                      controller: passwordController,
                                      obscureText: !_isPasswordVisible,
                                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
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

                                    // Sign Up Button
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const LoginPage()),
                                          );
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
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Back to Login
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Already have an account? ",
                                          style: TextStyle(fontFamily: 'Poppins'),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (_) => const LoginPage()),
                                            );
                                          },
                                          child: const Text(
                                            "Log In",
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
                        "SIGN UP",
                        style: TextStyle(
                          fontSize: 35,
                          fontFamily: 'Marykate',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        icon: Icons.person,
                        hintText: "First name...",
                        controller: firstNameController,
                        validator: (value) =>
                            value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: Icons.person,
                        hintText: "Last name...",
                        controller: lastNameController,
                        validator: (value) =>
                            value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: Icons.email,
                        hintText: "Email...",
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Required";
                          final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                          if (!emailRegex.hasMatch(value)) return "Invalid email";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: Icons.lock,
                        hintText: "Password...",
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
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
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(fontFamily: 'Poppins'),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              );
                            },
                            child: const Text(
                              "Log In",
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

// Reusable text field widget
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
