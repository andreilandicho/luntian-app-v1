// lib/services/report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';

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
}