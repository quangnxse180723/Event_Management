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
        .select('session_id, created_at')
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
        'checkin_time': c['created_at'],
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: AppBar(
        title: const Text("Các phiên đã điểm danh"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      useScrollView: false, // Giúp ListView hoạt động tốt
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}'),
            );
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(
              child: Text('Bạn chưa điểm danh phiên nào.'),
            );
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final s = sessions[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    s['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    );
  }
}
