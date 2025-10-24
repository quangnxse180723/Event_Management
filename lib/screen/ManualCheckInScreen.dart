import 'package:flutter/material.dart';
import '../services/SessionCheckInService.dart';
import '../services/notification_service.dart';
import '../widgets/main_layout.dart'; // ✅ Layout có gradient + sóng

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
    setState(() {
      _attendanceListFuture =
          _checkinService.getCheckinStatusForSession(widget.sessionId);
    });
  }

  Future<void> _manualCheckin(int studentId) async {
    final success = await _checkinService.createCheckin(
      sessionId: widget.sessionId,
      studentId: studentId,
      method: 'manual',
    );

    if (!mounted) return;

    if (success) {
      NotificationService.showSuccess(context, '✅ Điểm danh thành công!');
      _loadAttendanceList();
    } else {
      NotificationService.showError(
        context,
        'Sinh viên đã được điểm danh hoặc có lỗi xảy ra.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false, // ✅ tránh lỗi infinite scroll
      child: Scaffold(
        backgroundColor: Colors.transparent, // ✅ để thấy gradient và sóng
        appBar: AppBar(
          title: Text('Điểm danh thủ công - Phiên ${widget.sessionId}'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới danh sách',
              onPressed: () {
                _loadAttendanceList();
                NotificationService.showInfo(context, 'Đã làm mới danh sách 🔄');
              },
            ),
          ],
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _attendanceListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadAttendanceList,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final students = snapshot.data ?? [];
            if (students.isEmpty) {
              return const Center(
                child: Text('Không có sinh viên nào đăng ký sự kiện này.'),
              );
            }

            // Phân loại danh sách
            final checkedIn = students
                .where((s) =>
            s['checkin_status']?.toString().trim() == 'Đã Check-in')
                .toList();
            final notCheckedIn = students
                .where((s) =>
            s['checkin_status']?.toString().trim() == 'Chưa Check-in')
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader(
                  'Đã Check-in (${checkedIn.length})',
                  Colors.green,
                ),
                if (checkedIn.isEmpty)
                  const Text('— Không có sinh viên nào —',
                      style: TextStyle(color: Colors.grey)),
                ...checkedIn.map((s) => _buildStudentTile(s, true)),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Chưa Check-in (${notCheckedIn.length})',
                  Colors.orange,
                ),
                if (notCheckedIn.isEmpty)
                  const Text('— Tất cả đã điểm danh —',
                      style: TextStyle(color: Colors.grey)),
                ...notCheckedIn.map((s) => _buildStudentTile(s, false)),
              ],
            );
          },
        ),
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
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          student['student_name'] ?? 'Không có tên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('MSSV: ${student['student_code'] ?? 'N/A'}'),
        trailing: isCheckedIn
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
            : ElevatedButton.icon(
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Check-in'),
          onPressed:
          studentId != null ? () => _manualCheckin(studentId) : null,
        ),
      ),
    );
  }
}
