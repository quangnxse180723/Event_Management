import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/data/models/event_model.dart';

/// Mô hình chứa sự kiện được gợi ý kèm điểm và lý do
class RecommendedEvent {
  final Event event;
  final double score; // 0.0 → 1.0
  final String reason; // Lý do gợi ý

  const RecommendedEvent({
    required this.event,
    required this.score,
    required this.reason,
  });
}

/// Hệ thống gợi ý sự kiện sử dụng Hybrid Recommendation:
/// 1. Collaborative Filtering (40%) — sinh viên cùng trường đã đăng ký gì
/// 2. Content-Based Filtering (40%) — sự kiện tương tự đã rate cao
/// 3. Category Match (20%) — ngành học khớp với danh mục sự kiện
class EventRecommendationService {
  final SupabaseClient _supabase;

  EventRecommendationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Lấy top [limit] sự kiện gợi ý cho sinh viên [studentId]
  Future<List<RecommendedEvent>> getRecommendations({
    required int studentId,
    required int userId,
    int limit = 6,
  }) async {
    try {
      // --- 1. Lấy thông tin sinh viên hiện tại ---
      final studentRow = await _supabase
          .from('student')
          .select('student_id, university_id, major')
          .eq('student_id', studentId)
          .maybeSingle();

      if (studentRow == null) return [];

      final int? universityId = studentRow['university_id'] as int?;
      final String? major = studentRow['major'] as String?;

      // --- 2. Lấy sự kiện sinh viên đã đăng ký ---
      final myRegistrations = await _supabase
          .from('student_in_event')
          .select('event_id, rating')
          .eq('student_id', studentId);

      final Set<int> myEventIds = (myRegistrations as List)
          .map((r) => r['event_id'] as int)
          .toSet();

      // Sự kiện được đánh giá cao (≥4 sao)
      final List<int> highRatedEventIds = (myRegistrations)
          .where((r) => (r['rating'] ?? 0) >= 4)
          .map<int>((r) => r['event_id'] as int)
          .toList();

      // --- 3. Lấy tất cả sự kiện chưa đăng ký, chưa kết thúc ---
      final allEventsRaw = await _supabase
          .from('event')
          .select()
          .gt('end_date', DateTime.now().toIso8601String())
          .order('start_date', ascending: true);

      final List<Event> candidateEvents = (allEventsRaw as List)
          .map((json) => Event.fromJson(json))
          .where((e) => e.id != null && !myEventIds.contains(e.id))
          .toList();

      if (candidateEvents.isEmpty) return [];

      // --- 4. Collaborative Filtering: tần suất đăng ký bởi sinh viên cùng trường ---
      Map<int, int> collaborativeCount = {};
      if (universityId != null) {
        // Lấy student_id của tất cả sinh viên cùng trường
        final peersRaw = await _supabase
            .from('student')
            .select('student_id')
            .eq('university_id', universityId)
            .neq('student_id', studentId);

        final List<int> peerIds = (peersRaw as List)
            .map<int>((r) => r['student_id'] as int)
            .toList();

        if (peerIds.isNotEmpty) {
          final peerRegistrations = await _supabase
              .from('student_in_event')
              .select('event_id')
              .inFilter('student_id', peerIds);

          for (final reg in (peerRegistrations as List)) {
            final eid = reg['event_id'] as int;
            if (!myEventIds.contains(eid)) {
              collaborativeCount[eid] = (collaborativeCount[eid] ?? 0) + 1;
            }
          }
        }
      }

      // Tìm max để normalize
      final int maxCollab = collaborativeCount.values.isEmpty
          ? 1
          : collaborativeCount.values.reduce((a, b) => a > b ? a : b);

      // --- 5. Content-Based Filtering: TF-IDF đơn giản (token overlap) ---
      // Tập hợp các từ khóa từ sự kiện được đánh giá cao
      Set<String> highRatedTokens = {};
      if (highRatedEventIds.isNotEmpty) {
        final highRatedRaw = await _supabase
            .from('event')
            .select('title, description, category')
            .inFilter('event_id', highRatedEventIds);

        for (final e in (highRatedRaw as List)) {
          highRatedTokens.addAll(_tokenize(e['title'] ?? ''));
          highRatedTokens.addAll(_tokenize(e['description'] ?? ''));
          if (e['category'] != null) {
            highRatedTokens.addAll(_tokenize(e['category']));
          }
        }
      }

      // --- 6. Tính điểm cho từng sự kiện ứng viên ---
      List<RecommendedEvent> scored = [];

      for (final event in candidateEvents) {
        if (event.id == null) continue;

        // A. Collaborative Score (40%)
        final int collabCount = collaborativeCount[event.id] ?? 0;
        final double collabScore =
            maxCollab > 0 ? (collabCount / maxCollab) * 0.4 : 0.0;

        // B. Content-Based Score (40%)
        double contentScore = 0.0;
        if (highRatedTokens.isNotEmpty) {
          final eventTokens = <String>{
            ..._tokenize(event.title),
            ..._tokenize(event.description),
            if (event.category != null) ..._tokenize(event.category!),
          };
          final int overlap = eventTokens
              .intersection(highRatedTokens)
              .length;
          final int union = eventTokens.union(highRatedTokens).length;
          // Jaccard similarity
          contentScore = union > 0 ? (overlap / union) * 0.4 : 0.0;
        }

        // C. Category Match Score (20%)
        double categoryScore = 0.0;
        if (major != null && major.isNotEmpty && event.category != null) {
          final majorTokens = _tokenize(major);
          final catTokens = _tokenize(event.category!);
          final overlap = majorTokens.intersection(catTokens).length;
          if (overlap > 0) categoryScore = 0.2;
        }
        // Nếu không có major nhưng sự kiện phổ biến, vẫn cho điểm nhỏ
        if (categoryScore == 0 && collabCount > 0) categoryScore = 0.05;

        final double totalScore = collabScore + contentScore + categoryScore;

        // Xác định lý do gợi ý
        String reason = _buildReason(
          collabScore: collabScore,
          contentScore: contentScore,
          categoryScore: categoryScore,
          collabCount: collabCount,
          major: major,
          category: event.category,
        );

        scored.add(RecommendedEvent(
          event: event,
          score: totalScore,
          reason: reason,
        ));
      }

      // Sắp xếp giảm dần theo điểm
      scored.sort((a, b) => b.score.compareTo(a.score));

      // Trả về top [limit]
      return scored.take(limit).toList();
    } catch (e, stackTrace) {
      print('❌ [EventRecommendationService] Lỗi khi tạo gợi ý: $e');
      print('❌ StackTrace: $stackTrace');
      // Nếu lỗi, trả về danh sách rỗng để không crash UI
      return [];
    }
  }

  /// Tách văn bản thành tập hợp các từ khóa (loại bỏ từ ngắn và stop words)
  Set<String> _tokenize(String text) {
    const stopWords = {
      'và', 'của', 'cho', 'trong', 'với', 'về', 'là', 'các', 'có',
      'được', 'này', 'đến', 'từ', 'theo', 'tại', 'khi', 'để', 'bởi',
      'the', 'a', 'an', 'in', 'of', 'for', 'and', 'or', 'to', 'is',
      'on', 'at', 'by', 'with', 'from', 'as',
    };
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet();
  }

  /// Xây dựng lý do gợi ý dễ hiểu
  String _buildReason({
    required double collabScore,
    required double contentScore,
    required double categoryScore,
    required int collabCount,
    String? major,
    String? category,
  }) {
    if (categoryScore >= 0.2 && major != null) {
      return '📚 Phù hợp với ngành $major';
    }
    if (contentScore > collabScore && contentScore > 0.05) {
      return '⭐ Tương tự sự kiện bạn yêu thích';
    }
    if (collabCount > 0) {
      return '🔥 $collabCount bạn cùng trường đã đăng ký';
    }
    return '✨ Sự kiện mới dành cho bạn';
  }
}
