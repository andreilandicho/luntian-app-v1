class UserModel {
  final int id;
  final String email;
  final String role;
  final int? barangayId;
  final bool? verified;
  final String? firstName;
  final String? lastName;
  
  String get name => firstName != null || lastName != null 
      ? _combineNames(firstName, lastName) 
      : email.split('@')[0];

  UserModel({
    required this.id,  // Make ID required
    required this.email,
    required this.role,
    this.barangayId,
    this.verified = false,
    this.firstName,
    this.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Check if ID is missing
    if (json['id'] == null) {
      throw Exception('User ID is missing from API response. Cannot create user model.');
    }
    
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'citizen',
      barangayId: json['barangay_id'],
      verified: json['verified'] ?? false,
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'barangay_id': barangayId,
      'verified': verified,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
  
  // Helper method to combine firstName and lastName
  static String _combineNames(String? firstName, String? lastName) {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName;
    } else if (lastName != null) {
      return lastName;
    }
    return 'User';
  }
}