// rating_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static const String baseUrl = "http://10.0.2.2:3000"; 

  // Submit a rating
  static Future<Map<String, dynamic>> submitRating({
    required int reportId,
    required int satisfactionStars,
    required int responseTimeStars,
    required String comments,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        throw Exception('User not logged in');
      }

      final userData = jsonDecode(userDataString);
      final int userId = userData['id'];

      final response = await http.post(
        Uri.parse('$baseUrl/rating/submit-rating'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'report_id': reportId,
          'satisfaction_stars': satisfactionStars,
          'response_time_stars': responseTimeStars,
          'comments': comments,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      throw Exception('Rating submission failed: $e');
    }
  }

  // Delete a rating
  static Future<void> deleteRating(int ratingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        throw Exception('User not logged in');
      }

      final userData = jsonDecode(userDataString);
      final int userId = userData['id'];

      final response = await http.delete(
        Uri.parse('$baseUrl/rating/delete-rating/$ratingId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete rating');
      }
    } catch (e) {
      throw Exception('Rating deletion failed: $e');
    }
  }
}