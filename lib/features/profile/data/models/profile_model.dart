class ProfileModel {
  final String id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['avatar_url'] as String? ?? json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'bio': bio,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toPatchJson() {
    return {
      'username': username,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (bio != null) 'bio': bio,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
