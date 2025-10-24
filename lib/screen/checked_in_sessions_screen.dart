import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/main_layout.dart';

class CheckedInSessionsScreen extends StatefulWidget {
  const CheckedInSessionsScreen({super.key});

  @override
  State<CheckedInSessionsScreen> createState() => _CheckedInSessionsScreenState();
}

class _CheckedInSessionsScreenState extends State<CheckedInSessionsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchCheckedInSessions();
  }

  Future<List<Map<String, dynamic>>> _fetchCheckedInSessions() async {
    final authId = Supabase.instance.client.auth.currentUser?.id;
    if (authId == null) throw Exception("Chưa đăng nhập");

    final appUser = await Supabase.instance.client
        .from('app_user')
        .select('user_id')
        .eq('auth_id', authId)
        .single();

    final student = await Supabase.instance.client
        .from('student')
        .select('student_id')
        .eq('user_id', appUser['user_id'])
        .single();

    final checkins = await Supabase.instance.client
        .from('session_checkin')
        .select('session_id, checkin_time')
        .eq('student_id', student['student_id']);

    if (checkins == null || checkins.isEmpty) return [];

    List<Map<String, dynamic>> result = [];
    for (var c in checkins) {
      final session = await Supabase.instance.client
          .from('event_session')
          .select('title, start_time, location')
          .eq('session_id', c['session_id'])
          .single();

      result.add({
        'title': session['title'],
        'start_time': session['start_time'],
        'location': session['location'],
        'checkin_time': c['checkin_time'],
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Thay vì Scaffold, ta dùng MainLayout bọc toàn bộ nội dung
    return MainLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thay cho AppBar gốc
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  "Các phiên đã điểm danh",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),

          // Giữ nguyên FutureBuilder cũ
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data!;
                if (sessions.isEmpty) {
                  return const Center(
                      child: Text('Bạn chưa điểm danh phiên nào.'));
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(s['title']),
                        subtitle: Text(
                          'Thời gian: ${s['start_time']} - Địa điểm: ${s['location']}\n'
                              'Điểm danh lúc: ${s['checkin_time']}',
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
