// lib/utils/image_helper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImageHelper {
  // Get appropriate ImageProvider based on path type
  static ImageProvider getImageProvider(String? imagePath) {
    // Handle null or empty paths
    if (imagePath == null || imagePath.isEmpty) {
      return const AssetImage('assets/profile picture.png');
    }
    
    try {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return NetworkImage(imagePath);
      } else if (imagePath.startsWith('assets/')) {
        return AssetImage(imagePath);
      } else {
        final file = File(imagePath);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          // Fallback to default if file doesn't exist
          return const AssetImage('assets/profile picture.png');
        }
      }
    } catch (e) {
      print('Error creating image provider: $e');
      // Return default image on error
      return const AssetImage('assets/profile picture.png');
    }
  }
  
  // Create a CircleAvatar with error handling
  static Widget buildProfileImage({
    required String? imagePath, 
    required double radius,
    Color backgroundColor = Colors.grey,
  }) {
    // Handle null or empty paths
    if (imagePath == null || imagePath.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
      );
    }
    
    // Handle different image sources
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Network image with error handling
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(imagePath),
        onBackgroundImageError: (exception, stackTrace) {
          // Don't return anything here, just print the error
          print('Error loading network image: $exception');
        },
        // Use a transparent child container for better error state handling
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
        ),
      );
    } else if (imagePath.startsWith('assets/')) {
      // Asset image
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: AssetImage(imagePath),
      );
    } else {
      try {
        // Local file with existence check
        final file = File(imagePath);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            backgroundImage: FileImage(file),
          );
        } else {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
          );
        }
      } catch (e) {
        print('Error loading profile image: $e');
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
        );
      }
    }
  }
  
  // Save a network image to local storage
  static Future<String?> saveNetworkImageLocally(String url, {String? customName}) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        String fileName;
        
        if (customName != null) {
          fileName = customName;
        } else {
          // Extract filename from URL or generate a unique name
          fileName = url.split('/').last;
          if (!fileName.contains('.')) {
            // Add extension if missing
            fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          }
        }
        
        final filePath = '${appDir.path}/$fileName';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        print('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving image locally: $e');
    }
    return null;
  }
}