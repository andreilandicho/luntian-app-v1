class UserOfficialModel {
  final int officialId;
  final int officialUserId;
  final int officialBarangayId;
  String officialName;
  String officialEmail;
  String ?officialProfileUrl;

  UserOfficialModel({
    required this.officialId,
    required this.officialUserId,
    required this.officialBarangayId,
    required this.officialName,
    required this.officialEmail,
    this.officialProfileUrl,
  });

  factory UserOfficialModel.fromJson(Map<String, dynamic> json) {
    return UserOfficialModel(
      officialId: json['official_id'] ?? 0, //for mapping reports assigned to this official using the reports assignment table
      officialUserId: json['user_id'] ?? 0, //for modifying users table such as changing password
      officialBarangayId: json['barangay_id'] ?? 0, //for identifying which barangay this official belongs to
      officialName: json['name'] ?? '', //for displaying name in the app
      officialEmail: json['email'] ?? '', //for displaying email in the app
      officialProfileUrl: json['user_profile_url'] ?? '', //for displaying profile picture in the app
    );
  }
}