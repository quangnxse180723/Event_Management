import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventChatbotService {
  EventChatbotService({SupabaseClient? supabase, http.Client? httpClient})
      : _supabase = supabase ?? Supabase.instance.client,
        _httpClient = httpClient ?? http.Client();

  static const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );

  final SupabaseClient _supabase;
  final http.Client _httpClient;

  static const _requestTimeout = Duration(seconds: 25);

  bool get isConfigured => _geminiApiKey.isNotEmpty;

  Future<String> ask({
    required String question,
    required List<ChatTurn> history,
  }) async {
    if (!isConfigured) {
      return 'Chưa nạp GEMINI_API_KEY vào bản chạy hiện tại. Hãy dùng '
          '.\\scripts\\run_with_gemini.ps1 hoặc chạy flutter run '
          '--dart-define-from-file=.env.local, sau đó khởi động lại app.';
    }

    final dateAnswer = _answerCurrentDate(question);
    if (dateAnswer != null) return dateAnswer;

    String context;
    try {
      context = await _buildEventContext();
    } catch (_) {
      // Poki can still answer general questions if the event database is down.
      context = 'Dữ liệu sự kiện tạm thời không tải được.';
    }
    final prompt = _buildPrompt(
      question: question,
      history: history,
      eventContext: context,
    );

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_geminiModel:generateContent',
      {'key': _geminiApiKey},
    );

    late http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                }
              ],
              'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 700,
              },
            }),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const EventChatbotException(
        'Poki chưa nhận được phản hồi. Vui lòng thử lại sau ít phút.',
      );
    } on http.ClientException {
      throw const EventChatbotException(
        'Không thể kết nối đến dịch vụ AI. Hãy kiểm tra mạng và thử lại.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EventChatbotException(_messageForStatus(response.statusCode));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      return 'Mình chưa nhận được câu trả lời từ Gemini.';
    }

    final content = candidates.first['content'] as Map<String, dynamic>? ?? {};
    final parts = content['parts'] as List<dynamic>? ?? [];
    final text = parts
        .map((part) => (part as Map<String, dynamic>)['text'] as String? ?? '')
        .where((value) => value.trim().isNotEmpty)
        .join('\n')
        .trim();

    return text.isEmpty ? 'Mình chưa có câu trả lời phù hợp.' : text;
  }

  Future<String> _buildEventContext() async {
    final events = await _supabase.from('event').select('''
      event_id,
      title,
      description,
      organizer,
      start_date,
      end_date,
      event_session (
        title,
        start_time,
        end_time,
        location
      )
    ''').order('start_date', ascending: true).limit(20);

    if (events.isEmpty) {
      return 'Hiện chưa có dữ liệu sự kiện trong hệ thống.';
    }

    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (final rawEvent in events) {
      final event = Map<String, dynamic>.from(rawEvent);
      buffer.writeln('Su kien: ${event['title'] ?? 'Khong ten'}');
      buffer.writeln('- Mo ta: ${event['description'] ?? 'Chua co mo ta'}');
      buffer.writeln('- Don vi/to chuc: ${event['organizer'] ?? 'Chua ro'}');
      buffer.writeln(
          '- Bat dau: ${_formatDate(event['start_date'], dateFormat)}');
      buffer
          .writeln('- Ket thuc: ${_formatDate(event['end_date'], dateFormat)}');

      final sessions = event['event_session'];
      if (sessions is List && sessions.isNotEmpty) {
        buffer.writeln('- Cac phien:');
        for (final rawSession in sessions) {
          final session = Map<String, dynamic>.from(rawSession);
          buffer.writeln(
            '  + ${session['title'] ?? 'Khong ten'} | '
            '${_formatDate(session['start_time'], dateFormat)} - '
            '${_formatDate(session['end_time'], dateFormat)} | '
            'Dia diem: ${session['location'] ?? 'Chua ro'}',
          );
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _buildPrompt({
    required String question,
    required List<ChatTurn> history,
    required String eventContext,
  }) {
    final recentHistory = history.reversed
        .take(8)
        .toList()
        .reversed
        .map((turn) => '${turn.isUser ? 'Nguoi dung' : 'Tro ly'}: ${turn.text}')
        .join('\n');

    return '''
Ban la AI Tro ly ao Event Chatbot Assistant cho ung dung quan ly su kien.
Ten tro ly: Poki.
Tra loi ngan gon, ro rang bang tieng Viet.

Quy tac:
1. Khi cau hoi la thong tin CU THE ve su kien, lich, dia diem, phien, le phi, yeu cau tham gia hoac lien he, chi dung DU LIEU SU KIEN ben duoi. Neu du lieu khong co, noi "Minh chua thay thong tin nay trong du lieu su kien". Khong tu bia them.
2. Khi cau hoi la hoi thoai, kien thuc chung, meo hoc tap, meo chuan bi su kien, hoac cau hoi khac khong yeu cau du lieu su kien, duoc phep tra loi huu ich theo kien thuc chung.
3. Neu khong chac ve mot su kien cu the, phan biet ro "thong tin chung" voi "thong tin cua su kien".
4. Thoi gian hien tai cua ung dung: ${DateFormat('EEEE, dd/MM/yyyy HH:mm', 'vi').format(DateTime.now())}.

DU LIEU SU KIEN:
$eventContext

LICH SU GAN DAY:
$recentHistory

CAU HOI:
$question
''';
  }

  String _formatDate(dynamic value, DateFormat formatter) {
    if (value == null) return 'Chua ro';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return formatter.format(date.toLocal());
  }

  String? _answerCurrentDate(String question) {
    final normalized = question.toLowerCase();
    if (!RegExp(r'h.m nay').hasMatch(normalized) &&
        !normalized.contains('ngay bao nhieu')) {
      return null;
    }
    final formatted =
        DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now());
    return 'Hôm nay là $formatted.';
  }

  String _messageForStatus(int statusCode) {
    if (statusCode == 400 || statusCode == 403) {
      return 'Cấu hình Gemini chưa hợp lệ. Hãy kiểm tra API key và quyền truy cập model.';
    }
    if (statusCode == 429) {
      return 'Poki đang nhận quá nhiều yêu cầu. Vui lòng thử lại sau ít phút.';
    }
    return 'Dịch vụ AI đang tạm thời không phản hồi. Vui lòng thử lại sau.';
  }
}

class EventChatbotException implements Exception {
  const EventChatbotException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChatTurn {
  final String text;
  final bool isUser;

  const ChatTurn({
    required this.text,
    required this.isUser,
  });
}
