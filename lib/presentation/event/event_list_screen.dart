import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_attendance/data/services/student_service.dart';
import 'package:student_attendance/data/services/notification_service.dart';
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';
import 'package:student_attendance/presentation/session/student_event_session_list_screen.dart';

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
  
  String _searchQuery = '';
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int? _studentId;

  @override
  void initState() {
    super.initState();
    _loadEvents(refresh: true);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
        _loadEvents(refresh: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _offset = 0;
        _hasMore = true;
        _events.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

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

      _studentId = studentRow['student_id'] as int;

      var query = _service.supabase
          .from('event')
          .select('''
            event_id,
            title,
            start_date,
            end_date,
            image_url,
            student_in_event(student_id)
          ''')
          .gte('end_date', now);

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$_searchQuery%');
      }

      final response = await query
          .order('start_date')
          .range(_offset, _offset + _limit - 1);

      final events = List<Map<String, dynamic>>.from(response);

      for (var ev in events) {
        final regs = ev['student_in_event'] as List? ?? [];
        ev['registered'] = regs.any((r) => r['student_id'] == _studentId);
      }

      setState(() {
        if (events.length < _limit) {
          _hasMore = false;
        }
        _events.addAll(events);
        _offset += events.length;
        _loading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, "Lỗi tải sự kiện: $e");
      setState(() {
        _loading = false;
        _isLoadingMore = false;
      });
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
      useScrollView: false,
      // ✅ Dùng AppBar thật, trong suốt
      appBar: AppBar(
        title: const Text("Danh sách sự kiện"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),

      // ✅ Nội dung chính
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm sự kiện...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchQuery = value.trim();
                _loadEvents(refresh: true);
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                ? const Center(child: Text("Không có sự kiện nào sắp diễn ra."))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _events.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _events.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final ev = _events[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () {
                if (_studentId == null) {
                  NotificationService.showError(context, "Không tìm thấy mã sinh viên.");
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentEventSessionListScreen(
                      eventId: ev['event_id'],
                      eventTitle: ev['title'],
                      studentId: _studentId!,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ev['image_url'] != null && ev['image_url'].toString().isNotEmpty)
                    Image.network(
                      ev['image_url'],
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_available, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev['title'] ?? 'Chưa có tiêu đề',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Từ: ${_formatDate(ev['start_date'])} - Đến: ${_formatDate(ev['end_date'])}",
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (ev['registered'] == true)
                          const Chip(
                            label: Text("Đã ĐK", style: TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: Colors.green,
                            visualDensity: VisualDensity.compact,
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _registerEvent(index, ev['event_id']),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: const Size(0, 36),
                            ),
                            child: const Text("Đăng ký"),
                          ),
                      ],
                    ),
                  ),
                ],
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
