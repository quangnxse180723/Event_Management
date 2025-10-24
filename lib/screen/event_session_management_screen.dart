import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/event_session_model.dart';
import '../model/event_model.dart';
import '../services/event_session_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'event_session_form_screen.dart';
import '../widgets/main_layout.dart'; // ✅ dùng layout có sẵn

class EventSessionManagementScreen extends StatefulWidget {
  final int? eventId;
  final String role;
  final int userId;

  const EventSessionManagementScreen({
    super.key,
    this.eventId,
    required this.role,
    required this.userId,
  });

  @override
  State<EventSessionManagementScreen> createState() =>
      _EventSessionManagementScreenState();
}

class _EventSessionManagementScreenState
    extends State<EventSessionManagementScreen> {
  final EventSessionService sessionService = EventSessionService();
  final ApiService apiService = ApiService();

  Future<List<EventSession>>? _futureSessions;
  Event? selectedEvent;
  List<Event> events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await _loadEvents();
    _loadSessions();
  }

  Future<void> _loadEvents() async {
    try {
      events = await apiService.fetchEvents(
        role: widget.role,
        userId: widget.userId,
      );

      if (events.isNotEmpty) {
        if (widget.eventId != null) {
          selectedEvent = events.firstWhere(
                (e) => e.id == widget.eventId,
            orElse: () => events.first,
          );
        } else {
          selectedEvent = events.first;
        }
      } else {
        selectedEvent = null;
      }

      if (mounted) setState(() {});
    } catch (e) {
      NotificationService.showError(context, 'Lỗi tải sự kiện: $e');
    }
  }

  void _loadSessions() {
    if (selectedEvent?.id != null) {
      setState(() {
        _futureSessions =
            sessionService.fetchEventSessions(eventId: selectedEvent!.id!);
      });
    } else {
      setState(() {
        _futureSessions = Future.value([]);
      });
    }
  }

  void _handleDelete(EventSession session) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content:
          Text('Bạn có chắc chắn muốn xóa phiên "${session.title}" không?'),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await sessionService.deleteEventSession(session.sessionId);
                  if (mounted) {
                    NotificationService.showSuccess(
                        context, 'Đã xóa phiên "${session.title}" thành công!');
                  }
                  _loadSessions();
                } catch (e) {
                  NotificationService.showError(
                      context, 'Lỗi khi xóa phiên: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToCreateEdit({EventSession? session}) async {
    if (selectedEvent == null) {
      NotificationService.showWarning(
          context, 'Vui lòng chọn sự kiện trước khi tạo phiên');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventSessionFormScreen(
          eventSession: session,
          eventId: selectedEvent!.id!,
        ),
      ),
    );

    if (result == true) _loadSessions();
  }

  void _refreshSessions() {
    _loadSessions();
    NotificationService.showInfo(context, 'Đã làm mới danh sách phiên 🔄');
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false, // ✅ tránh lỗi infinite size
      child: Scaffold(
        backgroundColor: Colors.transparent, // ✅ thấy nền gradient & sóng
        appBar: AppBar(
          title: const Text('Quản lý Phiên'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshSessions,
            ),
          ],
        ),
        body: Column(
          children: [
            // --- Dropdown chọn sự kiện ---
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn sự kiện:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Event>(
                    value: selectedEvent,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: events.map((Event event) {
                      return DropdownMenuItem<Event>(
                        value: event,
                        child: Text(
                          event.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (Event? newValue) {
                      setState(() => selectedEvent = newValue);
                      _loadSessions();
                    },
                  ),
                ],
              ),
            ),

            // --- Danh sách phiên ---
            Expanded(
              child: _futureSessions == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<List<EventSession>>(
                future: _futureSessions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      NotificationService.showError(
                          context, 'Lỗi tải dữ liệu: ${snapshot.error}');
                    });
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSessions,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Chưa có phiên nào.'),
                    );
                  }

                  final sessions = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        margin:
                        const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        child: ListTile(
                          title: Text(session.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy HH:mm').format(session.startTime)} - '
                                '${DateFormat('dd/MM/yyyy HH:mm').format(session.endTime)}\n'
                                'Địa điểm: ${session.location}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.green),
                                onPressed: () => _navigateToCreateEdit(
                                    session: session),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _handleDelete(session),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton:
        (widget.role == 'admin' || widget.role == 'organizer')
            ? FloatingActionButton(
          onPressed: () => _navigateToCreateEdit(),
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        )
            : null,
      ),
    );
  }
}
