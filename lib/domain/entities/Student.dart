class Student {
  final int studentId;
  final String name;
  final String studentCode;
  final String phone;
  final int? universityId;
  final int? userId;
  final DateTime? createdAt;

  Student({
    required this.studentId,
    required this.name,
    required this.studentCode,
    required this.phone,
    this.universityId,
    this.userId,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'] is int
          ? json['student_id']
          : int.parse(json['student_id'].toString()),
      name: json['name'] ?? '',
      studentCode: json['student_code'] ?? '',
      phone: json['phone'] ?? '',
      universityId: json['university_id'] != null
          ? int.tryParse(json['university_id'].toString())
          : null,
      userId: json['user_id'] != null
          ? int.tryParse(json['user_id'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'student_code': studentCode,
      'phone': phone,
      'university_id': universityId,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
