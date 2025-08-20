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
  });
  
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['report_id'],
      userId: json['user_id'],
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
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': reportId,
      'username': anonymous ? 'Anonymous Citizen' : username,
      'userProfile': userProfileUrl ?? 'assets/profile picture.png',
      'images': photoUrls.isEmpty ? ['assets/garbage.png'] : photoUrls,
      'postContent': description,
      'priorityLabel': getPriorityFromStatus(status),
      'priorityColor': getPriorityColor(status),
      'timestamp': getTimeAgo(createdAt),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvoted': hasUserUpvoted,
      'downvoted': hasUserDownvoted,
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
  
  static Color getPriorityColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
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
      return 'just now';
    }
  }
}