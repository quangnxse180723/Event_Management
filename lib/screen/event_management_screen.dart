import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../model/event_model.dart';
import '../services/api_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa sự kiện không có ID.')),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa sự kiện thành công!')),
                    );
                  }
                  _loadEvents();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa: $e')),
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
      appBar: AppBar(
        title: const Text('Quản lý Sự kiện'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi tải dữ liệu: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadEvents, child: const Text('Thử lại'))
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có sự kiện nào.'));
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                child: ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Tổ chức bởi: ${event.organizer}\n'
                          'Từ ${DateFormat('dd/MM/yyyy').format(event.startDate)} đến ${DateFormat('dd/MM/yyyy').format(event.endDate)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        // SỬA: Gọi hàm điều hướng để sửa
                        onPressed: () => _navigateToCreateEditScreen(event: event),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
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
        // SỬA: Gọi hàm điều hướng để tạo mới
        onPressed: () => _navigateToCreateEditScreen(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}