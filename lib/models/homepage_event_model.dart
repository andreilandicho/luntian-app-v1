class HomepageEventModel {
  final int eventId;
  final int createdBy;
  final int? barangayId;
  final String? eventTitle;
  final String? eventDescription;
  final DateTime? eventDate;
  final String? eventLocation;
  final bool isPublic;
  final DateTime? createdAt;
  final List<String>? imageUrls;
  final int? volunteersNeeded;
  final String? creatorName;
  final int? interestedCount;
  final bool? isInterested;

  HomepageEventModel({
    required this.eventId,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventDate,
    required this.eventLocation,
    required this.isPublic,
    this.barangayId,
    this.imageUrls,
    required this.createdBy,
    this.createdAt,
    this.volunteersNeeded,
    this.creatorName,
    this.interestedCount,
    this.isInterested,
  });
  HomepageEventModel copyWith({
    int? eventId,
    int? createdBy,
    int? barangayId,
    String? eventTitle,
    String? eventDescription,
    DateTime? eventDate,
    String? eventLocation,
    bool? isPublic,
    DateTime? createdAt,
    List<String>? imageUrls,
    int? volunteersNeeded,
    String? creatorName,
    int? interestedCount,
    bool? isInterested,
  }) {
    return HomepageEventModel(
      eventId: eventId ?? this.eventId,
      createdBy: createdBy ?? this.createdBy,
      barangayId: barangayId ?? this.barangayId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDescription: eventDescription ?? this.eventDescription,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      volunteersNeeded: volunteersNeeded ?? this.volunteersNeeded,
      creatorName: creatorName ?? this.creatorName,
      interestedCount: interestedCount ?? this.interestedCount,
      isInterested: isInterested ?? this.isInterested,
    );
  }

  factory HomepageEventModel.fromJson(Map<String, dynamic> json) {
    return HomepageEventModel(
      eventId: json['event_id'],
      eventTitle: json['title'] as String?,
      eventDescription: json['description'] as String?,
      eventDate: DateTime.tryParse(json['event_date']) ?? DateTime.now(),
      eventLocation: json['location'] as String?,
      isPublic: json['ispublic'] ?? false,
      barangayId: json['barangay_id'] as int?,
      imageUrls: json['photo_urls'] != null ? List<String>.from(json['photo_urls']) : null,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      volunteersNeeded: json['volunteers_needed'] as int?,
      creatorName: json['creator_name']?.toString(),
      interestedCount: json['interested_count'] ?? 0,
      isInterested: json['is_interested'] ?? false,
    );
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