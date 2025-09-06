class HomepageEventModel {
  final int id;
  final String? title;
  final String? description;
  final DateTime? date;
  final String? location;
  final bool isPublic;
  final int? barangayId;
  final List<String>? imageUrls;
  final int createdBy; //event initiator to show in the admin end

  HomepageEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.isPublic,
    this.barangayId,
    this.imageUrls,
    required this.createdBy,

  });

  factory HomepageEventModel.fromJson(Map<String, dynamic> json) {
    return HomepageEventModel(
      id: json['event_id'],
      title: json['title'] as String?,
      description: json['description'] as String?,
      date: DateTime.tryParse(json['event_date']) ?? DateTime.now(),
      location: json['location'] as String?,
      isPublic: json['isPublic'] ?? false,
      barangayId: json['barangay_id'] as int?,
      imageUrls: json['photo_urls'] != null ? List<String>.from(json['photo_urls']) : null,
      createdBy: json['created_by'],
    );
  }
}