import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/student_service.dart';
import '../services/notification_service.dart';
import '../widgets/main_layout.dart';

class EventListScreen extends StatefulWidget {
  final int userId;

  const EventListScreen({super.key, required this.userId});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final StudentService _service = StudentService();
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final now = DateTime.now().toIso8601String();
      final studentRow = await _service.supabase
          .from('student')
          .select('student_id')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (studentRow == null) {
        if (!mounted) return;
        NotificationService.showError(context, "Không tìm thấy thông tin sinh viên!");
        setState(() => _loading = false);
        return;
      }

      final studentId = studentRow['student_id'] as int;

      final response = await _service.supabase
          .from('event')
          .select('''
            event_id,
            title,
            start_date,
            end_date,
            student_in_event(student_id)
          ''')
          .gte('end_date', now)
          .order('start_date');

      final events = List<Map<String, dynamic>>.from(response);

      for (var ev in events) {
        final regs = ev['student_in_event'] as List? ?? [];
        ev['registered'] = regs.any((r) => r['student_id'] == studentId);
      }

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, "Lỗi tải sự kiện: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _registerEvent(int index, int eventId) async {
    try {
      final studentRow = await _service.supabase
          .from('student')
          .select('student_id')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (studentRow == null) {
        NotificationService.showError(context, "Không tìm thấy sinh viên!");
        return;
      }

      final studentId = studentRow['student_id'] as int;

      final existing = await _service.supabase
          .from('student_in_event')
          .select()
          .eq('student_id', studentId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (existing != null) {
        NotificationService.showWarning(context, "Bạn đã đăng ký sự kiện này rồi!");
        return;
      }

      await _service.registerEvent(studentId, eventId);

      setState(() {
        _events[index]['registered'] = true;
      });

      final eventTitle = _events[index]['title'] ?? 'sự kiện';
      NotificationService.showSuccess(context, "🎉 Đăng ký sự kiện '$eventTitle' thành công!");
    } catch (e) {
      NotificationService.showError(context, "Lỗi đăng ký sự kiện: $e");
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false, // ⚡ vì bên trong có ListView
      child: Column(
        children: [
          // 🔹 AppBar giả lập (vì MainLayout đã có Scaffold)
          Container(
            height: kToolbarHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green.shade400.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Danh sách sự kiện",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                ? const Center(child: Text("Không có sự kiện nào sắp diễn ra."))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final ev = _events[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.event_available, color: Colors.blueAccent),
                    title: Text(ev['title'] ?? 'Chưa có tiêu đề'),
                    subtitle: Text(
                      "Từ: ${_formatDate(ev['start_date'])} - Đến: ${_formatDate(ev['end_date'])}",
                    ),
                    trailing: ev['registered'] == true
                        ? const Chip(
                      label: Text("Đã ĐK", style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.green,
                    )
                        : ElevatedButton(
                      onPressed: () => _registerEvent(index, ev['event_id']),
                      child: const Text("Đăng ký"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
