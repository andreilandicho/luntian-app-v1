import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Assumes supabase is already initialized in your app!
final supabase = Supabase.instance.client;

class SolutionService {
  /// Uploads images to "solution-photos", then inserts a record in "reports_solutions".
  /// Returns true if success, false otherwise.
  static Future<bool> submitReportSolution({
    required int reportId,
    required int userId,
    required List<File> imageFiles,
    required String cleanupNotes,
  }) async {
    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileExt = path.extension(file.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i$fileExt';
        final bytes = await file.readAsBytes();

        // Upload to solution-photos bucket
        await supabase.storage
            .from('solution-photos')
            .uploadBinary(
              'reports/$fileName',
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );

        // Get public URL for the uploaded file
        final imageUrl = supabase.storage
            .from('solution-photos')
            .getPublicUrl('reports/$fileName');
        uploadedUrls.add(imageUrl);
      }

      // Prepare data for insert
      final data = {
        'report_id': reportId,
        'updated_by': userId,
        'new_status': 'in_progress',
        'after_photo_urls': uploadedUrls,
        'cleanup_notes': cleanupNotes,
        'updated_at': DateTime.now().toIso8601String(),
        'approval_status': 'pending',
      };

      // Insert into reports_solutions table
      final response = await supabase
          .from('report_solutions')
          .insert(data)
          .select();

      return response != null;
    } catch (e) {
      print('Error submitting solution: $e');
      return false;
    }
  }
}