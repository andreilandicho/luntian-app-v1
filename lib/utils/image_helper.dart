import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImageHelper {
  static ImageProvider getImageProvider(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // For network images, including Supabase URLs
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      // For asset images
      return AssetImage(imagePath);
    } else {
      // For local file paths
      return FileImage(File(imagePath));
    }
  }
  
  static Widget buildProfileImage({
    required String imagePath,
    required double radius,
    Color backgroundColor = Colors.grey,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(imagePath),
        onBackgroundImageError: (_, __) {
          return errorWidget ?? const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          );
        },
      );
    } else if (imagePath.startsWith('assets/')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(imagePath),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(imagePath)),
      );
    }
  }
  
  static Future<String?> saveNetworkImageLocally(String url, {String? customName}) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = customName ?? '${DateTime.now().millisecondsSinceEpoch}${path.extension(url)}';
        final filePath = '${appDir.path}/$fileName';
        final file = File(filePath);
        
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      print('Error saving image locally: $e');
    }
    return null;
  }
  
  // Helper to determine if a URL is from Supabase storage
  static bool isSupabaseStorageUrl(String url) {
    return url.contains('.supabase.co/storage/v1/object/public/');
  }
  
  // Get cached version or download if needed
  static Future<String> getImagePathForDisplay(String imagePath, int userId) async {
    // If it's already a local file or asset, just return it
    if (imagePath.startsWith('assets/') || 
        (!imagePath.startsWith('http://') && !imagePath.startsWith('https://'))) {
      return imagePath;
    }
    
    // Try to get a cached version of the network image
    final fileName = 'profile_${userId}${path.extension(imagePath)}';
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = '${appDir.path}/$fileName';
    final localFile = File(localPath);
    
    if (await localFile.exists()) {
      // Use cached version if it exists
      return localPath;
    } else {
      // Download and cache the image
      final savedPath = await saveNetworkImageLocally(imagePath, customName: fileName);
      return savedPath ?? imagePath;
    }
  }
}