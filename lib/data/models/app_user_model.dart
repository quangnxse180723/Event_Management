import 'package:student_attendance/data/models/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.userId,
    required super.email,
    required super.role,
    super.authId,
    super.avatarUrl,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      userId: json['user_id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      authId: json['auth_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
