import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/event_session_model.dart';
import '../model/event_model.dart';
import '../services/event_session_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'event_session_form_screen.dart';

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
  State<EventSessionManagementScreen> createState() => _EventSessionManagementScreenState();
}

class _EventSessionManagementScreenState extends State<EventSessionManagementScreen> {
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
      // 1. Gọi API để lấy danh sách sự kiện
      events = await apiService.fetchEvents(
        role: widget.role,
        userId: widget.userId,
      );

      // SỬA: Tách logic tìm kiếm để tránh lỗi kiểu dữ liệu
      Event? foundEvent;
      // Chỉ tìm khi danh sách không rỗng
      if (events.isNotEmpty) {
        if (widget.eventId != null) {
          // Thử tìm event theo ID, nếu không thấy sẽ là null
          try {
            foundEvent = events.firstWhere((event) => event.id == widget.eventId);
          } catch (e) {
            foundEvent = null; // Không tìm thấy
          }
        }
        // Nếu không tìm thấy event theo ID, hoặc không có ID để tìm, thì lấy event đầu tiên
        selectedEvent = foundEvent ?? events.first;
      } else {
        // Nếu danh sách rỗng, không có event nào được chọn
        selectedEvent = null;
      }


      if (mounted) setState(() {});
    } catch (e) {
      print('Lỗi khi tải danh sách sự kiện: $e');
      if (mounted) {
        NotificationService.showError(context, 'Lỗi tải sự kiện: $e');
      }
    }
  }


  void _loadSessions() {
    if (selectedEvent?.id != null) {
      setState(() {
        _futureSessions = sessionService.fetchEventSessions(
          eventId: selectedEvent!.id!, // Dùng ! vì đã kiểm tra null
        );
      });
    } else {
      setState(() {
        _futureSessions = Future.value(<EventSession>[]);
      });
    }
  }

  void _handleDelete(EventSession session) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa phiên "${session.title}" không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await sessionService.deleteEventSession(session.sessionId);

                  if (mounted) {
                    NotificationService.showSuccess(context, 'Đã xóa phiên "${session.title}" thành công!');
                  }

                  _loadSessions();

                } catch (e) {
                  if (mounted) {
                    NotificationService.showError(context, 'Lỗi khi xóa phiên: $e');
                  }
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
      NotificationService.showWarning(context, 'Vui lòng chọn sự kiện trước khi tạo phiên');
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

    if (result == true) {
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Phiên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown chọn sự kiện
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: events.map((Event event) {
                    return DropdownMenuItem<Event>(
                      value: event,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          event.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (Event? newValue) {
                    setState(() {
                      selectedEvent = newValue;
                    });
                    _loadSessions();
                  },
                ),
              ],
            ),
          ),
          // Danh sách phiên
          Expanded(
            child: _futureSessions == null
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu...'),
                ],
              ),
            )
                : selectedEvent == null
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Vui lòng chọn sự kiện',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chọn sự kiện từ dropdown ở trên',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : FutureBuilder<List<EventSession>>(
              future: _futureSessions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Lỗi: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
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
                }
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có phiên nào',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Nhấn nút + để tạo phiên mới',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final session = snapshot.data![index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _navigateToCreateEdit(session: session),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      session.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _navigateToCreateEdit(session: session);
                                      } else if (value == 'delete') {
                                        _handleDelete(session);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit),
                                          title: Text('Chỉnh sửa'),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete, color: Colors.red),
                                          title: Text('Xóa', style: TextStyle(color: Colors.red)),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy HH:mm').format(session.startTime)} - '
                                        '${DateFormat('dd/MM/yyyy HH:mm').format(session.endTime)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      session.location,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}