import 'package:student_attendance/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/data/models/student.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class StudentService {
  final supabase = Supabase.instance.client;
  static const studentTable = 'student';
  static const studentInEventTable = 'student_in_event';

  /// -------------------------------
  /// CRUD cho student
  /// -------------------------------
  Future<List<Student>> getStudents({String? searchQuery, int limit = 15, int offset = 0}) async {
    var query = supabase.from(studentTable).select();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.range(offset, offset + limit - 1).order('name', ascending: true);

    return (response as List)
        .map((row) => Student.fromJson(row as Map<String, dynamic>))
        .toList();
  }

// Trong class StudentService

// Trong class StudentService
// ✨ PHIÊN BẢN NÂNG CẤP (giống logic hàm import) ✨

  Future<void> addStudent(Student student, String email, String password) async {

    // Bỏ hết logic cũ (AuthService, dọn dẹp, rollback...)

    try {
      // 1. Gọi thẳng "Hàm Thần" (RPC) vừa tạo
      //    và truyền tất cả tham số vào
      final response = await supabase.rpc('fn_create_student_and_user', params: {
        'p_email': email,
        'p_password': password,
        'p_name': student.name,
        'p_student_code': student.studentCode,
        'p_phone': student.phone,
        'p_university_id': student.universityId,
      });

      // 2. (Optional) In ra log thành công
      // Hàm RPC của mình trả về student_id mới
      print('✅ [RPC] Tạo user và student THÀNH CÔNG! Student ID mới là: $response');

      // 2.5 Cập nhật campus_id nếu có
      if (student.campusId != null) {
        await supabase
            .from(studentTable)
            .update({'campus_id': student.campusId})
            .eq('student_id', response);
        print('✅ Đã cập nhật campus_id cho sinh viên: ${student.campusId}');
      }

    } on PostgrestException catch (error) {
      // 3. Bắt lỗi từ CSDL
      // Nếu CSDL ném lỗi (ví dụ: email trùng, mã SV trùng)
      // nó sẽ bị bắt ở đây
      print('❌ [RPC] Lỗi từ CSDL: ${error.message}');

      // 4. Ném ra thông báo lỗi thân thiện cho UI (màn hình) bắt

      // Check lỗi trùng email
      if (error.message.contains('app_user_email_key') ||
          error.message.contains('users_email_key')) {
        throw Exception('Email này đã tồn tại. Vui lòng dùng email khác.');
      }

      // Check lỗi trùng Mã SV (anh thay 'student_student_code_key'
      // bằng tên 'unique constraint' của cột student_code nha)
      if (error.message.contains('student_student_code_key')) {
        throw Exception('Mã sinh viên [${student.studentCode}] này đã tồn tại.');
      }

      // Lỗi chung
      throw Exception('Lỗi CSDL: ${error.message}'); // Ném lỗi gốc

    } catch (e) {
      // Các lỗi chung khác (ví dụ: mất mạng)
      print('❌ [RPC] Lỗi chung: $e');
      throw Exception('Đã có lỗi không xác định xảy ra.');
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      // Chỉ cần dựa vào student_id vì nó là unique
      final res = await supabase
          .from(studentTable)
          .update(student.toJson())
          .eq('student_id', student.studentId)
          .select();

      if (res == null || (res is List && res.isEmpty)) {
        print('No student updated. Check studentId: ${student.studentId}');
      } else {
        print('Student updated successfully: $res');
      }
    } catch (e) {
      print('Error updating student: $e');
    }
  }

  Future<void> deleteStudent(int studentId) async {
    await supabase.from(studentTable).delete().eq('student_id', studentId);
  }

  /// -------------------------------
  /// Import sinh viên từ Excel
  /// -------------------------------
  Future<void> importStudentsFromExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final authService = AuthService();

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      final rows = sheet.rows;

      // Giả sử header nằm ở hàng đầu tiên
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];

        final name = row[0]?.value.toString() ?? '';
        final studentCode = row[1]?.value.toString() ?? '';
        final phone = row[2]?.value.toString() ?? '';
        final universityId = int.tryParse(row[3]?.value.toString() ?? '');
        final email = row[4]?.value.toString() ?? '';
        final passwordValue = row[5]?.value?.toString().trim() ?? '';
        final password = passwordValue.isEmpty ? '123456' : passwordValue;


        if (email.isEmpty) {
          print('⚠️ Bỏ qua dòng $i: thiếu email.');
          continue;
        }

        try {
          // 1️⃣ Kiểm tra user đã tồn tại chưa
          final existingUser = await authService.getUserByEmail(email);

          int appUserId;

          if (existingUser == null) {
            // 2️⃣ Nếu chưa có, tạo user mới
            final userRecord = await authService.signUpStudent(email, password);
            appUserId = userRecord['id'];
            print('✅ Đã tạo user mới cho $email (user_id: $appUserId)');
          } else {
            appUserId = existingUser.userId; // hoặc existingUser['user_id'] nếu map
            print('ℹ️ User đã tồn tại cho $email (user_id: $appUserId)');
          }

          // 3️⃣ Tạo đối tượng Student
          final newStudent = Student.createForInsert(
            name: name,
            studentCode: studentCode,
            phone: phone,
            universityId: universityId,
            userId: appUserId,
            createdAt: DateTime.now(),
          );

          // 4️⃣ Thêm vào DB
          await supabase.from(studentTable).insert(newStudent.toJson());

          print('🎓 Đã thêm sinh viên: $name ($email)');
        } catch (e) {
          print('❌ Lỗi dòng $i ($email): $e');
        }
      }
    }

    print('✅ Hoàn tất import sinh viên từ file Excel!');
  }


  /// -------------------------------
  /// Event logic
  /// -------------------------------

  /// Lấy danh sách sự kiện đã đăng ký theo studentId
  Future<List<Map<String, dynamic>>> getMyEventsByStudentId(int studentId) async {
    final response = await supabase
        .from(studentInEventTable)
        .select('''
        student_in_event_id,
        status,
        rating,
        feedback,
        created_at,
        event:event_id (
          event_id,
          title,
          start_date,
          end_date,
          description
        )
      ''')
        .eq('student_id', studentId);

    return List<Map<String, dynamic>>.from(response ?? []);
  }

  /// Lấy danh sách sự kiện đã đăng ký theo userId của app
  Future<List<Map<String, dynamic>>> getMyEventsForAppUserId(int appUserId) async {
    final studentRow = await supabase
        .from(studentTable)
        .select('student_id')
        .eq('user_id', appUserId)
        .maybeSingle();

    if (studentRow == null) return [];
    final studentId = studentRow['student_id'] as int;
    return getMyEventsByStudentId(studentId);
  }

  /// Đăng ký sự kiện
  Future<bool> registerEvent(int studentId, int eventId) async {
    final exists = await supabase
        .from(studentInEventTable)
        .select()
        .eq('student_id', studentId)
        .eq('event_id', eventId)
        .maybeSingle();

    if (exists != null) return false; // đã đăng ký rồi

    await supabase.from(studentInEventTable).insert({
      'student_id': studentId,
      'event_id': eventId,
      'status': 'registered',
      'created_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  /// Hủy đăng ký sự kiện
  Future<bool> unregisterEvent(int studentId, int eventId) async {
    final deleted = await supabase
        .from(studentInEventTable)
        .delete()
        .eq('student_id', studentId)
        .eq('event_id', eventId);

    return deleted != null;
  }

  /// Check xem sinh viên đã đăng ký chưa
  Future<bool> isRegistered(int studentId, int eventId) async {
    final exists = await supabase
        .from(studentInEventTable)
        .select('student_id')
        .eq('student_id', studentId)
        .eq('event_id', eventId)
        .maybeSingle();

    return exists != null;
  }
}