class StudentInEvent {
  final int? studentInEventId; // camelCase
  final int eventId;
  final int studentId;
  final String status;
  final int? rating;
  final String? feedback;
  final Student? student;
  final Map<String, dynamic>? event;

  StudentInEvent({
    this.studentInEventId,
    required this.eventId,
    required this.studentId,
    required this.status,
    this.rating,
    this.feedback,
    this.student,
    this.event,
  });

  factory StudentInEvent.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    final idVal = _parseInt(json['student_in_event_id'] ?? json['id']);
    final eventIdVal = _parseInt(json['event_id'] ?? json['event']?['event_id']);
    final studentIdVal = _parseInt(json['student_id'] ?? json['student']?['student_id']);

    if (eventIdVal == null || studentIdVal == null) {
      throw FormatException('Missing event_id or student_id in StudentInEvent JSON: $json');
    }

    return StudentInEvent(
      studentInEventId: idVal,
      eventId: eventIdVal,
      studentId: studentIdVal,
      status: (json['status'] ?? 'registered') as String,
      rating: json['rating'] as int?,
      feedback: json['feedback'] as String?,
      student: json['student'] != null
          ? Student.fromJson(Map<String, dynamic>.from(json['student']))
          : null,
      event: json['event'] != null ? Map<String, dynamic>.from(json['event']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_in_event_id': studentInEventId,
      'event_id': eventId,
      'student_id': studentId,
      'status': status,
      'rating': rating,
      'feedback': feedback,
    };
  }

  String get eventTitle => event?['title'] ?? 'Không có tên sự kiện';
}

class Student {
  final int studentId;
  final String name;
  final String email;
  final String studentCode;

  Student({
    required this.studentId,
    required this.name,
    required this.email,
    required this.studentCode,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Student(
      studentId: _parseInt(json['student_id'] ?? json['id']),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      studentCode: json['student_code'] ?? '',
    );
  }
}
