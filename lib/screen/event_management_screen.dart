import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../model/event_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'create_edit_event_screen.dart';
import '../widgets/main_layout.dart';
import 'event_session_management_screen.dart'; // Thêm import

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
    NotificationService.showInfo(context, 'Đã làm mới danh sách sự kiện 🔄');
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
      if (result == true) _loadEvents();
    });
  }

  void _handleDelete(Event event) {
    if (event.id == null) {
      NotificationService.showWarning(context, 'Không thể xóa sự kiện không có ID ⚠️');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sự kiện "${event.title}" không?'),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await apiService.deleteEvent(event.id!);
                if (mounted) {
                  NotificationService.showSuccess(context, 'Đã xóa sự kiện thành công! 🗑️');
                }
                _loadEvents();
              } catch (e) {
                if (mounted) {
                  NotificationService.showError(context, 'Lỗi khi xóa sự kiện: $e');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false, // ✅ để ListView hoạt động đúng
      appBar: AppBar(
        title: const Text(
          'Quản lý Sự kiện',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEvents,
          ),
        ],
      ),
      // ** ĐÃ THAY ĐỔI: Thêm Row chứa 2 nút **
      floatingActionButton: (widget.role == 'admin' || widget.role == 'organizer')
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Nút "Phiên sự kiện"
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventSessionManagementScreen(
                          role: widget.role,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  heroTag: 'sessionFab', // Tránh xung đột Hero tag
                  icon: const Icon(Icons.access_time, color: Colors.white),
                  label: const Text('Phiên', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.blueAccent,
                ),
                const SizedBox(width: 16),
                // Nút "Thêm sự kiện" (giữ nguyên)
                FloatingActionButton(
                  onPressed: () => _navigateToCreateEditScreen(),
                  heroTag: 'eventFab', // Tránh xung đột Hero tag
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            )
          : null,
      child: FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NotificationService.showError(
                context,
                'Lỗi tải dữ liệu sự kiện: ${snapshot.error}',
              );
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadEvents,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có sự kiện nào.'));
          }

          final events = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Tổ chức bởi: ${event.organizer}\n'
                        'Từ ${DateFormat('dd/MM/yyyy').format(event.startDate)} '
                        'đến ${DateFormat('dd/MM/yyyy').format(event.endDate)}',
                  ),
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
    );
  }
}
