import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/data/models/student_in_event_model.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

/// Service quản lý bảng student_in_event
class StudentInEventService {
  SupabaseClient get _supabase => Supabase.instance.client;
  static const String _tableName = 'student_in_event';
  static const String _idColumn = 'student_in_event_id';

  /// Lấy tất cả sinh viên trong tất cả sự kiện
  Future<List<StudentInEvent>> fetchAllStudentsInEvents() async {
    try {
      final data = await _supabase.from(_tableName).select('''
  student_in_event_id, status, event_id, student_id,
  student!fk_student_in_event_student(student_id, student_code, name),
  event(event_id, title)
''');

      print('🔥 Raw data tất cả sự kiện: $data');
      return data.map<StudentInEvent>((item) => StudentInEvent.fromJson(item)).toList();
    } catch (e) {
      print('Lỗi khi lấy tất cả sinh viên trong các sự kiện: $e');
      throw Exception('Không thể tải danh sách sinh viên trong các sự kiện.');
    }
  }

  /// Lấy danh sách sinh viên
  Future<List<StudentInEvent>> fetchStudentsByEvent(int eventId) async {
    try {
      final data = await _supabase.from(_tableName).select('''
        student_in_event_id, status, event_id, student_id,
        student(student_id, student_code, name),
        event(event_id, title)
      ''').eq('event_id', eventId);

      print('🔥 Raw data sự kiện $eventId: $data');
      return data.map<StudentInEvent>((item) => StudentInEvent.fromJson(item)).toList();
    } catch (e) {
      print('Lỗi khi lấy sinh viên trong sự kiện $eventId: $e');
      throw Exception('Không thể tải danh sách sinh viên.');
    }
  }

  /// Cập nhật trạng thái của một sinh viên trong sự kiện
  Future<void> updateStudentStatus(int? studentInEventId, String newStatus) async {
    if (studentInEventId == null) {
      throw Exception('ID bản ghi không hợp lệ để cập nhật.');
    }
    try {
      await _supabase
          .from(_tableName)
          .update({'status': newStatus})
          .eq(_idColumn, studentInEventId);
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái: $e');
      throw Exception('Không thể cập nhật trạng thái.');
    }
  }

  /// Gửi đánh giá và phản hồi cho sự kiện
  Future<void> submitRating(int studentInEventId, int rating, String feedback) async {
    try {
      await _supabase
          .from(_tableName)
          .update({
            'rating': rating,
            'feedback': feedback,
          })
          .eq(_idColumn, studentInEventId);
    } catch (e) {
      print('Lỗi khi gửi đánh giá: $e');
      throw Exception('Không thể gửi đánh giá.');
    }
  }

  /// Thêm một sinh viên vào sự kiện bằng student_code
  Future<StudentInEvent?> addStudentToEvent(int eventId, String studentCode) async {
    try {
      // 1. Tìm student_id theo student_code
      final studentData = await _supabase
          .from('student')
          .select('student_id')
          .eq('student_code', studentCode)
          .maybeSingle();

      if (studentData == null) {
        throw Exception("Không tìm thấy sinh viên với mã: $studentCode");
      }

      final studentId = studentData['student_id'];

      // 2. Insert student vào event
      final data = await _supabase
          .from(_tableName)
          .insert({
        'event_id': eventId,
        'student_id': studentId,
        'status': 'registered',
      })
          .select('''
            student_in_event_id, student_id, event_id, status,
            student(student_id, student_code, name),
            event(event_id, title)
          ''')
          .single();

      print("🔥 Insert result: $data");

      return StudentInEvent.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception("Sinh viên này đã đăng ký sự kiện.");
      }
      print('Lỗi Postgres khi thêm sinh viên: ${e.message}');
      throw Exception("Không thể thêm sinh viên vào sự kiện.");
    } catch (e) {
      print('Lỗi khác khi thêm sinh viên: $e');
      throw Exception("Không thể thêm sinh viên vào sự kiện.");
    }
  }

  /// Xóa một sinh viên khỏi sự kiện
  Future<void> deleteStudentFromEvent(int? studentInEventId) async {
    if (studentInEventId == null) {
      throw Exception('ID bản ghi không hợp lệ để xóa.');
    }
    try {
      await _supabase.from(_tableName).delete().eq(_idColumn, studentInEventId);
    } catch (e) {
      print('Lỗi khi xóa sinh viên khỏi sự kiện: $e');
      throw Exception('Không thể xóa sinh viên.');
    }
  }

  /// Import danh sách sinh viên từ file Excel
