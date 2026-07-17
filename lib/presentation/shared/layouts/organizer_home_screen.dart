import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart' as tc;

import 'package:student_attendance/presentation/event/event_management_screen.dart';
import 'package:student_attendance/presentation/session/session_list_screen.dart';
import 'package:student_attendance/presentation/event/event_chatbot_screen.dart';
import 'package:student_attendance/presentation/profile/settings_screen.dart';
import 'package:student_attendance/presentation/student/student_in_event_screen.dart';
import 'package:student_attendance/presentation/profile/organizer_profile_screen.dart'; // ✅ ĐÃ THÊM IMPORT MÀN HÌNH PROFILE
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';
import 'package:student_attendance/presentation/shared/widgets/notification_bell.dart';
import 'package:student_attendance/presentation/leaderboard/leaderboard_screen.dart';

// ------------------------------
// MÀN HÌNH CHÍNH DÀNH CHO ORGANIZER
// (Layout giống Admin, nội dung home kết hợp Admin + Student)
// ------------------------------
class OrganizerHomeScreen extends StatefulWidget {
  final String role;
  final int userId;

  const OrganizerHomeScreen(
      {super.key, required this.role, required this.userId});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // Trang 0: Nội dung chính (Widget tùy chỉnh bên dưới)
      _OrganizerHomeContent(role: widget.role, userId: widget.userId),
      // Trang 1: Điểm danh (Dùng chung)
      const SessionListScreen(),
      const EventChatbotScreen(),
      // Trang 2: Cài đặt (Dùng chung)
      const SettingsScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Tái sử dụng layout MainLayout và BottomNavigationBar từ AdminHomeScreen
    return MainLayout(
      useScrollView: false,
      appBar: null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
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
      // IndexedStack giúp giữ trạng thái của các trang
      child: IndexedStack(index: _currentIndex, children: _pages),
    );
  }
}

// ----------------------------------------------------
// NỘI DUNG TRANG CHỦ CỦA ORGANIZER (_OrganizerHomeContent)
// ----------------------------------------------------
class _OrganizerHomeContent extends StatefulWidget {
  final String role;
  final int userId;

  const _OrganizerHomeContent({required this.role, required this.userId});

  @override
  State<_OrganizerHomeContent> createState() => _OrganizerHomeContentState();
}

