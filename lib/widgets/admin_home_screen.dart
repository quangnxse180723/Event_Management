import 'package:flutter/material.dart';
import 'package:student_attendance/screen/event_management_screen.dart';
import '../screen/reporting_screen.dart';
import '../screen/student_in_event_screen.dart';
import '../screen/student_management_screen.dart';
import 'main_layout.dart';
import 'package:student_attendance/screen/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screen/SessionListScreen.dart';
import '../screen/event_chatbot_screen.dart';

// ------------------------------
// MÀN HÌNH CHÍNH DÀNH CHO ADMIN
// ------------------------------
class AdminHomeScreen extends StatefulWidget {
  final String role;
  final int userId;

  const AdminHomeScreen({super.key, required this.role, required this.userId});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final List<String> _pageTitles = const [
    'Xin chào, Admin',
    'Điểm danh',
    'Cài đặt',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      // Trang 0: Nội dung chính
      _AdminHomeContent(role: widget.role, userId: widget.userId),
      // Trang 1: Điểm danh (dùng SessionListScreen như logic cũ)
      const SessionListScreen(),
      const EventChatbotScreen(),
      // Trang 2: Cài đặt
      const SettingsScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      // Các trang con đã tự quản lý việc cuộn, nên set ở đây là false
      useScrollView: false,
      appBar: null,
      // Dùng widget BottomNavigationBar tiêu chuẩn
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        // Đổi màu nền cố định thành màu nền của Theme
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Điểm danh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'Tro ly',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
      // IndexedStack giúp giữ trạng thái của các trang khi chuyển qua lại
      child: IndexedStack(index: _currentIndex, children: _pages),
    );
  }
}

// ----------------------------------------------------
// NỘI DUNG TRANG CHỦ (_AdminHomeContent) - GIỮ NGUYÊN
// Phần này đã đúng và sẽ hoạt động tốt trong cấu trúc mới
// ----------------------------------------------------
class _AdminHomeContent extends StatefulWidget {
  final String role;
  final int userId;

  const _AdminHomeContent({required this.role, required this.userId});

  @override
  State<_AdminHomeContent> createState() => _AdminHomeContentState();
}

class _AdminHomeContentState extends State<_AdminHomeContent> {
  bool _isLoading = true;
  int _eventCount = 0;
  int _studentCount = 0;
  int _universityCount = 0;
  int _studentsInEventCount = 0;
  Map<String, dynamic>? nextEvent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Không cần setState ở đây vì _isLoading đã là true
    // Chạy đồng thời cả hai hàm fetch để tăng tốc
    await Future.wait([_fetchStats(), _fetchNextEvent()]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Lấy số lượng thống kê từ Supabase (dùng API mới)
  Future<void> _fetchStats() async {
    try {
      final supabase = Supabase.instance.client;

      final results = await Future.wait([
        supabase.from('event').count(),
        supabase.from('student').count(),
        supabase.from('university').count(),
        supabase.from('student_in_event').count(),
      ]);

      if (!mounted) return;

      setState(() {
        _eventCount = results[0];
        _studentCount = results[1];
        _universityCount = results[2];
        _studentsInEventCount = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải thống kê: $e')));
    }
  }

  // ✅ HÀM MỚI: Lấy sự kiện sắp diễn ra gần nhất
  Future<void> _fetchNextEvent() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Truy vấn để lấy sự kiện sắp tới
      final response = await supabase
          .from('event')
          .select()
          .gte('start_date', now.toIso8601String()) // Lấy ngày >= hôm nay
          .order(
        'start_date',
        ascending: true,
      ) // Sắp xếp để ngày gần nhất lên đầu
          .limit(1) // Chỉ lấy 1 kết quả
          .maybeSingle(); // Dùng maybeSingle để không lỗi nếu không có sự kiện nào

      if (mounted && response != null) {
        setState(() {
          nextEvent = response;
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Lỗi tải sự kiện sắp tới: $e');
      // Không cần hiển thị lỗi ở đây, UI sẽ tự ẩn card đi
    }
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView đã có sẵn, nên useScrollView của MainLayout là false
    return SingleChildScrollView(
      // Padding đã có trong MainLayout, nhưng có thể thêm ở đây nếu cần
      // padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào,',
            style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          Text(
            'Admin',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildStatCard(
                'Sự kiện',
                _eventCount,
                Icons.event,
                Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventManagementScreen(
                      role: widget.role,
                      userId: widget.userId,
                    ),
                  ),
                ),
              ),
              _buildStatCard(
                'Sinh viên',
                _studentCount,
                Icons.people,
                Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentManagementScreen(),
                  ),
                ),
              ),
              _buildStatCard(
                'Trường học',
                _universityCount,
                Icons.school,
                Colors.orange,
              ),
              _buildStatCard(
                'SV tham gia', // Tên thẻ
                _studentsInEventCount, // Số liệu
                Icons.person_add_alt_1, // Icon phù hợp
                Colors.purple, // Màu sắc
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentInEventScreen(
                      eventId: 1,
                      eventTitle: 'Sự kiện có SV',
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Sự kiện sắp tới (hiển thị cả tên sự kiện)
          if (nextEvent != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3), // Giữ nguyên bóng đen mờ cho card nổi bật
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Colors.blue, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sự kiện sắp diễn ra',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (() {
                              if (nextEvent?['event'] != null &&
                                  nextEvent?['event'] is Map &&
                                  nextEvent?['event']['title'] != null) {
                                return nextEvent!['event']['title'];
                              } else if (nextEvent?['title'] != null) {
                                return nextEvent!['title'];
                              } else {
                                return 'Không có tên sự kiện';
                              }
                            })(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (() {
                              String? rawDate =
                                  nextEvent?['event']?['start_date'] ??
                                      nextEvent?['start_date'];
                              if (rawDate == null || rawDate.isEmpty) {
                                return 'Thời gian: -';
                              }
                              DateTime? dt;
                              try {
                                dt = DateTime.tryParse(rawDate);
                              } catch (_) {}
                              if (dt != null) {
                                return 'Thời gian: ' +
                                    dt.toLocal().toString().split(' ')[0];
                              } else {
                                return 'Thời gian: ' + rawDate.split('T')[0];
                              }
                            })(),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          Text(
            'Báo cáo & Thống kê',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            color: Theme.of(context).cardColor,
            surfaceTintColor: Colors.transparent, // Bỏ tint trắng để theme tối không bị lóa
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildReportItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Thống kê sự kiện',
                  subtitle: 'Xem báo cáo chi tiết theo sự kiện, trường học',
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Thêm khoảng trống dưới cùng
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      int value,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent, // Fix lỗi lóa màu trắng trên Dark Mode
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 20, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color, // Chữ phụ theo theme
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary, // Đổi sang màu primary
                    ),
                  )
                      : Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color, // Chữ chính theo theme
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 32,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
          subtitle,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)
      ),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReportingScreen(role: widget.role, userId: widget.userId),
        ),
      ),
    );
  }
}