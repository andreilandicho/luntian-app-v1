class EventModel {
  final int eventId;
  final int? createdBy;
  final int? barangayId;
  final String? title;
  final String? description;
  final DateTime? eventDate;
  final String? location;
  final String approvalStatus;
  final DateTime? createdAt;
  final bool isPublic;
  final List<String> photoUrls;

  EventModel({
    required this.eventId,
    this.createdBy,
    this.barangayId,
    this.title,
    this.description,
    this.eventDate,
    this.location,
    required this.approvalStatus,
    this.createdAt,
    required this.isPublic,
    required this.photoUrls,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['event_id'],
      createdBy: json['created_by'],
      barangayId: json['barangay_id'],
      title: json['title'],
      description: json['description'],
      eventDate: json['event_date'] != null && json['event_date'] != "" ? DateTime.parse(json['event_date']) : null,
      location: json['location']?.toString(),
      approvalStatus: json['approval_status'] ?? 'pending',
      createdAt: json['created_at'] != null && json['created_at'] != "" ? DateTime.parse(json['created_at']) : null,
      isPublic: json['isPublic'] ?? false,
      photoUrls: json['photo_urls'] == null
          ? []
          : List<String>.from(json['photo_urls']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'created_by': createdBy,
      'barangay_id': barangayId,
      'title': title,
      'description': description,
      'event_date': eventDate?.toIso8601String(),
      'location': location,
      'approval_status': approvalStatus,
      'created_at': createdAt?.toIso8601String(),
      'isPublic': isPublic,
      'photo_urls': photoUrls,
    };
  }
}