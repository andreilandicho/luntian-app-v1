import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/profile_service.dart';
import 'package:flutter_application_1/services/auth_service.dart'; // Assuming you have this


class ChangePasswordScreen extends StatefulWidget {
  final int userId;

  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String errorText = '';

  Future<void> _changePassword() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Password validation
    if (newPassword.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(newPassword) ||
        !RegExp(r'\d').hasMatch(newPassword)) {
      setState(() {
        errorText = 'Password must be at least 8 characters, include letters and numbers.';
        isLoading = false;
      });
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() {
        errorText = 'New passwords do not match.';
        isLoading = false;
      });
      return;
    }


    // Call backend to handle change and verification
    final success = await AuthService().changePassword(widget.userId, oldPassword, newPassword);

    setState(() {
      isLoading = false;
      if (success == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
      } else if (success is String && success.isNotEmpty) {
        errorText = success;
      } else {
        errorText = 'Failed to change password.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color(0xFF328E6E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Old Password'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password'),
                  ),
                  const SizedBox(height: 24),
                  if (errorText.isNotEmpty)
                    Text(errorText, style: const TextStyle(color: Colors.red)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                      ),
                      child: const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}