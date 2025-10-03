// submitted_solution.dart
class SubmittedSolution {
  final int solutionId;
  final int reportId;
  final String reporterName;
  final String profileImage;
  final String reportDate;
  final String solutionDate;
  final String priority;
  final List<String> originalImages;
  final List<String> solutionImages;
  final String description;
  final String cleanupNotes;
  final String? descriptiveLocation;
  final bool isHazardous;
  final String reportCategory;
  final String reportStatus;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final DateTime? reportDeadline;
  final double? lat;
  final double? lon;
  final List<String> assignedOfficials;

  SubmittedSolution({
    required this.solutionId,
    required this.reportId,
    required this.reporterName,
    required this.profileImage,
    required this.reportDate,
    required this.solutionDate,
    required this.priority,
    required this.originalImages,
    required this.solutionImages,
    required this.description,
    required this.cleanupNotes,
    this.descriptiveLocation,
    required this.isHazardous,
    required this.reportCategory,
    required this.reportStatus,
    required this.approvalStatus,
    this.reportDeadline,
    this.lat,
    this.lon,
    required this.assignedOfficials,
  });

  factory SubmittedSolution.fromJson(Map<String, dynamic> json) {
    return SubmittedSolution(
      solutionId: json['solutionId'] as int,
      reportId: json['reportId'] as int,
      reporterName: json['reporterName'] as String,
      profileImage: json['profileImage'] as String,
      reportDate: json['reportDate'] as String,
      solutionDate: json['solutionDate'] as String,
      priority: json['priority'] as String,
      originalImages: List<String>.from(json['originalImages'] as List),
      solutionImages: List<String>.from(json['solutionImages'] as List),
      description: json['description'] as String,
      cleanupNotes: json['cleanupNotes'] as String,
      descriptiveLocation: json['descriptive_location'] as String?,
      isHazardous: json['isHazardous'] as bool,
      reportCategory: json['reportCategory'] as String,
      reportStatus: json['reportStatus'] as String,
      approvalStatus: json['approval_status'] as String,
      reportDeadline: json['reportDeadline'] != null 
          ? DateTime.parse(json['reportDeadline'] as String)
          : null,
      lat: json['lat'] as double?,
      lon: json['lon'] as double?,
      assignedOfficials: List<String>.from(json['assignedOfficials'] as List),
    );
  }
}