Future<void> importStudentsFromExcel() async {
    try {
      // 1️⃣ Chọn file Excel
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        print("❌ Không có file nào được chọn.");
        return;
      }

      final file = File(result.files.single.path!);
      print("📂 File được chọn: ${file.path}");

      final bytes = await file.readAsBytes();

      // 2️⃣ Đọc Excel
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        print("❌ File Excel không có sheet nào.");
        return;
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      print("📑 Sheet: $sheetName, Tổng số dòng: ${sheet.rows.length}");

      if (sheet.rows.length <= 1) {
        print("⚠️ File Excel không có dữ liệu (chỉ có header hoặc rỗng).");
        return;
      }

      final List<Map<String, dynamic>> rowsToUpsert = [];
      int skippedRows = 0;
      int processedRows = 0;

      // 3️⃣ Duyệt từng dòng (bỏ header)
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        print("🔍 Đang xử lý dòng ${i + 1}...");

        final eventIdStr = row[0]?.value?.toString().trim() ?? '';
        final studentCode = row[1]?.value?.toString().trim() ?? '';
        final status = row[2]?.value?.toString().trim() ?? 'registered';

        if (eventIdStr.isEmpty || studentCode.isEmpty) {
          print("⚠️ Dòng ${i + 1} bị bỏ qua: Thiếu event_id hoặc student_code.");
          skippedRows++;
          continue;
        }

        final eventId = int.tryParse(eventIdStr);
        if (eventId == null) {
          print("⚠️ Dòng ${i + 1} bị bỏ qua: event_id không hợp lệ ($eventIdStr).");
          skippedRows++;
          continue;
        }

        // Kiểm tra status hợp lệ
        const allowedStatuses = ['registered', 'attended', 'cancelled', 'pending'];
        if (!allowedStatuses.contains(status.toLowerCase())) {
          print("⚠️ Dòng ${i + 1} bị bỏ qua: Status không hợp lệ ($status). Chỉ chấp nhận: $allowedStatuses.");
          skippedRows++;
          continue;
        }

        // 4️⃣ Kiểm tra event_id tồn tại
        Map<String, dynamic>? eventData;
        try {
          eventData = await _supabase
              .from('event')
              .select('event_id')
              .eq('event_id', eventId)
              .maybeSingle();
        } catch (e) {
          print("❌ Lỗi khi kiểm tra event_id $eventId ở dòng ${i + 1}: $e");
          skippedRows++;
          continue;
        }

        if (eventData == null) {
          print("⚠️ Dòng ${i + 1} bị bỏ qua: Không tìm thấy event_id $eventId trong bảng event.");
          skippedRows++;
          continue;
        }

        // 5️⃣ Lookup student_id từ student_code
        Map<String, dynamic>? studentData;
        try {
          studentData = await _supabase
              .from('student')
              .select('student_id')
              .eq('student_code', studentCode)
              .maybeSingle();
        } catch (e) {
          print("❌ Lỗi khi tìm sinh viên mã $studentCode ở dòng ${i + 1}: $e");
          skippedRows++;
          continue;
        }

        if (studentData == null) {
          print("⚠️ Dòng ${i + 1} bị bỏ qua: Không tìm thấy sinh viên với mã $studentCode trong bảng student.");
          skippedRows++;
          continue;
        }

        final studentId = studentData['student_id'];
        print("✅ Dòng ${i + 1}: Xác thực OK - event_id: $eventId, student_id: $studentId, status: $status.");

        rowsToUpsert.add({
          'event_id': eventId,
          'student_id': studentId,
          'status': status,
        });
        processedRows++;
      }

      if (rowsToUpsert.isEmpty) {
        print("⚠️ Không có dữ liệu hợp lệ để upsert. ($skippedRows dòng bị bỏ qua)");
        return;
      }

      print("📊 Tổng dòng xử lý: $processedRows, Hợp lệ để upsert: ${rowsToUpsert.length} ($skippedRows bị bỏ qua).");

      // 6️⃣ Upsert từng dòng một để tránh lỗi bulk với conflict
      int upsertedCount = 0;
      for (var row in rowsToUpsert) {
        final eventId = row['event_id'];
        final studentId = row['student_id'];
        final status = row['status'];

        try {
          // Kiểm tra tồn tại và cập nhật nếu cần
          final existing = await _supabase
              .from(_tableName)
              .select('student_in_event_id, status')
              .eq('event_id', eventId)
              .eq('student_id', studentId)
              .maybeSingle();

          if (existing != null) {
            // Nếu tồn tại và status khác, update
            if (existing['status'] != status) {
              await _supabase
                  .from(_tableName)
                  .update({'status': status})
                  .eq('event_id', eventId)
                  .eq('student_id', studentId);
              print("🔄 Dòng (event_id: $eventId, student_id: $studentId) đã cập nhật status thành $status.");
            } else {
              print("ℹ️ Dòng (event_id: $eventId, student_id: $studentId) đã tồn tại với status giống nhau, bỏ qua.");
            }
          } else {
            // Nếu chưa tồn tại, insert
            await _supabase.from(_tableName).insert(row);
            print("✅ Dòng (event_id: $eventId, student_id: $studentId) đã insert thành công.");
          }
          upsertedCount++;
        } catch (e) {
          print("❌ Lỗi khi xử lý dòng (event_id: $eventId, student_id: $studentId): $e");
        }
      }

      print("✅ Hoàn tất upsert: $upsertedCount dòng thành công.");

    } catch (e) {
      print("❌ Lỗi tổng quát khi import Excel: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveEvents() async {
    try {
      final data = await _supabase
          .from('event')
          .select('event_id, title, start_date, end_date')
          .gte('end_date', DateTime.now().toUtc().toIso8601String());

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Lỗi khi lấy sự kiện: $e");
      rethrow;
    }
  }

  /// Lấy tất cả sự kiện (cũ + mới)
  Future<List<Map<String, dynamic>>> fetchAllEvents() async {
    try {
      final data = await _supabase
          .from('event')
          .select('event_id, title, description, organizer, start_date, end_date, user_id');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Lỗi khi lấy tất cả sự kiện: $e");
      rethrow;
    }
  }
}