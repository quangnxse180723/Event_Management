import 'package:flutter/material.dart';
import '../services/SessionCheckInService.dart';
import '../services/notification_service.dart';

class ManualCheckinScreen extends StatefulWidget {
  final int sessionId;

  const ManualCheckinScreen({Key? key, required this.sessionId})
    : super(key: key);

  @override
  State<ManualCheckinScreen> createState() => _ManualCheckinScreenState();
}

class _ManualCheckinScreenState extends State<ManualCheckinScreen> {
  final SessionCheckInService _checkinService = SessionCheckInService();
  late Future<List<Map<String, dynamic>>> _attendanceListFuture;

  @override
  void initState() {
    super.initState();
    _loadAttendanceList();
  }

  void _loadAttendanceList() {
    _attendanceListFuture = _checkinService.getCheckinStatusForSession(
      widget.sessionId,
    );
  }

  Future<void> _manualCheckin(int studentId) async {
    final success = await _checkinService.createCheckin(
      sessionId: widget.sessionId,
      studentId: studentId,
      method: 'manual',
    );

    if (mounted) {
      if (success) {
        NotificationService.showSuccess(context, '✅ Điểm danh thành công!');
      } else {
        NotificationService.showError(context, 'Sinh viên đã được điểm danh hoặc có lỗi xảy ra.');
      }

      // Always refresh the list to show current status
      setState(() {
        _attendanceListFuture = _checkinService.getCheckinStatusForSession(
          widget.sessionId,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm danh thủ công - Phiên ${widget.sessionId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadAttendanceList();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _attendanceListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Không có sinh viên nào đăng ký sự kiện này.'),
            );
          }

          final students = snapshot.data!;
          for (var student in students) {
            print(
              'Student: ${student['student_name']}, Status: "${student['checkin_status']}"',
            );
          }
          final checkedInStudents = students
              .where(
                (s) => s['checkin_status']?.toString().trim() == 'Đã Check-in',
              )
              .toList();
          final notCheckedInStudents = students
              .where(
                (s) =>
                    s['checkin_status']?.toString().trim() == 'Chưa Check-in',
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              _buildSectionHeader(
                'Đã Check-in (${checkedInStudents.length})',
                Colors.green,
              ),
              ...checkedInStudents.map(
                (student) => _buildStudentTile(student, true),
              ),
              const SizedBox(height: 20),
              _buildSectionHeader(
                'Chưa Check-in (${notCheckedInStudents.length})',
                Colors.orange,
              ),
              ...notCheckedInStudents.map(
                (student) => _buildStudentTile(student, false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student, bool isCheckedIn) {
    final studentId = int.tryParse(student['student_id'].toString());

    return Card(
      child: ListTile(
        title: Text(student['student_name'] ?? 'Không có tên'),
        subtitle: Text('MSSV: ${student['student_code'] ?? 'N/A'}'),
        trailing: isCheckedIn
            ? Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                onPressed: studentId != null
                    ? () => _manualCheckin(studentId)
                    : null,
                child: const Text('Check-in'),
              ),
      ),
    );
  }
}
