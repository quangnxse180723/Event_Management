import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/main_layout.dart'; // MainLayout dùng gradient background
import '../services/notification_service.dart';

class StudentEventSessionListScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final int studentId;

  const StudentEventSessionListScreen({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentEventSessionListScreen> createState() =>
      _StudentEventSessionListScreenState();
}

class _StudentEventSessionListScreenState
    extends State<StudentEventSessionListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchSessions();
  }

  Future<List<Map<String, dynamic>>> _fetchSessions() async {
    final supabase = Supabase.instance.client;

    final data = await supabase
        .from('event_session')
        .select(
        'session_id, title, start_time, end_time, location, session_checkin(session_id, student_id)')
        .eq('event_id', widget.eventId);

    print("👉 Raw sessions: $data");

    return (data as List).map<Map<String, dynamic>>((s) {
      final session = Map<String, dynamic>.from(s);
      final checkins = session['session_checkin'] as List<dynamic>? ?? [];
      final checkedIn =
      checkins.any((c) => c['student_id'] == widget.studentId);

      // Schedule reminder if start time is in the future
      if (session['start_time'] != null) {
        try {
          final startTime = DateTime.parse(session['start_time']);
          final reminderTime = startTime.subtract(const Duration(minutes: 30));
          if (reminderTime.isAfter(DateTime.now())) {
            NotificationService.scheduleEventReminder(
              session['session_id'],
              'Nhắc nhở sự kiện: ${widget.eventTitle}',
              'Phiên "${session['title']}" sẽ bắt đầu lúc ${DateFormat('HH:mm').format(startTime)} tại ${session['location'] ?? "chưa rõ"}',
              reminderTime,
            );
          }
        } catch (e) {
          print('Error scheduling notification: $e');
        }
      }

      return {
        ...session,
        'checked_in': checkedIn,
      };
    }).toList();
  }

  String _formatDT(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return iso ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false,
      child: Column(
        children: [
          // Custom header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.eventTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List of sessions
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final sessions = snapshot.data!;
                if (sessions.isEmpty) {
                  return const Center(child: Text("Chưa có phiên nào."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          Icons.access_time,
                          color: s['checked_in'] ? Colors.green : Colors.grey,
                        ),
                        title: Text(s['title'] ?? 'Không có tiêu đề'),
                        subtitle: Text(
                          'Bắt đầu: ${_formatDT(s['start_time'])}\n'
                              'Kết thúc: ${_formatDT(s['end_time'])}\n'
                              'Địa điểm: ${s['location'] ?? ""}',
                        ),
                        trailing: s['checked_in']
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  "Đã điểm danh",
                                  style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.bold),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  "Chưa điểm danh",
                                  style: TextStyle(fontSize: 12, color: Colors.red[800], fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
