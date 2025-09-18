import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class OfficialProfileService {
  final String baseUrl = 'http://10.0.2.2:3000';

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
}