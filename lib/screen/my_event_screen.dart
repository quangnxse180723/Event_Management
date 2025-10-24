import 'package:flutter/material.dart';
import 'package:student_attendance/screen/student_event_session_list_screen.dart';
import '../widgets/main_layout.dart';
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

      if (mounted) {
        setState(() {
          _events = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        NotificationService.showError(context, "Lỗi tải sự kiện: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: true, // ✅ Cho phép cuộn trong layout gradient
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar tùy chỉnh (vì AppBar trong MainLayout trong suốt)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Sự kiện của tôi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Làm mới',
                  onPressed: () {
                    _loadEvents();
                    NotificationService.showInfo(
                        context, "Đã làm mới danh sách 🔄");
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Phần nội dung chính
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_events.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text(
                    "Bạn chưa tham gia sự kiện nào.",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                      title: Text(
                        event['title'] ?? 'Không có tiêu đề',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Bắt đầu: ${event['start_date'] ?? ''}\nKết thúc: ${event['end_date'] ?? ''}",
                      ),
                      trailing: Chip(
                        label: Text(ev['status'] ?? 'N/A'),
                        backgroundColor: (ev['status'] == 'Hoàn thành')
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                      ),
                      onTap: () async {
                        if (_studentId == null) {
                          NotificationService.showError(
                              context, "Không tìm thấy mã sinh viên.");
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
          ],
        ),
      ),
    );
  }
}
