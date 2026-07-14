import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Extracts student-card text with OCR.space only.
class StudentCardOcrService {
  StudentCardOcrService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // The free OCR.space key is a client-side key for this student project.
  // A --dart-define value still overrides it when the key is rotated later.
  static const _apiKey = String.fromEnvironment(
    'OCR_SPACE_API_KEY',
    defaultValue: 'K81141945188957',
  );
  static const _requestTimeout = Duration(seconds: 35);
  static final _endpoint = Uri.parse('https://api.ocr.space/parse/image');

  final http.Client _httpClient;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<StudentCardOcrResult> extract(Uint8List imageBytes) async {
    if (!isConfigured) {
      throw const StudentCardOcrException(
        'Chưa cấu hình OCR_SPACE_API_KEY cho chức năng quét thẻ.',
      );
    }

    late http.Response response;
    try {
      response = await _httpClient.post(
        _endpoint,
        body: {
          'apikey': _apiKey,
          'base64Image': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
          'language': 'eng',
          'OCREngine': '2',
          'isOverlayRequired': 'false',
          'scale': 'true',
          'detectOrientation': 'true',
        },
      ).timeout(_requestTimeout);
    } on TimeoutException {
      throw const StudentCardOcrException(
        'OCR.space mất quá nhiều thời gian. Hãy thử lại với ảnh rõ hơn.',
      );
    } on http.ClientException {
      throw const StudentCardOcrException(
        'Không thể kết nối đến OCR.space. Hãy kiểm tra mạng và thử lại.',
      );
    }

    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StudentCardOcrException(
        _readError(body) ?? 'OCR.space không thể xử lý ảnh thẻ lúc này.',
      );
    }
    if (body['IsErroredOnProcessing'] == true) {
      throw StudentCardOcrException(
        _readError(body) ?? 'OCR.space không thể đọc nội dung trên thẻ.',
      );
    }

    final results = body['ParsedResults'];
    if (results is! List || results.isEmpty) {
      throw const StudentCardOcrException(
        'Không tìm thấy chữ trên thẻ. Hãy chụp lại ảnh sáng và không bị lóa.',
      );
    }
    final rawText = results
        .whereType<Map>()
        .map((result) => result['ParsedText']?.toString() ?? '')
        .where((text) => text.trim().isNotEmpty)
        .join('\n')
        .trim();
    if (rawText.isEmpty) {
      throw const StudentCardOcrException(
        'Không đọc được chữ trên thẻ. Hãy chụp lại ảnh rõ hơn.',
      );
    }
    return parseText(rawText);
  }

  static StudentCardOcrResult parseText(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_cleanLine)
        .where((line) => line.isNotEmpty)
        .toList();
    return StudentCardOcrResult(
      rawText: rawText.trim(),
      studentCode: _findStudentCode(rawText),
      fullName: _findFullName(lines),
      universityName: _findUniversity(lines),
    );
  }

  static Map<String, dynamic> _decodeBody(String body) {
    try {
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } on FormatException {
      return const {};
    }
  }

  static String? _readError(Map<String, dynamic> body) {
    final error = body['ErrorMessage'] ?? body['ErrorDetails'];
    if (error is List) {
      final text = error.whereType<Object>().join(' ').trim();
      return text.isEmpty ? null : text;
    }
    final text = error?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _findStudentCode(String text) {
    final labelled = RegExp(
      r'(?:MSSV|MS\s*SV|MA\s*SV|STUDENT\s*(?:ID|CODE)?|ID)\s*[:#\-]?\s*([A-Z0-9][A-Z0-9._\-]{4,})',
      caseSensitive: false,
    ).firstMatch(text);
    if (labelled != null) return labelled.group(1)?.toUpperCase();

    return RegExp(r'\b(?:[A-Z]{1,5}\d{5,12}|\d{7,12})\b')
        .firstMatch(text.toUpperCase())
        ?.group(0);
  }

  static String? _findFullName(List<String> lines) {
    for (final line in lines) {
      final match = RegExp(
        r'(?:HO\s*VA\s*TEN|HỌ\s*VÀ\s*TÊN|FULL\s*NAME|NAME)\s*[:\-]?\s*(.+)',
        caseSensitive: false,
      ).firstMatch(line);
      final value = match?.group(1)?.trim();
      if (value != null && _looksLikePersonName(value)) return value;
    }

    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('TRUONG') ||
          upper.contains('TRƯỜNG') ||
          upper.contains('UNIVERSITY') ||
          upper.contains('EDUCATION') ||
          upper.contains('FPT') ||
          upper.contains('STUDENT') ||
          upper.contains('VALID') ||
          (upper.contains('DAI') && upper.contains('HOC')) ||
          upper.contains('KHOA')) {
        continue;
      }
      if (_looksLikePersonName(line)) return line;
    }
    return null;
  }

  static String? _findUniversity(List<String> lines) {
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('FPT') && !upper.contains('EDUCATION')) {
        return line;
      }
      if (upper.contains('DAI HOC') ||
          upper.contains('ĐẠI HỌC') ||
          upper.contains('UNIVERSITY') ||
          upper.startsWith('TRUONG ') ||
          upper.startsWith('TRƯỜNG ')) {
        return line;
      }
    }
    return null;
  }

  static bool _looksLikePersonName(String value) {
    final words = value.split(RegExp(r'\s+'));
    if (words.length < 2 || words.length > 6) return false;
    if (value.contains(RegExp(r'\d'))) return false;
    return words.where((word) => word.length > 1).length >= 2;
  }

  static String _cleanLine(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class StudentCardOcrResult {
  const StudentCardOcrResult({
    required this.rawText,
    this.studentCode,
    this.fullName,
    this.universityName,
  });

  final String rawText;
  final String? studentCode;
  final String? fullName;
  final String? universityName;
}

class StudentCardOcrException implements Exception {
  const StudentCardOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}
