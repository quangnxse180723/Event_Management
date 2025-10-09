import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/app_user.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// lấy thông tin người dùng bằng email
  Future<AppUser?> getUserByEmail(String email) async {
    final data = await _supabase
        .from('app_user')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (data == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(data));
  }
  /// Đăng nhập với email & password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    // 1. Gọi Supabase auth
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception("Đăng nhập thất bại. Kiểm tra lại email/mật khẩu.");
    }

    final userId = response.user!.id;

    // 2. Truy vấn bảng `app_user` để lấy user_id và role
    final userData = await _supabase
        .from('app_user')
        .select('user_id, role')
        .eq('auth_id', userId)
        .single();

    if (userData == null) {
      throw Exception("Không tìm thấy thông tin người dùng trong hệ thống.");
    }

    // 3. (Optional) Lấy name từ bảng student nếu có
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

  /// Đăng ký tài khoản sinh viên (Sign Up)
  Future<Map<String, dynamic>> signUpStudent(String email, String password) async {
    // 1. Tạo tài khoản trên Supabase Auth
    final response = await _supabase.auth.signUp(email: email, password: password);
    final authUser = response.user;
    if (authUser == null) throw Exception("Đăng ký thất bại!");

    // 2. Insert vào bảng app_user với role student
    final userRecord = await _supabase
        .from('app_user')
        .insert({
      'auth_id': authUser.id,
      'email': email,
      'role': 'student',
    })
        .select()
        .single();

    return {
      'role': userRecord['role'],
      'id': userRecord['user_id'],
    };
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Lấy user hiện tại (nếu có)
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final userData = await _supabase
        .from('app_user')
        .select('user_id, role')
        .eq('auth_id', user.id)
        .single();

    if (userData == null) return null;

    // (Optional) Lấy name từ bảng student nếu có
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
    if (user == null || user.email == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    try {
      // Thử đăng nhập lại để xác minh mật khẩu
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
      // Nếu không có lỗi, mật khẩu đúng
      return true;
    } on AuthException {
      // Nếu có lỗi xác thực, tức là sai mật khẩu
      rethrow; // Ném lại lỗi để UI bắt được
    } catch (e) {
      // Các lỗi khác
      throw Exception('Lỗi không xác định khi xác minh mật khẩu.');
    }
  }

  // HÀM MỚI 2: Cập nhật mật khẩu người dùng
  Future<void> updateUserPassword(String newPassword) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập.');
    }

    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      print('Lỗi khi cập nhật mật khẩu: $e');
      throw Exception('Không thể cập nhật mật khẩu.');
    }
  }
}