import 'package:flutter/material.dart';
import 'package:student_attendance/screen/student_event_session_list_screen.dart';
import '../services/student_service.dart';
import '../services/notification_service.dart';

class MyEventScreen extends StatefulWidget {
  final int userId;

  const MyEventScreen({super.key, required this.userId});

  @override
  State<MyEventScreen> createState() => _MyEventScreenState();
}

class _MyEventScreenState extends State<MyEventScreen> {
  final StudentService _service = StudentService();
  bool _loading = true;
  List<Map<String, dynamic>> _events = [];
  int? _studentId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      // Lấy studentId từ userId
      final studentRow = await _service.supabase
          .from('student')
          .select('student_id')
          .eq('user_id', widget.userId)
          .maybeSingle();
      _studentId = studentRow?['student_id'] as int?;
      final data = await _service.getMyEventsForAppUserId(widget.userId);
      setState(() {
        _events = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      NotificationService.showError(context, "Lỗi tải sự kiện: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sự kiện của tôi")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? const Center(
        child: Text(
          "Bạn chưa tham gia sự kiện nào.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final ev = _events[index];
          final event = ev['event'];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.blue),
              title: Text(event['title'] ?? 'No title'),
              subtitle: Text(
                "Bắt đầu: ${event['start_date'] ?? ''}\nKết thúc: ${event['end_date'] ?? ''}",
              ),
              trailing: Chip(
                label: Text(ev['status'] ?? 'N/A'),
                backgroundColor: Colors.green.shade100,
              ),
              onTap: () async {
                if (_studentId == null) {
                  NotificationService.showError(context, "Không tìm thấy mã sinh viên.");
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentEventSessionListScreen(
                      eventId: event['event_id'],
                      eventTitle: event['title'],
                      studentId: _studentId!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}