import 'package:flutter/material.dart';
import 'package:student_attendance/screen/envent_list_screen.dart';
import 'package:student_attendance/services/student_service.dart';
import 'package:student_attendance/domain/entities/Student.dart';
import 'package:table_calendar/table_calendar.dart' as tc;
import 'package:student_attendance/screen/my_event_screen.dart';
import 'package:student_attendance/screen/profile_screen.dart';
import 'package:student_attendance/screen/QRScannerScreen.dart';
import 'package:student_attendance/screen/ManualCheckInScreen.dart';
import 'package:student_attendance/screen/settings_screen.dart';

class StudentHomeDynamic extends StatefulWidget {
  final int userId;
  const StudentHomeDynamic({Key? key, required this.userId}) : super(key: key);

  @override
  State<StudentHomeDynamic> createState() => _StudentHomeDynamicState();
}

class _StudentHomeDynamicState extends State<StudentHomeDynamic> {
  Set<DateTime> registeredDates = {};
  String studentName = '';
  int totalEvents = 0;
  int myEvents = 0;
  Map<String, dynamic>? nextEvent;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    final studentService = StudentService();
    // Lấy thông tin sinh viên
    final studentRow = await studentService.supabase
        .from('student')
        .select()
        .eq('user_id', widget.userId)
        .maybeSingle();
    if (studentRow == null) {
      setState(() { loading = false; });
      return;
    }
    final student = Student.fromJson(studentRow);
    // Lấy tất cả sự kiện đã đăng ký
    final myEventsList = await studentService.getMyEventsByStudentId(student.studentId);
    // Chỉ tính sự kiện đã tham gia khi đã điểm danh thành công (status == 'checked_in')
    final attendedEvents = myEventsList.where((e) => (e['status'] ?? '') == 'checked_in').toList();
    // Sự kiện sắp tới (lấy event gần nhất trong tương lai)
    final now = DateTime.now();
    final upcoming = myEventsList.where((e) {
      final event = e['event'];
      if (event == null) return false;
      final start = DateTime.tryParse(event['start_date'] ?? '');
      return start != null && start.isAfter(now);
    }).toList();
    upcoming.sort((a, b) {
      final aDate = DateTime.tryParse(a['event']?['start_date'] ?? '') ?? DateTime(2100);
      final bDate = DateTime.tryParse(b['event']?['start_date'] ?? '') ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });
    // Lấy các ngày đã đăng ký sự kiện (dạng DateTime, chỉ lấy ngày)
    final Set<DateTime> regDates = myEventsList.map((e) {
      final event = e['event'];
      if (event == null) return null;
      final start = DateTime.tryParse(event['start_date'] ?? '');
      if (start == null) return null;
      return DateTime(start.year, start.month, start.day);
    }).whereType<DateTime>().toSet();
    setState(() {
      studentName = student.name;
      totalEvents = attendedEvents.length;
      myEvents = myEventsList.length;
      nextEvent = upcoming.isNotEmpty ? upcoming.first : null;
      registeredDates = regDates;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F3),
      body: SafeArea(
        child: Column(
          children: [
            // --- Old home content before calendar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào,', style: textTheme.bodyMedium),
                      Text(studentName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Spacer(),
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
                      SizedBox(width: 8),
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
                              color: Colors.grey.shade200,
                            ),
                            child: Icon(Icons.settings, color: Colors.black87),
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
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        children: [
                          Text('Sự kiện đã tham gia', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('$totalEvents', style: TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        children: [
                          Text('Tổng sự kiện đã đăng ký', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('$myEvents', style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventListScreen(userId: widget.userId),
                            ),
                          );
                          fetchStudentData();
                        },
                        child: Column(
                          children: [
                            Icon(Icons.event_available, color: Colors.white),
                            SizedBox(height: 4),
                            Text('Đăng ký\nSự kiện', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Sự kiện sắp tới (hiển thị cả tên sự kiện)
            if (nextEvent != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
                            ),
                            SizedBox(height: 2),
                            Text(
                              (() {
                                if (nextEvent?['event'] != null && nextEvent?['event'] is Map && nextEvent?['event']['title'] != null) {
                                  return nextEvent!['event']['title'];
                                } else if (nextEvent?['title'] != null) {
                                  return nextEvent!['title'];
                                } else {
                                  return 'Không có tên sự kiện';
                                }
                              })(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              (() {
                                String? rawDate = nextEvent?['event']?['start_date'] ?? nextEvent?['start_date'];
                                if (rawDate == null || rawDate.isEmpty) return 'Thời gian: -';
                                DateTime? dt;
                                try {
                                  dt = DateTime.tryParse(rawDate);
                                } catch (_) {}
                                if (dt != null) {
                                  return 'Thời gian: ' + dt.toLocal().toString().split(' ')[0];
                                } else {
                                  return 'Thời gian: ' + rawDate.split('T')[0];
                                }
                              })(),
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            // (Đã bỏ phần thông báo theo yêu cầu)
            // Thống kê, sự kiện sắp tới, thông báo, ... (add your previous widgets here)
            // --- End old home content ---
            // --- Calendar section below ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Lịch của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
                              Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyEventScreen(userId: widget.userId),
                                    ),
                                  );
                                },
                                child: Text('Xem tất cả', style: TextStyle(color: Colors.blue)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          tc.TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2100, 12, 31),
                            focusedDay: DateTime.now(),
                            calendarFormat: tc.CalendarFormat.month,
                            headerVisible: false,
                            daysOfWeekVisible: true,
                            calendarStyle: tc.CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            selectedDayPredicate: (day) {
                              return registeredDates.contains(DateTime(day.year, day.month, day.day));
                            },
                            onDaySelected: (selectedDay, focusedDay) {},
                            calendarBuilders: tc.CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                if (registeredDates.contains(DateTime(day.year, day.month, day.day))) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }
                                return null;
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
            Spacer(),
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home, color: Colors.green),
                        Text('Trang chủ', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRScannerScreen(),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code, color: Colors.green),
                          Text('Quét Mã', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.green),
                          Text('Tài khoản', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}