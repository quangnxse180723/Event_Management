import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/data/models/event_session_model.dart';

class EventSessionService {
  SupabaseClient get _supabase => Supabase.instance.client;

  static const String _tableName = 'event_session';
  static const String _idColumn = 'session_id';

  Future<List<EventSession>> fetchEventSessions({int? eventId}) async {
    print('Đang lấy dữ liệu phiên sự kiện từ Supabase, bảng: $_tableName');
    try {
      final dynamic response;
      if (eventId != null) {
        response = await _supabase
            .from(_tableName)
            .select()
            .eq('event_id', eventId)
            .order('start_time', ascending: true);
      } else {
        response = await _supabase
            .from(_tableName)
            .select()
            .order('start_time', ascending: true);
      }

      final List<dynamic> data = response as List<dynamic>;
      final sessions = data.map((dynamic item) => EventSession.fromJson(item)).toList();
      print('Lấy dữ liệu phiên sự kiện thành công, số phiên: ${sessions.length}');
      return sessions;
    } catch (e, st) {
      print('Đã xảy ra lỗi khi lấy dữ liệu phiên sự kiện: $e\n$st');
      if (e is PostgrestException) {
        throw Exception('Lỗi từ server khi tải phiên sự kiện: ${e.message}');
      }
      throw Exception('Lỗi khi tải dữ liệu phiên sự kiện từ Supabase.');
    }
  }

  Future<EventSession> createEventSession(EventSession session) async {
    print('Đang tạo phiên sự kiện mới trên Supabase, bảng: $_tableName');

    // Kiểm tra trường bắt buộc
    if (session.eventId == null) {
      throw Exception('Không thể tạo phiên: eventId bị thiếu.');
    }

    try {
      // Chuẩn hóa payload: convert DateTime -> ISO string nếu cần
      final Map<String, dynamic> payload = _normalizeSessionPayload(session.toJson());

      // Insert và lấy single result
      final response = await _supabase
          .from(_tableName)
          .insert([payload])
          .select()
          .single();

      print('Tạo phiên sự kiện trên Supabase thành công!');
      return EventSession.fromJson(response as Map<String, dynamic>);
    } catch (e, st) {
      print('Lỗi khi tạo phiên sự kiện trên Supabase: $e\n$st');
      if (e is PostgrestException) {
        throw Exception('Lỗi từ server khi tạo phiên: ${e.message}');
      }
      throw Exception('Lỗi khi tạo phiên sự kiện.');
    }
  }

  Future<EventSession> updateEventSession(EventSession session) async {
    if (session.sessionId == null) {
      throw Exception('Không thể cập nhật phiên sự kiện vì thiếu ID.');
    }
    print('Đang cập nhật phiên sự kiện trên Supabase, ID: ${session.sessionId}');

    try {
      final Map<String, dynamic> payload = _normalizeSessionPayload(session.toJson());

      final response = await _supabase
          .from(_tableName)
          .update(payload)
          .eq(_idColumn, session.sessionId!)
          .select()
          .single();

      print('Cập nhật phiên sự kiện trên Supabase thành công!');
      return EventSession.fromJson(response as Map<String, dynamic>);
    } catch (e, st) {
      print('Lỗi khi cập nhật phiên sự kiện trên Supabase: $e\n$st');
      if (e is PostgrestException) {
        throw Exception('Lỗi từ server khi cập nhật phiên: ${e.message}');
      }
      throw Exception('Lỗi khi cập nhật phiên sự kiện.');
    }
  }

  Future<void> deleteEventSession(int? sessionId) async {
    if (sessionId == null) {
      throw Exception('Không thể xóa phiên sự kiện vì thiếu ID.');
    }
    print('Đang xóa phiên sự kiện trên Supabase, ID: $sessionId');

    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq(_idColumn, sessionId);

      print('Xóa phiên sự kiện trên Supabase thành công!');
    } catch (e, st) {
      print('Lỗi khi xóa phiên sự kiện trên Supabase: $e\n$st');
      if (e is PostgrestException) {
        throw Exception('Lỗi từ server khi xóa phiên: ${e.message}');
      }
      throw Exception('Lỗi khi xóa phiên sự kiện.');
    }
  }

  Future<EventSession?> getEventSessionById(int sessionId) async {
    print('Đang lấy phiên sự kiện theo ID từ Supabase, ID: $sessionId');
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq(_idColumn, sessionId)
          .maybeSingle();

      if (response != null) {
        final session = EventSession.fromJson(response as Map<String, dynamic>);
        print('Lấy phiên sự kiện theo ID thành công!');
        return session;
      } else {
        print('Không tìm thấy phiên sự kiện với ID: $sessionId');
        return null;
      }
    } catch (e, st) {
      print('Lỗi khi lấy phiên sự kiện theo ID: $e\n$st');
      if (e is PostgrestException) {
        throw Exception('Lỗi từ server khi tải phiên: ${e.message}');
      }
      throw Exception('Lỗi khi tải phiên sự kiện.');
    }
  }

  // Helper: convert DateTime fields to ISO strings if necessary.
  // Giữ nguyên các giá trị khác.
  Map<String, dynamic> _normalizeSessionPayload(Map<String, dynamic> raw) {
    final Map<String, dynamic> out = {};
    raw.forEach((key, value) {
      if (value is DateTime) {
        out[key] = value.toIso8601String();
      } else if (value is String) {
        // giữ nguyên
        out[key] = value;
      } else if (value == null) {
        // Supabase thường bỏ qua null, nhưng để rõ ràng ta vẫn gán null
        out[key] = null;
      } else {
        out[key] = value;
      }
    });
    return out;
  }
}