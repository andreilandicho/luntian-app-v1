// lib/services/report_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/homepage_event_model.dart';

class EventService {
  //request url
  final String baseUrl = 'https://luntian-app-v1-production.up.railway.app';

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


  // for emailers that I have created
  Future<void> notifyBarangayAboutEvent(int eventId) async {
  try {
    final url = '$baseUrl/notif/eventNotif';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'event_id': eventId}),
    );
    
    if (response.statusCode != 200) {
      print('Warning: Failed to send event notification');
    }
  } catch (e) {
    print('Error sending event notification: $e');
    // Non-critical error, don't throw
  }
}
// Call this when an event is approved
Future<void> notifyAllCitizensAboutEvent(int eventId, int barangayId) async {
  try {
    final url = '$baseUrl/notif/notifyBarangayCitizens';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'event_id': eventId,
        'barangay_id': barangayId
      }),
    );
    
    if (response.statusCode == 200) {
      print('Successfully sent notifications to all citizens');
    } else {
      print('Error sending notifications: ${response.body}');
    }
  } catch (e) {
    print('Exception sending notifications: $e');
  }
}

//emailer for approval updates for event
Future<void> updateEventApprovalStatus(int eventId, String status, int barangayId) async {
  try {
    // Send the notification
    final url = '$baseUrl/notif/eventApproval';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'event_id': eventId,
        'approval_status': status
      }),
    );
    
    if (response.statusCode != 200) {
      debugPrint('Warning: Failed to send event approval notification: ${response.body}');
    } else {
      debugPrint('✅ Event approval notification sent successfully');
      
      // If approved, also notify all citizens in the barangay
      if (status == 'approved') {
        await notifyAllCitizensAboutEvent(eventId, barangayId);
      }
    }
  } catch (e) {
    debugPrint('Error sending event approval notification: $e');
  }
}
}
