class PendingReport {
  final int reportId;
  final String reporterName;
  final String profileImage;
  final String reportDate;
  final String priority;
  final List<String> postImages;
  final String description;
  final String? location;
  final bool isHazardous;
  final String reportCategory;
  final String status;
  final DateTime? reportDeadline;
  final double? lat;
  final double? lon;
  final List<String> assignedOfficials;
  final bool anonymous; // ✅ add this

  PendingReport({
    required this.reportId,
    required this.reporterName,
    required this.profileImage,
    required this.reportDate,
    required this.priority,
    required this.postImages,
    required this.description,
    this.location,
    required this.isHazardous,
    required this.reportCategory,
    required this.status,
    this.reportDeadline,
    this.lat,
    this.lon,
    required this.assignedOfficials,
    required this.anonymous, // ✅ add this
  });

  factory PendingReport.fromJson(Map<String, dynamic> json) {
    String? deadlineString = json['reportDeadline'];
    DateTime? deadline;
    if (deadlineString != null && deadlineString.isNotEmpty) {
      deadline = DateTime.tryParse(deadlineString);
    }
    return PendingReport(
      reportId: json['reportId'],
      reporterName: json['reporterName'],
      profileImage: json['profileImage'],
      reportDate: json['reportDate'],
      priority: json['priority'],
      postImages: List<String>.from(json['postImages']),
      description: json['description'],
      location: json['location'],
      isHazardous: json['isHazardous'],
      reportCategory: json['reportCategory'],
      status: json['status'],
      reportDeadline: deadline,
      lat: (json['lat'] is num) ? (json['lat'] as num).toDouble() : null,
      lon: (json['lon'] is num) ? (json['lon'] as num).toDouble() : null,
      assignedOfficials: List<String>.from(json['assignedOfficials']),
      anonymous: json['anonymous'] ?? false, // ✅ make sure you have this
    );
  }
}