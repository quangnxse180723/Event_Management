import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_attendance/data/services/api_service.dart';
import 'package:student_attendance/core/theme/app_theme.dart';
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    try {
      final rawData = await _apiService.fetchRealAttendanceForLeaderboard();
      
      // Group by student
      Map<int, Map<String, dynamic>> studentStats = {};
      
      for (var record in rawData) {
        final student = record['student'];
        final eventSession = record['event_session'];
        if (student == null || eventSession == null) continue;
        
        final event = eventSession['event'];
        if (event == null) continue;

        int studentId = student['student_id'];
        if (!studentStats.containsKey(studentId)) {
          studentStats[studentId] = {
            'student_id': studentId,
            'name': student['name'] ?? 'Không rõ',
            'student_code': student['student_code'] ?? '',
            'university': student['university']?['name'] ?? 'Không rõ',
            'event_count': 0,
            'events': <Map<String, dynamic>>[],
            'attended_event_ids': <int>{},
          };
        }
        
        int eventId = event['event_id'];
        if (!studentStats[studentId]!['attended_event_ids'].contains(eventId)) {
           studentStats[studentId]!['attended_event_ids'].add(eventId);
           studentStats[studentId]!['event_count'] = (studentStats[studentId]!['event_count'] as int) + 1;
           (studentStats[studentId]!['events'] as List).add(event);
        }
      }

      final sortedList = studentStats.values.toList()
        ..sort((a, b) => (b['event_count'] as int).compareTo(a['event_count'] as int));

      if (mounted) {
        setState(() {
          _leaderboard = sortedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải bảng xếp hạng: $e')),
        );
      }
    }
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> studentData) {
    final events = studentData['events'] as List;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        studentData['name'].toString().isNotEmpty ? studentData['name'].toString()[0] : '?',
                        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentData['name'],
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MSSV: ${studentData['student_code']}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            studentData['university'],
                            style: TextStyle(color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Đã tham gia ${studentData['event_count']} sự kiện',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final dateStr = event['start_date'] ?? '';
                    String displayDate = '';
                    if (dateStr.isNotEmpty) {
                      try {
                        final dt = DateTime.parse(dateStr).toLocal();
                        displayDate = DateFormat('dd/MM/yyyy HH:mm').format(dt);
                      } catch (_) {
                        displayDate = dateStr;
                      }
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event, color: Colors.blue),
                      ),
                      title: Text(
                        event['title'] ?? 'Sự kiện không tên',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(displayDate),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(int rank) {
    if (rank == 1) {
      return const Icon(Icons.workspace_premium, color: Colors.amber, size: 40);
    } else if (rank == 2) {
      return Icon(Icons.workspace_premium, color: Colors.grey.shade400, size: 40);
    } else if (rank == 3) {
      return Icon(Icons.workspace_premium, color: Colors.orange.shade700, size: 40);
    } else {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(
          '$rank',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false,
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Stack(
        children: [
          if (!_isLoading && _leaderboard.isEmpty)
            const Center(child: Text('Chưa có dữ liệu.'))
          else if (!_isLoading)
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final student = _leaderboard[index];
                final rank = index + 1;
                
                return Card(
                  elevation: rank <= 3 ? 4 : 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: rank == 1 
                      ? const BorderSide(color: Colors.amber, width: 2)
                      : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: _buildBadge(rank),
                    title: Text(
                      student['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: rank <= 3 ? 18 : 16,
                      ),
                    ),
                    subtitle: Text('${student['student_code']} • ${student['university']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${student['event_count']}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => _showStudentDetails(context, student),
                  ),
                );
              },
            ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
