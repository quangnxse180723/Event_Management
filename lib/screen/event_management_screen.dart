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

  Future<void> _loadEvents() async {
    setState(() {
      _futureEvents = apiService.fetchEvents(
        role: widget.role,
        userId: widget.userId,
      );
    });
    // Bắt lỗi ở đây để tránh Unhandled Exception nếu Future thất bại
    // và lỗi sẽ được hiển thị bởi FutureBuilder.
    try {
      await _futureEvents;
    } catch (_) {
      // Bỏ qua lỗi ở đây vì nó sẽ được xử lý trong FutureBuilder
    }
  }

  void _navigateToCreateEditScreen({Event? event}) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditEventScreen(
          event: event,
          userId: widget.userId,
          role: widget.role,
        ),
      ),
    ).then((result) {
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
                // Đóng dialog xác nhận trước
                Navigator.of(dialogContext).pop();

                // === SỬA LỖI: SỬ DỤNG TRY-CATCH ===
                try {
                  // Gọi hàm delete. Nếu có lỗi, nó sẽ nhảy vào khối catch.
                  await apiService.deleteEvent(event.id!);

                  // Nếu không có lỗi, tức là đã xóa thành công.
                  if (!mounted) return;

                  // Hiển thị thông báo thành công và tải lại danh sách.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa sự kiện thành công!')),
                  );
                  _loadEvents(); // Tải lại danh sách sự kiện

                } catch (e) {
                  // Nếu có lỗi xảy ra trong quá trình xóa.
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xóa thất bại: ${e.toString()}')),
                  );
                }
                // ======================================
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
              final start = event.startDate;
              final end = event.endDate;

              final startText = (start != null)
                  ? DateFormat('dd/MM/yyyy').format(start)
                  : '—';
              final endText = (end != null)
                  ? DateFormat('dd/MM/yyyy').format(end)
                  : '—';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                child: ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Tổ chức bởi: ${event.organizer}\n'
                          'Từ $startText đến $endText'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
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
        onPressed: () => _navigateToCreateEditScreen(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}