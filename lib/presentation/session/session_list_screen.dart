import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';
import 'package:student_attendance/presentation/session/manual_check_in_screen.dart';
import 'package:student_attendance/presentation/session/display_qr_screen.dart';

// --- Màn hình 1: Danh sách Sự kiện để Điểm danh ---
class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  late final Stream<List<Map<String, dynamic>>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = Supabase.instance.client
        .from('event')
        .stream(primaryKey: ['event_id'])
        .order('start_date', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false,
      floatingActionButton: null,
      appBar: AppBar(
        title: const Text(
          "Chọn sự kiện để điểm danh",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Ẩn nút back vì đây là tab
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Không có sự kiện nào.', style: TextStyle(color: Colors.white)),
            );
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(
                    event['title'] ?? 'Không có tiêu đề',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text('Tổ chức bởi: ${event['organizer'] ?? 'Chưa rõ'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckinSessionListScreen(
                          eventId: event['event_id'],
                          eventTitle: event['title'] ?? 'Phiên điểm danh',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- Màn hình 2: Danh sách Phiên của 1 Sự kiện cụ thể ---
class CheckinSessionListScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const CheckinSessionListScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<CheckinSessionListScreen> createState() => _CheckinSessionListScreenState();
}

class _CheckinSessionListScreenState extends State<CheckinSessionListScreen> {
  late final Stream<List<Map<String, dynamic>>> _sessionsStream;

  @override
  void initState() {
    super.initState();
    _sessionsStream = Supabase.instance.client
        .from('event_session')
        .stream(primaryKey: ['session_id'])
        .eq('event_id', widget.eventId) // Lọc theo sự kiện
        .order('start_time', ascending: false);
  }

  void _showOptions(BuildContext context, Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.qr_code_2_rounded, color: Colors.blue),
                title: const Text('Hiển thị mã QR'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplayQRScreen(
                        sessionId: session['session_id'],
                        sessionTitle: session['title'] ?? 'Không có tiêu đề',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: Colors.orange),
                title: const Text('Điểm danh thủ công'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualCheckinScreen(
                        sessionId: session['session_id'],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false,
      floatingActionButton: null,
      appBar: AppBar(
        title: Text(
          widget.eventTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _sessionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có phiên nào cho sự kiện này.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final sessions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.blue,
                  ),
                  title: Text(
                    session['title'] ?? 'Không có tiêu đề',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Địa điểm: ${session['location'] ?? 'Chưa xác định'}',
                  ),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () => _showOptions(context, session),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
