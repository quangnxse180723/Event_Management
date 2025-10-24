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
  late final Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _fetchSessions();
  }

  Future<List<Map<String, dynamic>>> _fetchSessions() async {
    try {
      final response = await Supabase.instance.client
          .from('event_session')
          .select('session_id, title, start_time, location')
          .order('start_time', ascending: false);
      return response;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách phiên: $e')),
      );
      rethrow;
    }
  }

  void _showOptions(BuildContext context, Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.qr_code_2_rounded),
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
              leading: const Icon(Icons.edit_note_rounded),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false,
      // 🔹 AppBar custom: có nút back và tiêu đề
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Thanh tiêu đề + back
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Chọn phiên để điểm danh",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Nội dung chính
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled_rounded),
                        title: Text(
                          session['title'] ?? 'Không có tiêu đề',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Địa điểm: ${session['location'] ?? 'Chưa xác định'}'),
                        trailing: const Icon(Icons.more_vert),
                        onTap: () => _showOptions(context, session),
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
