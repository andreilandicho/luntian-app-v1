// lib/services/report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import '../models/report_model.dart';
import '../models/solved_report_model.dart';

class ReportService {
  final String baseUrl = 'http://10.0.2.2:3000';
  
  Future<List<ReportModel>> getReportsByBarangay(int barangayId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/barangay/$barangayId?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ReportModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting reports: $e');
    }
  }

  Future<List<SolvedReportModel>> getSolvedReportsByBarangay(int barangayId, int currentUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/solved/$barangayId?userId=$currentUserId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SolvedReportModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load solved reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting solved reports: $e');
    }
  }
  
  Future<void> voteReport(int reportId, int userId, String voteType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports/$reportId/vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'voteType': voteType, // 'upvote', 'downvote', or 'remove'
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update vote: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error voting report: $e');
    }
  }
  
  Future<void> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reportData),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Failed to create report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating report: $e');
    }
  }

  //Profile page services
  Future<List<ReportModel>> getUserReports(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((report) => ReportModel.fromJson(report)).toList();
      } else {
        throw Exception('Failed to load user reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user reports: $e');
    }
  }

  // Method for getting user's event participation
  Future<List<Map<String, dynamic>>> getUserEvents(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load user events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user events: $e');
    }
  }

  // Method to get report statistics for a user
  Future<Map<String, dynamic>> getUserReportStats(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/stats/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user report stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user report stats: $e');
    }
  }
  
  Future<List<ReportModel>> getReportsByUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/reports/user/$userId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ReportModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch reports by user');
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }
}
