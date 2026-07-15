class Student {
  final int studentId; // required
  final String name;
  final String studentCode;
  final String phone;
  final int? universityId;
  final int? userId;
  final DateTime? createdAt;
  final String? major; // Ngành học

  Student({
    required this.studentId,
    required this.name,
    required this.studentCode,
    required this.phone,
    this.universityId,
    this.userId,
    this.createdAt,
    this.major,
  });

  /// Factory để tạo Student trước khi insert DB
  /// studentId sẽ dùng placeholder 0, DB sẽ cấp actual ID
  factory Student.createForInsert({
    required String name,
    required String studentCode,
    required String phone,
    int? universityId,
    int? userId,
    DateTime? createdAt,
  }) {
    return Student(
      studentId: 0, // placeholder
      name: name,
      studentCode: studentCode,
      phone: phone,
      universityId: universityId,
      userId: userId,
      createdAt: createdAt,
    );
  }

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
      major: json['major'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'student_code': studentCode,
      'phone': phone,
      'university_id': universityId,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      if (major != null) 'major': major,
    };

    // Chỉ đưa student_id nếu không phải placeholder
    if (studentId != 0) {
      map['student_id'] = studentId;
    }

    return map;
  }
}
