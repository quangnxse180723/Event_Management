import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/main_layout.dart';
import 'ManualCheckinScreen.dart';
import 'display_qr_screen.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  late final Stream<List<Map<String, dynamic>>> _sessionsStream;

  @override
  void initState() {
    super.initState();
    _sessionsStream = Supabase.instance.client
        .from('event_session')
        .stream(primaryKey: ['session_id'])
        .order('start_time', ascending: false);
  }

  void _showOptions(BuildContext context, Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
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
      floatingActionButton: null, // Bỏ nút refresh đi vì đã dùng Stream (Realtime)
      appBar: AppBar(
        title: const Text(
          "Chọn phiên để điểm danh",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Ẩn nút back
      ),

      // 🔹 Nội dung chính
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
                'Không có phiên nào được tìm thấy.',
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
                color: Colors.white.withOpacity(0.9),
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
