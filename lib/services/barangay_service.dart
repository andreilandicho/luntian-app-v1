import 'dart:convert';
import 'package:http/http.dart' as http;

class BarangayService {
  //request url
  final String baseUrl = 'https://luntian-app-v1-production.up.railway.app';

  Future<Map<String, dynamic>?> getBarangayInfo(int barangayId) async {
  final response = await http.get(Uri.parse('$baseUrl/barangays/$barangayId'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is List && data.isNotEmpty) {
      return data[0]; // Return the first (and only) barangay object
    }
  }
  return null;
}
}