class _OrganizerHomeContentState extends State<_OrganizerHomeContent> {
  bool _isLoading = true;
  int _eventCount = 0; // Thống kê: Sự kiện của tôi
  int _studentsInEventCount = 0; // Thống kê: SV tham gia sự kiện của tôi
  Map<String, dynamic>? nextEvent; // Sự kiện sắp diễn ra (của tôi)
  Set<DateTime> registeredDates = {}; // Lịch: Các ngày sự kiện (của tôi)
  DateTime calendarFocusedDay = DateTime.now(); // Lịch: Ngày đang focus

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Tải song song tất cả dữ liệu
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.wait([
      _fetchStats(),
      _fetchNextEvent(),
      _fetchCalendarEvents(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Lấy thống kê: (1) Số sự kiện của tôi, (2) Số SV tham gia sự kiện của tôi
  Future<void> _fetchStats() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Đếm số sự kiện do organizer này tạo (SỬA LỖI KIỂU DỮ LIỆU)
      final eventRes = await supabase
          .from('event')
          .select()
          .eq('user_id', widget.userId);
      final eventCount = eventRes.length;

      // 2. Đếm số sinh viên tham gia các sự kiện của organizer này
      // Lấy ID các sự kiện của tôi
      final myEventsRes = await supabase
          .from('event')
          .select('event_id')
          .eq('user_id', widget.userId);

      final myEventIds =
      myEventsRes.map((e) => e['event_id'] as int).toList();

      int studentCount = 0;
      if (myEventIds.isNotEmpty) {
        // Đếm số SV trong các event ID đó (sửa lỗi trả về int)
        final inList = '(${myEventIds.join(',')})';
        final res = await supabase
            .from('student_in_event')
            .select()
            .filter('event_id', 'in', inList);
        if (res is List) {
          studentCount = res.length;
        } else {
          studentCount = 0;
        }
      }

      if (!mounted) return;
      setState(() {
        _eventCount = eventCount;
        _studentsInEventCount = studentCount;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Lỗi tải thống kê organizer: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải thống kê: $e')));
    }
  }

  /// Lấy sự kiện SẮP DIỄN RA (chỉ của organizer này)
  Future<void> _fetchNextEvent() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      final response = await supabase
          .from('event')
          .select()
          .eq('user_id',
          widget.userId) // YÊU CẦU: Chỉ lấy sự kiện của user này
          .gte('start_date', now.toIso8601String())
          .order('start_date', ascending: true)
          .limit(1)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          nextEvent = response;
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Lỗi tải sự kiện sắp tới (organizer): $e');
    }
  }

  /// Lấy các ngày có sự kiện cho LỊCH (chỉ của organizer này)
  Future<void> _fetchCalendarEvents() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('event')
          .select('start_date')
          .eq('user_id', widget.userId); // Chỉ lấy sự kiện của user này

      // Tái sử dụng logic từ StudentHomeDynamic
      final Set<DateTime> regDates = response.map((e) {
        final start = DateTime.tryParse(e['start_date'] ?? '');
        if (start == null) return null;
        return DateTime(start.year, start.month, start.day);
      }).whereType<DateTime>().toSet();

      if (mounted) {
        setState(() {
          registeredDates = regDates;
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Lỗi tải ngày lịch (organizer): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tái sử dụng UI từ Admin và Student
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lời chào (từ AdminHomeScreen)
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spacer takes care of this
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xin chào,',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    widget.role == 'organizer'
                        ? 'Tổ chức'
                        : 'Organizer', // Hiển thị vai trò
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              NotificationBell(userId: widget.userId),
              const SizedBox(width: 12),
              // Nút bấm Avatar chuyển hướng
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrganizerProfileScreen(userId: widget.userId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue, size: 28),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thẻ thống kê (từ AdminHomeScreen, nhưng chỉ 2 thẻ)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
            1.1, // Tăng tỷ lệ để thẻ cao hơn một chút (giống ảnh)
            children: [
              _buildStatCard(
                'Sự kiện của tôi',
                _eventCount,
                Icons.event,
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventManagementScreen(
                        role: widget.role,
                        userId: widget.userId,
                      ),
                    ),
                  ).then((_) {
                    _loadData();
                  });
                },
              ),
              _buildStatCard(
                'SV tham gia',
                _studentsInEventCount,
                Icons.people,
                Colors.green,
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
          const SizedBox(height: 14),

          // Bảng xếp hạng Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
                ),
                child: Row(
                  children: [
                    const Text(
                      '🏆',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bảng xếp hạng Tích cực',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Xem ngay top sinh viên năng nổ nhất!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.8), size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Thẻ Sự kiện sắp tới (từ AdminHomeScreen / StudentHomeDynamic)
          if (nextEvent != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).toInt()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    (() {
                      final String? imageUrl = nextEvent?['event']?['image_url'] ?? nextEvent?['image_url'];
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                          ),
                        );
                      } else {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.event, color: Colors.blue, size: 32),
                        );
                      }
                    })(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sự kiện của tôi sắp diễn ra',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Logic parse tên sự kiện (dùng chung)
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
                          // Logic parse ngày (dùng chung)
                          Text(
                            (() {
                              try {
                                final dateStr = nextEvent?['start_date'] ?? '';
                                final date = DateTime.parse(dateStr);
                                return '${date.day}/${date.month}/${date.year}';
                              } catch (_) {
                                return 'Chưa xác định';
                              }
                            })(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Lịch sự kiện (từ StudentHomeDynamic)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha((0.1 * 255).toInt()), blurRadius: 4)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Sự kiện:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: calendarFocusedDay.month,
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (m) => DropdownMenuItem(
                            value: m,
                            child: Text('Tháng $m'),
                          ),
                        )
                            .toList(),
                        onChanged: (m) {
                          if (m != null) {
                            setState(() {
                              calendarFocusedDay = DateTime(
                                calendarFocusedDay.year,
                                m,
                                1,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: calendarFocusedDay.year,
                        items: List.generate(
                          6,
                              (i) => DateTime.now().year - 2 + i,
                        )
                            .map(
                              (y) => DropdownMenuItem(
                            value: y,
                            child: Text('Năm $y'),
                          ),
                        )
                            .toList(),
                        onChanged: (y) {
                          if (y != null) {
                            setState(() {
                              calendarFocusedDay = DateTime(
                                y,
                                calendarFocusedDay.month,
                                1,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tái sử dụng TableCalendar từ StudentHomeDynamic
                  tc.TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: calendarFocusedDay,
                    calendarFormat: tc.CalendarFormat.month,
                    headerVisible: false,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        calendarFocusedDay = focusedDay;
                      });
                    },
                    calendarBuilders: tc.CalendarBuilders(
                      todayBuilder: (context, day, focusedDay) {
                        final isRegistered = registeredDates.contains(
                          DateTime(day.year, day.month, day.day),
                        );
                        if (isRegistered) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                            ),
                          );
                        }
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final isRegistered = registeredDates.contains(
                          DateTime(day.year, day.month, day.day),
                        );
                        if (isRegistered) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      outsideBuilder: (context, day, focusedDay) {
                        return Container(
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20), // Thêm khoảng trống dưới cùng
        ],
      ),
    );
  }

  /// Hàm Helper: Tái sử dụng từ AdminHomeScreen
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
      surfaceTintColor: Theme.of(context).cardColor,
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
                backgroundColor: color.withAlpha((0.15 * 255).toInt()),
                child: Icon(icon, size: 20, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.blue,
                    ),
                  )
                      : Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
}