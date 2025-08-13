import 'package:flutter/material.dart';

class Post {
  final String username;
  final String userProfile;
  final List<String> images;
  final String postContent;
  final String priorityLabel;
  final Color priorityColor;
  final String timestamp;
  int upvotes;
  int downvotes;
  bool upvoted;
  bool downvoted;

  Post({
    required this.username,
    required this.userProfile,
    required this.images,
    required this.postContent,
    required this.priorityLabel,
    required this.priorityColor,
    required this.timestamp,
    required this.upvotes,
    required this.downvotes,
    this.upvoted = false,
    this.downvoted = false,
  });

  // Optional: Convert from Map (useful for API responses)
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      username: map['username'] ?? '',
      userProfile: map['userProfile'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      postContent: map['postContent'] ?? '',
      priorityLabel: map['priorityLabel'] ?? '',
      priorityColor: map['priorityColor'] ?? Colors.green,
      timestamp: map['timestamp'] ?? '',
      upvotes: map['upvotes'] ?? 0,
      downvotes: map['downvotes'] ?? 0,
      upvoted: map['upvoted'] ?? false,
      downvoted: map['downvoted'] ?? false,
    );
  }

  // Optional: Convert to Map (useful for API requests)
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'userProfile': userProfile,
      'images': images,
      'postContent': postContent,
      'priorityLabel': priorityLabel,
      'priorityColor': priorityColor,
      'timestamp': timestamp,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvoted': upvoted,
      'downvoted': downvoted,
    };
  }
}