import 'package:flutter/material.dart';
import 'package:student_attendance/screen/ManualCheckInScreen.dart';
import 'package:student_attendance/screen/QRScannerScreen.dart';
import '../screen/event_management_screen.dart';
import '../screen/student_in_event_screen.dart';
import '../screen/university_management_screen.dart';
import 'placeholder_screen.dart';
import '../screen/SessionListScreen.dart';
import 'package:student_attendance/screen/student_management_screen.dart';
import '../screen/event_session_management_screen.dart';
import '../screen/reporting_screen.dart';
import '../screen/settings_screen.dart';
import '../screen/profile_screen.dart';
import '../screen/my_event_screen.dart';

import 'student_home_dynamic.dart';
import '../screen/envent_list_screen.dart';


class HomeScreen extends StatefulWidget {
  final String role;   // admin | organizer | student
  final int userId;    // id user sau khi login

  const HomeScreen({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Danh sách menu cho từng role
  List<Map<String, dynamic>> get _adminFeatures => [
    {
      'title': 'Quản lý Sự kiện',
      'icon': Icons.event_note,
      'screen': EventManagementScreen(role: widget.role, userId: widget.userId),
    },
    {
      'title': 'Quản lý Sinh viên',
      'icon': Icons.people,
      'screen': const StudentManagementScreen(),
    },
    {
      'title': 'Quản lý Trường/ĐV',
      'icon': Icons.school,
      'screen': const UniversityScreen(),
    },
    {
      'title': 'Quản lý Phiên',
      'icon': Icons.access_time,
      'screen': EventSessionManagementScreen(role: widget.role, userId: widget.userId),
    },
    {
      'title': 'SV trong Sự kiện',
      'icon': Icons.group_add,
      'screen': StudentInEventScreen(eventId: 4, eventTitle: "Sự kiện có SV"),
    },
    {
      'title': 'Điểm danh',
      'icon': Icons.fact_check_outlined,
      'screen': const SessionListScreen(),
    },
    {
      'title': 'Báo cáo & Thống kê',
      'icon': Icons.bar_chart,
      'screen': ReportingScreen(role: widget.role, userId: widget.userId),
    },
    {
      'title': 'Cài đặt',
      'icon': Icons.settings,
      'screen': const SettingsScreen(),
    },
  ];

  List<Map<String, dynamic>> get _organizerFeatures => [
    {
      'title': 'Quản lý Sự kiện của tôi',
      'icon': Icons.event_note,
      'screen': EventManagementScreen(role: widget.role, userId: widget.userId),    },
    {
      'title': 'Quản lý Phiên của tôi',
      'icon': Icons.access_time,
      'screen':EventSessionManagementScreen(role: widget.role, userId: widget.userId), // Cũng filter theo event của organizer
    },
    {
      'title': 'Điểm danh',
      'icon': Icons.fact_check_outlined,
      'screen': const SessionListScreen(),
    },
    {
      'title': 'Cài đặt',
      'icon': Icons.settings,
      'screen': const SettingsScreen(),
    },
  ];

  List<Map<String, dynamic>> _studentFeatures(int studentId) => [
    {
      'title': 'Quét QR Check-in',
      'icon': Icons.qr_code_scanner,
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerScreen(),
          ),
        );
      },
    },
    {
      'title': 'Đăng ký sự kiện',
      'icon': Icons.event_available,
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventListScreen(userId: studentId),
          ),
        );
      },
    },
    {
      'title': 'Sự kiện của tôi',
      'icon': Icons.event,
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyEventScreen(userId: studentId),
          ),
        );
      },
    },
    {
      'title': 'Thông tin cá nhân',
      'icon': Icons.person,
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: studentId),
          ),
        );
      },
    },
    {
      'title': 'Cài đặt',
      'icon': Icons.settings,
      'screen': const SettingsScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardTheme = Theme.of(context).cardTheme;

    if (widget.role == "student") {
      // Giao diện đặc biệt cho sinh viên, lấy dữ liệu động từ Supabase
  return StudentHomeDynamic(userId: widget.userId);
    }

    // Giao diện mặc định cho admin/organizer
    List<Map<String, dynamic>> features;
    if (widget.role == "admin") {
      features = _adminFeatures;
    } else if (widget.role == "organizer") {
      features = _organizerFeatures;
    } else {
      features = _studentFeatures(widget.userId);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Trang chủ (${widget.role})', style: textTheme.headlineSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.secondary.withOpacity(0.3),
                  colorScheme.background,
                  colorScheme.primary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.2,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return _buildFeatureCard(
                  context,
                  title: feature['title'],
                  icon: feature['icon'],
                  onTap: feature['onTap'] ??
                          () {
                        if (feature['screen'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => feature['screen']),
                          );
                        }
                      },
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  cardTheme: cardTheme, // Truyền biến cardTheme (kiểu CardThemeData)
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
        required ColorScheme colorScheme,
        required TextTheme textTheme,
        // SỬA LỖI Ở ĐÂY: Sửa kiểu dữ liệu từ CardTheme thành CardThemeData
        required CardThemeData cardTheme,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        color: cardTheme.color ?? colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}