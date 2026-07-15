class SessionCheckIn {
  final int checkinId;
  final int sessionId;
  final int studentId;
  final int? userId;
  final DateTime? checkinTime;
  final String method;

  SessionCheckIn({
    required this.checkinId,
    required this.sessionId,
    required this.studentId,
    required this.userId,
    required this.checkinTime,
    required this.method,
  });

  factory SessionCheckIn.fromJson(Map<String, dynamic> json) {
    return SessionCheckIn(
      checkinId: json['checkin_id'],
      sessionId: json['session_id'],
      studentId: json['student_id'],
      userId: json['user_id'],
      checkinTime: json['checkin_time'] != null
          ? DateTime.tryParse(json['checkin_time'])
          : null,
      method: json['method'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkin_id': checkinId,
      'session_id': sessionId,
      'student_id': studentId,
      'user_id': userId,
      'checkin_time': checkinTime?.toIso8601String(),
      'method': method,
    };
  }
}