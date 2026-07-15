class AppUser {
  final int userId;
  final String email;
  final String role;
  final String? authId;
  final String? avatarUrl;

  const AppUser({
    required this.userId,
    required this.email,
    required this.role,
    this.authId,
    this.avatarUrl,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isOrganizer => role.toLowerCase() == 'organizer';
  bool get isStudent => role.toLowerCase() == 'student';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      authId: json['auth_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'role': role,
      'auth_id': authId,
      'avatar_url': avatarUrl,
    };
  }
}
