import 'dart:convert';
import 'package:http/http.dart' as http;

class DeleteService {
  final String baseUrl = 'https://luntian-app-v1-production.up.railway.app';

  /// Delete a report
  Future<bool> deleteReport(int reportId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('You can only delete your own reports');
      } else if (response.statusCode == 404) {
        throw Exception('Report not found');
      } else {
        throw Exception('Failed to delete report: ${response.body}');
      }
    } catch (e) {
      print('Error deleting report: $e');
      throw Exception('Error deleting report: $e');
    }
  }

  Future<bool> deleteEvent(int eventId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('You can only delete your own events');
      } else if (response.statusCode == 404) {
        throw Exception('Event not found');
      } else {
        throw Exception('Failed to delete event: ${response.body}');
      }
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Error deleting event: $e');
    }
  }
}