import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;


class ProfileService {
  //request url
  final String baseUrl = 'https://luntian-app-v1-production.up.railway.app'; // Same as your other services
  //get user information
  Future<Map<String, dynamic>> getUserInfo(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch user info: ${response.statusCode}');
    }
  }
  // Get user badges
  Future<List<Map<String, dynamic>>> getUserBadges(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/badges/$userId'),
        // Uri.parse('http://10.0.2.2:3000/badges/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        // If server doesn't have badges yet, return dummy badges
        return _getDummyBadges(userId);
      }
    } catch (e) {
      // Fallback to dummy badges on error
      return _getDummyBadges(userId);
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    required int userId,
    String? name,
    String? address,
    String? profilePicUrl,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (address != null) 'address': address,
          if (profilePicUrl != null) 'profile_pic_url': profilePicUrl,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
  
  // Upload profile picture
  // Update the uploadProfilePicture method in ProfileService
Future<String?> uploadProfilePicture(int userId, String filePath) async {
  try {
    // Create multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/$userId/upload-profile-picture')
    );
    
    // Add the image file
    final file = File(filePath);
    final multipartFile = await http.MultipartFile.fromPath(
      'image', 
      file.path,
      contentType: MediaType('image', _getFileExtension(filePath).replaceAll('.', ''))
    );
    request.files.add(multipartFile);
    
    // Send the request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imageUrl'];
    } else {
      print('Error uploading profile picture: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Exception uploading profile picture: $e');
    return null;
  }
}

// Helper method to get file extension
String _getFileExtension(String filePath) {
  return path.extension(filePath).toLowerCase();
}
  
  // Temporary method to generate dummy badges until you implement the backend
  List<Map<String, dynamic>> _getDummyBadges(int userId) {
    return [
      {
        'name': 'The Gina Lopez Badge',
        'earned': false,
        'description': 'Submit 10 reports for a better environment.',
        'progress': 0,
        'goal': 10
      },
      {
        'name': 'The Anna Oposa Badge',
        'earned': false,
        'description': 'Report 3 marine or water-related issues.',
        'progress': 0,
        'goal': 3
      },
      {
        'name': 'The Rodne Galicha Badge',
        'earned': false,
        'description': 'Successfully organize your first event.',
        'progress': 0,
        'goal': 1
      },
    ];
  }
}