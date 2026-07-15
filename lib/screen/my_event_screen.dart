import 'package:flutter/material.dart';
import 'package:student_attendance/screen/student_event_session_list_screen.dart';
import '../widgets/main_layout.dart';
import '../services/student_service.dart';
import '../services/student_in_event_service.dart';
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
  Set<int> _attendedEventIds = {};

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

      if (_studentId != null) {
        final checkinsResponse = await _service.supabase
            .from('session_checkin')
            .select('event_session(event_id)')
            .eq('student_id', _studentId!);
        final checkins = List<Map<String, dynamic>>.from(checkinsResponse ?? []);
        _attendedEventIds = checkins
            .map((c) => c['event_session']?['event_id'])
            .where((id) => id != null)
            .cast<int>()
            .toSet();
      }

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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      // Chuyển chuỗi ISO (vd: 2025-10-31T00:00:00) sang DateTime
      final date = DateTime.parse(dateStr);
      // Hiển thị chỉ ngày/tháng/năm (bỏ giờ)
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateStr; // fallback nếu parse lỗi
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
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Sự kiện của tôi",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
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
                    style: TextStyle(fontSize: 16),
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

                  // ✅ Xử lý trạng thái tiếng Việt
                  String trangThai = (ev['status'] ?? '').toString().toLowerCase();
                  
                  // Logic cập nhật trạng thái dựa vào điểm danh thực tế
                  int eventId = event['event_id'];
                  if (trangThai == 'attended' && !_attendedEventIds.contains(eventId)) {
                    // Nếu DB là attended nhưng chưa điểm danh phiên nào
                    trangThai = 'registered';
                  } else if (_attendedEventIds.contains(eventId) && trangThai != 'completed') {
                    // Nếu đã điểm danh ít nhất 1 phiên thì là attended
                    trangThai = 'attended';
                  }

                  switch (trangThai) {
                    case 'registered':
                      trangThai = 'Đã đăng ký';
                      break;
                    case 'attended':
                      trangThai = 'Đã tham gia';
                      break;
                    case 'completed':
                      trangThai = 'Hoàn thành';
                      break;
                    case 'absent':
                      trangThai = 'Vắng mặt';
                      break;
                    case 'pending':
                      trangThai = 'Đang chờ xác nhận';
                      break;
                    default:
                      trangThai = 'Không xác định';
                  }

                  // ✅ Màu nền chip
                  Color chipColor;
                  if (trangThai == 'Đã tham gia' || trangThai == 'Hoàn thành') {
                    chipColor = Colors.green.shade100;
                  } else if (trangThai == 'Đã đăng ký' ||
                      trangThai == 'Đang chờ xác nhận') {
                    chipColor = Colors.orange.shade100;
                  } else if (trangThai == 'Vắng mặt') {
                    chipColor = Colors.red.shade100;
                  } else {
                    chipColor = Colors.grey.shade200;
                  }

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
                        "Bắt đầu: ${_formatDate(event['start_date'])}   •   Kết thúc: ${_formatDate(event['end_date'])}",
                        style: const TextStyle(height: 1.5),
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(
                              trangThai,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: chipColor,
                            padding: EdgeInsets.zero,
                          ),
                          if (trangThai == 'Đã tham gia' || trangThai == 'Hoàn thành')
                            InkWell(
                              onTap: () => _showRatingDialog(context, ev),
                              child: const Text('Đánh giá', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12)),
                            )
                        ],
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

  void _showRatingDialog(BuildContext context, Map<String, dynamic> ev) {
    int rating = ev['rating'] ?? 5;
    String feedback = ev['feedback'] ?? '';
    final studentInEventId = ev['student_in_event_id'];

    if (studentInEventId == null) {
      NotificationService.showError(context, "Không thể đánh giá sự kiện này");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Đánh giá sự kiện'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ý kiến phản hồi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) => feedback = val,
                    controller: TextEditingController(text: feedback),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await StudentInEventService().submitRating(studentInEventId, rating, feedback);
                      if (context.mounted) {
                        NotificationService.showSuccess(context, 'Cảm ơn bạn đã đánh giá!');
                        _loadEvents(); // Reload to get updated rating
                      }
                    } catch (e) {
                      if (context.mounted) {
                        NotificationService.showError(context, e.toString());
                      }
                    }
                  },
                  child: const Text('Gửi'),
                )
              ],
            );
          }
        );
      }
    );
  }
}
