// lib/models/report_model.dart
import 'package:flutter/material.dart';

class ReportModel {
  final int reportId;
  final int userId;
  final String username;
  final String? userProfileUrl;
  final String description;
  final List<String> photoUrls;
  final String status;
  final DateTime createdAt;
  int upvotes;
  int downvotes;
  bool hasUserUpvoted;
  bool hasUserDownvoted;
  final bool anonymous;
  final int barangayId;
  final String? location;   // Optional field for location
  final DateTime? reportDeadline;
  final double? lat;
  final double? lon;
  final String? category;
  final String? priority; 
  final String? hazardous;


  
  ReportModel({
    required this.reportId,
    required this.userId,
    required this.username,
    this.userProfileUrl,
    required this.description,
    required this.photoUrls,
    required this.status,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.hasUserUpvoted,
    required this.hasUserDownvoted,
    required this.anonymous,
    required this.barangayId,
    this.location,
    this.reportDeadline,
    this.lat, 
    this.lon,
    this.category,
    this.priority,
    this.hazardous,
  });
  
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['report_id'],
      userId: json['user_id'] ?? -1,
      username: json['anonymous'] ? 'Anonymous Citizen' : (json['username'] ?? ''),
      userProfileUrl: json['anonymous'] ? null : (json['user_profile_url'] ?? 'assets/profile picture.png'),
      description: json['description'],
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      hasUserUpvoted: json['has_user_upvoted'] ?? false,
      hasUserDownvoted: json['has_user_downvoted'] ?? false,
      anonymous: json['anonymous'] ?? false,
      barangayId: json['barangay_id'],
      location: json['location']?.toString(), // <-- null safe
      reportDeadline: json['report_deadline'] != null ? DateTime.parse(json['report_deadline']) : null,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] != null ? (json['lon'] as num).toDouble() : null,
      category: json['category']?.toString(),
      priority: json['priority']?.toString(),
      hazardous: json['hazardous']?.toString(),
    );

  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': reportId,
      'username': anonymous ? 'Anonymous Citizen' : username,
      'userProfile': userProfileUrl,
      'images': photoUrls.isEmpty ? ['assets/garbage.png'] : photoUrls,
      'postContent': description,
      'priorityLabel': getPriorityFromStatus(status),
      'priorityColor': getPriorityColor(status),
      'timestamp': getTimeAgo(createdAt),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvoted': hasUserUpvoted,
      'downvoted': hasUserDownvoted,
      'status': status,
      'location': location ?? 'Unknown Location',
      'reportDeadline': reportDeadline?.toIso8601String(),
      'lat': lat,
      'lon': lon,
      'category': category,
      'priority': priority,
      'hazardous': hazardous,
    };
  }
  
  static String getPriorityFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'critical': return 'High';
      case 'in_progress': return 'Medium';
      case 'resolved': return 'Resolved';
      default: return 'Low';
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.yellow;
      case 'pending': return Colors.orange;
      default: return Colors.blue;
    }
  }
  
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }
  
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}