import 'package:flutter_test/flutter_test.dart';
import 'package:student_attendance/services/student_card_ocr_service.dart';

void main() {
  group('StudentCardOcrService.parseText', () {
    test('extracts labelled student information', () {
      final result = StudentCardOcrService.parseText('''
TRUONG DAI HOC HUTECH
HO VA TEN: Nguyen Van An
MSSV: 2180601234
''');

      expect(result.fullName, 'Nguyen Van An');
      expect(result.studentCode, '2180601234');
      expect(result.universityName, 'TRUONG DAI HOC HUTECH');
    });

    test('uses a code-shaped fallback when the label is absent', () {
      final result = StudentCardOcrService.parseText('''
HUTECH UNIVERSITY
Le Thi Binh
SV2026002
''');

      expect(result.studentCode, 'SV2026002');
      expect(result.fullName, 'Le Thi Binh');
    });

    test('recognizes Vietnamese labels and university names', () {
      final result = StudentCardOcrService.parseText('''
TRƯỜNG ĐẠI HỌC HUTECH
HỌ VÀ TÊN: Nguyễn Văn An
MSSV: 2180601234
''');

      expect(result.fullName, 'Nguyễn Văn An');
      expect(result.studentCode, '2180601234');
      expect(result.universityName, 'TRƯỜNG ĐẠI HỌC HUTECH');
    });

    test('extracts fields from an FPT card OCR response', () {
      final result = StudentCardOcrService.parseText('''
FPT Education
TRUONG DAI HOC FPT
Nguyen Dinh Thanh
SE182854
Valid: Dec 2026
STUDENT ID CARD
''');

      expect(result.fullName, 'Nguyen Dinh Thanh');
      expect(result.studentCode, 'SE182854');
      expect(result.universityName, 'TRUONG DAI HOC FPT');
    });
  });
}
