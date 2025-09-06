// lib/services/report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/homepage_event_model.dart';

class EventService {
  final String baseUrl = 'http://10.0.2.2:3000';
  
  Future<List<HomepageEventModel>> getPublicEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HomepageEventModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting events: $e');
    }
  }
  Future<List<HomepageEventModel>> getBarangayEvents(int barangayId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/barangay/$barangayId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HomepageEventModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting events: $e');
    }
  }
  Future<List<HomepageEventModel>> getInterestedCitizens(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/interested/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HomepageEventModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load number of interested citizens: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting number of interested citizens: $e');
    }
  }
}
