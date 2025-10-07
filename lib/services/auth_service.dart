import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // Using 10.0.2.2 for Android emulator to access localhost
  final String baseUrl = 'http://10.0.2.2:3000';

  // Key for storing user data in shared preferences
  static const String userKey = 'user_data';
  
  // Login method
  Future<UserModel> login(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final userData = responseData['user'];
      
      // Print the exact data structure
      print('User data structure from API: ${userData.runtimeType}');
      print('User data from API: $userData');
      
      // Check if ID exists
      if (userData['id'] == null) {
        print('WARNING: No user ID found in API response!');
        // Try to find if ID might be under a different field name
        userData.keys.forEach((key) {
          print('Field in response: $key: ${userData[key]}');
        });
      }
      
      final user = UserModel.fromJson(userData);
      await _saveUserToPrefs(user);
      
      return user;
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Login failed';
      throw Exception(error);
    }
  } catch (e) {
    print('Login exception: $e');
    throw Exception('Login failed: ${e.toString()}');
  }
}
  
  // Get currently logged in user
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }
  
  /// Performs password change and verification in one call.
  /// Returns true if successful, or error string if failed.
  Future<dynamic> changePassword(int userId, String oldPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        return data['error'] ?? 'Unknown error';
      }
    } catch (e) {
      return e.toString();
    }
  }
  
  // Log out
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }
  
  // Save user data to shared preferences
  Future<void> _saveUserToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user.toJson()));
  }
}