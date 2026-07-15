import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_attendance/screen/envent_list_screen.dart';
import 'package:student_attendance/services/student_service.dart';
import 'package:student_attendance/domain/entities/Student.dart';
import 'package:table_calendar/table_calendar.dart' as tc;
import 'package:student_attendance/screen/my_event_screen.dart';
import 'package:student_attendance/screen/profile_screen.dart';
import 'package:student_attendance/screen/QRScannerScreen.dart';
import 'package:student_attendance/screen/event_chatbot_screen.dart';
import 'package:student_attendance/screen/settings_screen.dart';
import 'package:student_attendance/screen/recommended_events_screen.dart';
import 'package:student_attendance/services/event_recommendation_service.dart';
import 'package:student_attendance/model/event_model.dart';

import 'main_layout.dart';
import 'notification_bell.dart';

class StudentHomeDynamic extends StatefulWidget {
  final int userId;

  const StudentHomeDynamic({Key? key, required this.userId}) : super(key: key);

  @override
  State<StudentHomeDynamic> createState() => _StudentHomeDynamicState();
}

class _StudentHomeDynamicState extends State<StudentHomeDynamic> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final List<String> _pageTitles = const [
    'Trang chủ',
    'Quét mã',
    'Tài khoản',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      // ✅ STEP 2: SỬ DỤNG WIDGET MỚI VÀ TRUYỀN `userId` VÀO
      _StudentHomeContent(userId: widget.userId), // Trang 0: Nội dung chính
      const SizedBox.shrink(),
      const EventChatbotScreen(),
      ProfileScreen(userId: widget.userId), // Trang 2: Trang tài khoản
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack keeps inactive children alive. The scanner is replaced with
    // a placeholder outside its tab so the camera is never started in advance.
    final pages = List<Widget>.from(_pages);
    pages[1] =
        _currentIndex == 1 ? const QRScannerScreen() : const SizedBox.shrink();

    return MainLayout(
      // Các trang con đã tự quản lý việc cuộn, nên set ở đây là false
      useScrollView: false,
      appBar: null,
      // Dùng widget BottomNavigationBar tiêu chuẩn
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            activeIcon: Icon(Icons.qr_code),
            label: 'Quét mã',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'Tro ly',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
      // IndexedStack giúp giữ trạng thái của các trang khi chuyển qua lại
      child: IndexedStack(index: _currentIndex, children: pages),
    );
  }
}

class _StudentHomeContent extends StatefulWidget {
  final int userId;
  const _StudentHomeContent({required this.userId});

  @override
  State<_StudentHomeContent> createState() => _StudentHomeContentState();
}

class _StudentHomeContentState extends State<_StudentHomeContent> {
  // --- TOÀN BỘ LOGIC VÀ STATE GIỮ NGUYÊN ---
  Set<DateTime> registeredDates = {};
  String studentName = '';
  int totalEvents = 0;
  int myEvents = 0;
  Map<String, dynamic>? nextEvent;
  bool loading = true;
  DateTime calendarFocusedDay = DateTime.now();

