import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/maintenance/pending_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingReportService {
  // Replace with your actual API base url
  //request url
  static const String baseUrl = "http://luntian-app-v1-production.up.railway.app";

  Future<List<PendingReport>> fetchAssignedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final officialDataString = prefs.getString('official_data');
    if (officialDataString == null) {
      throw Exception('No official data found in storage.');
    }
    final officialData = jsonDecode(officialDataString);
    final int officialId = officialData['user_id'];

    final response = await http.get(
      Uri.parse('$baseUrl/official-reports/assigned-reports/$officialId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PendingReport.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending reports');
    }
  }
}