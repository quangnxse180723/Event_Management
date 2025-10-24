import 'package:flutter/material.dart';
import 'package:student_attendance/widgets/student_home_dynamic.dart';
import 'package:student_attendance/screen/profile_screen.dart';
import 'package:student_attendance/screen/my_event_screen.dart';
import 'package:student_attendance/screen/envent_list_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final int userId;
  const StudentMainScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      StudentHomeDynamic(userId: widget.userId),
      MyEventScreen(userId: widget.userId),
      EventListScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Lịch của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Đăng ký sự kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