  // --- Recommendation ---
  final _recommendService = EventRecommendationService();
  List<RecommendedEvent> _recommendations = [];
  bool _loadingRec = false;
  int? _currentStudentId;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    // --- KHÔNG THAY ĐỔI GÌ Ở HÀM NÀY ---
    final studentService = StudentService();
    final studentRow = await studentService.supabase
        .from('student')
        .select()
        .eq('user_id', widget.userId)
        .maybeSingle();
    if (studentRow == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    final student = Student.fromJson(studentRow);
    final myEventsList =
        await studentService.getMyEventsByStudentId(student.studentId);

    // Lấy danh sách các session mà sinh viên đã điểm danh
    final checkinsResponse = await studentService.supabase
        .from('session_checkin')
        .select('event_session(event_id)')
        .eq('student_id', student.studentId);
    
    final checkins = List<Map<String, dynamic>>.from(checkinsResponse ?? []);
    final uniqueAttendedEventIds = checkins
        .map((c) => c['event_session']?['event_id'])
        .where((id) => id != null)
        .toSet();

    final attendedEvents = myEventsList.where((e) {
      String status = (e['status'] ?? '').toString().toLowerCase();
      final eventId = e['event']?['event_id'];
      
      if (status == 'attended' && !uniqueAttendedEventIds.contains(eventId)) {
        status = 'registered';
      } else if (uniqueAttendedEventIds.contains(eventId) && status != 'completed') {
        status = 'attended';
      }
      
      return status == 'attended' || status == 'completed';
    }).toList();
    final now = DateTime.now();
    final upcoming = myEventsList.where((e) {
      final event = e['event'];
      if (event == null) return false;
      final start = DateTime.tryParse(event['start_date'] ?? '');
      return start != null && start.isAfter(now);
    }).toList();
    upcoming.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['event']?['start_date'] ?? '') ?? DateTime(2100);
      final bDate =
          DateTime.tryParse(b['event']?['start_date'] ?? '') ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });
    final Set<DateTime> regDates = myEventsList
        .map((e) {
          final event = e['event'];
          if (event == null) return null;
          final start = DateTime.tryParse(event['start_date'] ?? '');
          if (start == null) return null;
          return DateTime(start.year, start.month, start.day);
        })
        .whereType<DateTime>()
        .toSet();

    if (mounted) {
      setState(() {
        studentName = student.name;
        totalEvents = attendedEvents.length;
        myEvents = myEventsList.length;
        nextEvent = upcoming.isNotEmpty ? upcoming.first : null;
        registeredDates = regDates;
        loading = false;
        _currentStudentId = student.studentId;
      });
    }
    // Tải gợi ý sau khi đã có studentId
    _loadRecommendations(student.studentId);
  }

  Future<void> _loadRecommendations(int studentId) async {
    if (_loadingRec) return;
    if (mounted) setState(() => _loadingRec = true);
    try {
      final recs = await _recommendService.getRecommendations(
        studentId: studentId,
        userId: widget.userId,
        limit: 6,
      );
      if (mounted) setState(() => _recommendations = recs);
    } catch (_) {
      // Không crash nếu gợi ý lỗi
    } finally {
      if (mounted) setState(() => _loadingRec = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (loading) {
      // Giữ nguyên màn hình loading
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        // Toàn bộ nội dung bên trong Column được giữ nguyên 100%
        children: [
          // --- Old home content before calendar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào,', style: textTheme.bodyMedium),
                      Text(
                        studentName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Avatar tròn nền trong suốt
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/logo_app.png',
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                        ),
                      ),
                    ),
                    // Notification Bell
                    NotificationBell(userId: widget.userId),
                    const SizedBox(width: 8),
                    // Nút setting giữ nguyên
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.secondaryContainer,
                          ),
                          child: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Thống kê + Đăng ký sự kiện
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyEventScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text(
                              'Sự kiện đã tham gia',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalEvents',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyEventScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text(
                              'Sự kiện đã đăng ký',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$myEvents',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Nút đăng ký sự kiện
                Column(
                  children: [
                    SizedBox(height: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventListScreen(userId: widget.userId),
                          ),
                        );
                        fetchStudentData();
                      },
                      child: Column(
                        children: [
                          Icon(Icons.event_available, color: Colors.white),
                          SizedBox(height: 4),
                          Text(
                            'Đăng ký\nSự kiện',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // --- SECTION GỢI Ý CHO BẠN ---
          _buildRecommendationSection(context),
          SizedBox(height: 8),
          // Sự kiện sắp tới (hiển thị cả tên sự kiện)
          if (nextEvent != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: Colors.blue, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sự kiện sắp diễn ra:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            (() {
                              String? rawDate = nextEvent?['event']
                                      ?['start_date'] ??
                                  nextEvent?['start_date'];
                              if (rawDate == null || rawDate.isEmpty)
                                return 'Thời gian: -';
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 16),
          // Lịch của tôi với các ngày đã đăng ký
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Lịch sự kiện của tôi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MyEventScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              child: Text(
                                'Xem tất cả',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Sự kiện:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 12),
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
                            SizedBox(width: 8),
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
                        SizedBox(height: 8),
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
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
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
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                                    ),
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
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(BuildContext context) {
    if (_loadingRec) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ Gợi ý cho bạn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return SizedBox.shrink(); // Ẩn nếu không có gợi ý
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✨ Gợi ý cho bạn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecommendedEventsScreen(userId: widget.userId),
                    ),
                  );
                },
                child: Text(
                  'Xem thêm →',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length > 5 ? 5 : _recommendations.length, // Chỉ show tối đa 5 ở trang chủ
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              return _buildRecommendedEventCard(rec);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedEventCard(RecommendedEvent rec) {
    final event = rec.event;
    final reason = rec.reason;
    final dateStr = DateFormat('dd/MM').format(event.startDate.toLocal());

    return Container(
      width: 240,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Chuyển tới EventListScreen hoặc mở chi tiết.
            // Để đơn giản, ta chuyển người dùng tới EventListScreen.
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventListScreen(userId: widget.userId),
              ),
            );
            // Có thể tối ưu bằng cách mở thẳng chi tiết sự kiện
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag lý do
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  event.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Spacer(),
                    if (event.category != null && event.category!.isNotEmpty)
                      Expanded(
                        child: Text(
                          event.category!,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: Colors.purple),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
