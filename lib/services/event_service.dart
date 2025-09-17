// lib/services/report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/homepage_event_model.dart';

class EventService {
  final String baseUrl = 'http://10.0.2.2:3000';

  //for event screen
  Future<int?> getCitizenIdOfUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/users/$userId/citizen-id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['citizen_id'] as int?;
      } else {
        print('Failed to fetch citizen ID. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching citizen ID: $e');
      return null;
    }
  }
  
  Future<List<HomepageEventModel>> getPublicEvents(int? citizenId) async {
    try {
      final url = citizenId != null 
          ? '$baseUrl/events/public?citizenId=$citizenId'
          : '$baseUrl/events/public';
      
      final response = await http.get(
        Uri.parse(url),
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
  Future<List<HomepageEventModel>> getBarangayEvents(int barangayId, {int? citizenId}) async {
    try {
      final url = citizenId != null 
          ? '$baseUrl/events/barangay/$barangayId?citizenId=$citizenId'
          : '$baseUrl/events/barangay/$barangayId';
      
      final response = await http.get(
        Uri.parse(url),
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
  //toggle interest
  // Toggle interest in an event
  Future<bool> toggleEventInterest(int eventId, int citizenId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/events/$eventId/interest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'citizen_id': citizenId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['is_interested'] ?? false;
      } else {
        throw Exception('Failed to toggle interest: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling event interest: $e');
    }
  }

  // Add interest to an event
  Future<void> addInterest(int eventId, int citizenId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/interest/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'citizen_id': citizenId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add interest: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding interest: $e');
    }
  }

  // Remove interest from an event
  Future<void> removeInterest(int eventId, int citizenId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId/interest/remove'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'citizen_id': citizenId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove interest: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing interest: $e');
    }
  }
  // Get number of interested citizens for an event
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
