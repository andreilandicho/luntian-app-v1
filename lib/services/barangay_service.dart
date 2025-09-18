import 'dart:convert';
import 'package:http/http.dart' as http;

class BarangayService {
  final String baseUrl = 'http://10.0.2.2:3000';
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