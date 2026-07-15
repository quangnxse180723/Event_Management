import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/app_user.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AppUser?> getUserByEmail(String email) async {
    final data = await _supabase
        .from('app_user')
        .select()
        .eq('email', email)
        .maybeSingle();
    return data == null
        ? null
        : AppUser.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Đăng nhập thất bại. Kiểm tra lại email và mật khẩu.');
    }

    final userData = await _supabase
        .from('app_user')
        .select('user_id, role')
        .eq('auth_id', authUser.id)
        .maybeSingle();
    if (userData == null) {
      throw Exception('Không tìm thấy profile người dùng trong hệ thống.');
    }

    final studentData = await _supabase
        .from('student')
        .select('name')
        .eq('user_id', userData['user_id'])
        .maybeSingle();
    return {
      'id': userData['user_id'],
      'role': userData['role'],
      'name': studentData?['name'],
    };
  }

  Future<Map<String, dynamic>> signUpStudent(
    String email,
    String password, {
    String? fullName,
    String? studentCode,
    String? major,
    int? universityId,
    int? campusId,
  }) async {
    final metadata = <String, dynamic>{
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
      if (studentCode != null && studentCode.trim().isNotEmpty)
        'student_code': studentCode.trim().toUpperCase(),
      if (major != null && major.trim().isNotEmpty)
        'major': major.trim(),
      if (universityId != null) 'university_id': universityId,
      if (campusId != null) 'campus_id': campusId,
    };
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
    final authUser = response.user;
    if (authUser == null) throw Exception('Đăng ký thất bại.');

    // The database trigger creates the profile even if email confirmation is on.
    if (response.session == null) {
      return {
        'role': 'student',
        'id': null,
        'emailConfirmationRequired': true,
      };
    }

    // Fallback keeps compatibility if the migration has not been run yet.
    var userRecord = await _supabase
        .from('app_user')
        .select('user_id, role')
        .eq('auth_id', authUser.id)
        .maybeSingle();
    userRecord ??= await _supabase
        .from('app_user')
        .insert({
          'auth_id': authUser.id,
          'email': email,
          'role': 'student',
        })
        .select('user_id, role')
        .single();

    if (fullName != null &&
        fullName.trim().isNotEmpty &&
        studentCode != null &&
        studentCode.trim().isNotEmpty &&
        universityId != null) {
      final existingStudent = await _supabase
          .from('student')
          .select('student_id')
          .eq('user_id', userRecord['user_id'])
          .maybeSingle();
      if (existingStudent == null) {
        await _supabase.from('student').insert({
          'user_id': userRecord['user_id'],
          'university_id': universityId,
          if (campusId != null) 'campus_id': campusId,
          'name': fullName.trim(),
          'email': email,
          'student_code': studentCode.trim().toUpperCase(),
          'phone': '',
          if (major != null && major.trim().isNotEmpty) 'major': major.trim(),
        });
      }
    }

    return {
      'role': userRecord['role'],
      'id': userRecord['user_id'],
      'emailConfirmationRequired': false,
    };
  }

  Future<List<Map<String, dynamic>>> getUniversities() async {
    final data = await _supabase
        .from('university')
        .select('university_id, name')
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  // HÀM MỚI: Quên mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.eventapp://login-callback/',
      );
    } catch (e) {
      print('Lỗi khi gửi email đặt lại mật khẩu: $e');
      throw Exception('Không thể gửi yêu cầu đặt lại mật khẩu. Vui lòng kiểm tra lại email.');
    }
  }

  Future<List<Map<String, dynamic>>> getCampuses(int universityId) async {
    final data = await _supabase
        .from('university_campus')
        .select('campus_id, name, address')
        .eq('university_id', universityId)
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> signOut() => _supabase.auth.signOut();

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final userData = await _supabase
        .from('app_user')
        .select('user_id, role')
        .eq('auth_id', user.id)
        .maybeSingle();
    if (userData == null) return null;
    final studentData = await _supabase
        .from('student')
        .select('name')
        .eq('user_id', userData['user_id'])
        .maybeSingle();
    return {
      'id': userData['user_id'],
      'role': userData['role'],
      'name': studentData?['name'],
    };
  }

  Future<bool> verifyCurrentPassword(String password) async {
    final user = _supabase.auth.currentUser;
    if (user?.email == null) throw Exception('Người dùng chưa đăng nhập.');
    await _supabase.auth
        .signInWithPassword(email: user!.email!, password: password);
    return true;
  }

  Future<void> updateUserPassword(String newPassword) async {
    if (_supabase.auth.currentUser == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
