import 'package:supabase_flutter/supabase_flutter.dart';

class AppUserService {
  final SupabaseClient supabase;

  AppUserService(this.supabase);

  /// Tạo Auth user + app_user cho sinh viên
  Future<int> createUserForStudent(String studentName) async {
    final email = studentName.toLowerCase().replaceAll(' ', '') + '@example.com';
    final password = 'Temp1234'; // password tạm, có thể gửi cho sinh viên

    // 1. Tạo Auth user
    final authUser = await supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
      ),
    );

    final uid = authUser.user?.id;
    if (uid == null) throw Exception('Failed to create auth user');

    // 2. Lưu vào bảng app_user
    final response = await supabase.from('app_user').insert({
      'auth_id': uid,       // liên kết với Auth user
      'email': email,
      'role': 'student',
      'password_hash': password, // password tạm để admin gửi cho sinh viên
    }).select();

    if (response.isEmpty) throw Exception('Failed to create app_user');

    return response[0]['user_id'] as int; // trả về userId để gán vào student
  }
}
