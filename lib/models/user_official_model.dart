class UserOfficialModel {
  final int officialId;
  final int officialUserId;
  final int officialBarangayId;
  String officialName;
  String officialEmail;

  UserOfficialModel({
    required this.officialId,
    required this.officialUserId,
    required this.officialBarangayId,
    required this.officialName,
    required this.officialEmail,
  });

  factory UserOfficialModel.fromJson(Map<String, dynamic> json) {
    return UserOfficialModel(
      officialId: json['official_id'], //for mapping reports assigned to this official using the reports assignment table
      officialUserId: json['oicffial_user_id'], //for modifying users table such as changing password
      officialBarangayId: json['official_barangay_id'], //for identifying which barangay this official belongs to
      officialName: json['official_name'], //for displaying name in the app
      officialEmail: json['official_email'], //for displaying email in the app
    );
  }
}