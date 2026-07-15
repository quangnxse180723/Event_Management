import 'package:supabase_flutter/supabase_flutter.dart';

class SessionCheckInService {
  final supabase = Supabase.instance.client;

  Future<bool> createCheckin({
    required int sessionId,
    required int studentId,
    required String method,
  }) async {
    try {
      // 1. Check if student is already checked in for this session
      final existingCheckin = await supabase
          .from('session_checkin')
          .select('checkin_id')
          .eq('session_id', sessionId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (existingCheckin != null) {
        print('Student already checked in for this session');
        return false; // Student already checked in
      }

      // 2. Lấy user_id từ bảng student dựa vào studentId
      final student = await supabase
          .from('student')
          .select('user_id')
          .eq('student_id', studentId)
          .single();

      final userId = student['user_id'];
      if (userId == null) {
        print('Check-in error: user_id của sinh viên không tồn tại!');
        return false;
      }

      // 3. Thực hiện insert check-in với user_id lấy được
      final response = await supabase.from('session_checkin').insert({
        'session_id': sessionId,
        'student_id': studentId,
        'user_id': userId,
        'method': method,
      });

      print('DEBUG Insert response: $response');
      return true;
    } catch (e) {
      print('Check-in error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCheckinStatusForSession(int sessionId) async {
    try {
      // 1. Lấy event_id của session
      final sessionRes = await supabase
          .from('event_session')
          .select('event_id')
          .eq('session_id', sessionId)
          .single();
      final eventId = sessionRes['event_id'];

      // 2. Lấy danh sách sinh viên đã đăng ký event này
      final studentsInEventRes = await supabase
          .from('student_in_event')
          .select('student_id')
          .eq('event_id', eventId);

      if (studentsInEventRes.isEmpty) return [];

      final List<int> studentIds = studentsInEventRes
          .map<int>((e) => e['student_id'] as int)
          .toList();

      // 3. Lấy thông tin chi tiết sinh viên
      final inList = '(${studentIds.join(',')})';
      final studentsRes = await supabase
          .from('student')
          .select('student_id, name, student_code')
          .filter('student_id', 'in', inList);

      final studentsMap = {
        for (var s in studentsRes) s['student_id']: s
      };

      // 4. Lấy danh sách checkin của session này
      final checkinsRes = await supabase
          .from('session_checkin')
          .select('checkin_id, student_id, method, created_at')
          .eq('session_id', sessionId);

      // 5. Map check-in theo student_id để tra cứu nhanh
      final checkinsMap = {
        for (var c in checkinsRes) c['student_id']: c
      };

      // 6. Kết hợp dữ liệu
      final List<Map<String, dynamic>> result = [];
      for (var stId in studentIds) {
        final studentData = studentsMap[stId];
        final c = checkinsMap[stId];

        result.add({
          'student_id': stId,
          'student_name': studentData != null ? studentData['name'] : 'Unknown',
          'student_code': studentData != null ? studentData['student_code'] : 'Unknown',
          'checkin_id': c?['checkin_id'],
          'method': c?['method'],
          'checkin_time': c?['created_at'],
          'checkin_status': c != null ? 'Đã Check-in' : 'Chưa Check-in',
        });
      }

      return result;
    } catch (e) {
      print('Lỗi khi lấy danh sách điểm danh (không dùng RPC): $e');
      return [];
    }
  }

}
