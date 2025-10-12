import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class OfficialProfileService {
  //request url
  final String baseUrl = 'https://luntian-app-v1-production.up.railway.app';

  Future<String?> uploadProfilePhoto(int userId, String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/official/$userId/upload-profile-photo'),
    );
    final file = File(filePath);
    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      file.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      return data['profile_photo_url'];
    }
    return null;
  }

  //change password
  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) return true;

    final data = jsonDecode(response.body);
    throw Exception(data['error'] ?? 'Failed to change password.');
  }

}