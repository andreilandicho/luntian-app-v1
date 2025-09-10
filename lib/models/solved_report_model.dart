class SolvedReportModel {
  final int reportId;
  final int userId;
  final String username;
  final String? userProfileUrl;
  final int barangayId;
  final String description;
  final List<String> photoUrls;
  final bool anonymous;
  final String status;
  final DateTime createdAt;
  final String? cleanupNotes;
  final DateTime? solutionUpdated;
  final List<String>? afterPhotoUrls;
  final List<int> assignedOfficials;
  final double? overallAverageRating;

  SolvedReportModel({
    required this.reportId,
    required this.userId,
    required this.username,
    this.userProfileUrl,
    required this.barangayId,
    required this.description,
    required this.photoUrls,
    required this.anonymous,
    required this.status,
    required this.createdAt,
    this.cleanupNotes,
    this.solutionUpdated,
    this.afterPhotoUrls,
    required this.assignedOfficials,
    this.overallAverageRating,
  });

  factory SolvedReportModel.fromJson(Map<String, dynamic> json) {
  return SolvedReportModel(
    reportId: json['report_id'] ?? -1,
    userId: json['user_id'] ?? -1,
    username: json['anonymous'] ? 'Anonymous Citizen' : (json['username'] ?? ''),
    userProfileUrl: json['anonymous'] ? null : (json['user_profile_url'] ?? ''),
    barangayId: json['barangay_id'] ?? -1,
    description: json['description'] ?? '',
    photoUrls: json['photo_urls'] != null ? List<String>.from(json['photo_urls']) : <String>[],
    anonymous: json['anonymous'] ?? false,
    status: json['status'] ?? '',
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    cleanupNotes: json['cleanup_notes'] ?? '', // <-- Default to empty string para ma-avoid ang null is not a subtype of String error
    solutionUpdated: json['solution_updated'] != null ? DateTime.parse(json['solution_updated']) : null,
    afterPhotoUrls: json['after_photo_urls'] != null ? List<String>.from(json['after_photo_urls']) : <String>[],
    assignedOfficials: json['assigned_officials'] != null ? List<int>.from(json['assigned_officials']) : <int>[],
    overallAverageRating: (json['overall_average_rating'] != null)
        ? double.tryParse(json['overall_average_rating'].toString())
        : 0.0,
  );
}
}