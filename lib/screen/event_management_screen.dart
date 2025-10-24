import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../model/event_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'create_edit_event_screen.dart';

class EventManagementScreen extends StatefulWidget {
  final String role;
  final int userId;

  const EventManagementScreen({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Event>> _futureEvents;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _futureEvents = apiService.fetchEvents(
        role: widget.role,
        userId: widget.userId,
      );
    });
  }

  void _refreshEvents() {
    _loadEvents();
    NotificationService.showInfo(
      context,
      'Đã làm mới danh sách sự kiện 🔄',
    );
  }

  // SỬA: Tạo hàm điều hướng dùng chung để tránh lặp code
  void _navigateToCreateEditScreen({Event? event}) {
    Navigator.push<bool>( // Chờ kết quả trả về là bool
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditEventScreen(
          event: event,
          userId: widget.userId,
          role: widget.role,// Luôn truyền userId
        ),
      ),
    ).then((result) {
      // Nếu màn hình con trả về true (có thay đổi), thì mới tải lại danh sách
      if (result == true) {
        _loadEvents();
      }
    });
  }

  void _handleDelete(Event event) {
    if (event.id == null) {
      NotificationService.showWarning(
        context,
        'Không thể xóa sự kiện không có ID ⚠️',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa sự kiện "${event.title}" không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await apiService.deleteEvent(event.id!);
                  if (mounted) {
                    NotificationService.showSuccess(
                      context,
                      'Đã xóa sự kiện thành công! 🗑️',
                    );
                  }
                  _loadEvents();
                } catch (e) {
                  if (mounted) {
                    NotificationService.showError(
                      context,
                      'Lỗi khi xóa sự kiện: $e',
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF8), // Nền xanh lá nhạt
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF43A047), // Xanh lá đậm
        title: const Text(
          'Quản lý Sự kiện',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Làm mới',
            onPressed: _refreshEvents,
          ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF43A047)));
          }
          if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService.showError(
                context,
                'Lỗi tải dữ liệu sự kiện: \\${snapshot.error}',
              );
            });
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Lỗi tải dữ liệu: \\${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loadEvents,
                      child: const Text('Thử lại'),
                    )
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Không có sự kiện nào.',
                style: TextStyle(
                  color: Color(0xFF43A047),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            );
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                color: Colors.white,
                elevation: 6,
                shadowColor: const Color(0xFF43A047).withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: const Color(0xFF43A047).withOpacity(0.12), width: 1.2),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF43A047).withOpacity(0.15),
                    child: const Icon(Icons.event, color: Color(0xFF43A047)),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      'Tổ chức bởi: \\${event.organizer}\nTừ \\${DateFormat('dd/MM/yyyy').format(event.startDate)} đến \\${DateFormat('dd/MM/yyyy').format(event.endDate)}',
                      style: const TextStyle(
                        color: Color(0xFF388E3C),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF43A047)),
                        tooltip: 'Sửa sự kiện',
                        onPressed: () => _navigateToCreateEditScreen(event: event),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Xóa sự kiện',
                        onPressed: () => _handleDelete(event),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: (widget.role == 'admin' || widget.role == 'organizer')
          ? FloatingActionButton(
              onPressed: () => _navigateToCreateEditScreen(),
              backgroundColor: const Color(0xFF43A047),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
              tooltip: 'Tạo sự kiện mới',
            )
          : null,
    );
  }
}