import 'package:flutter/material.dart';
import '../model/student_in_event_model.dart';
import '../services/student_in_event_service.dart';
import '../services/notification_service.dart';
import '../widgets/main_layout.dart'; // ✅ THÊM IMPORT

class StudentInEventScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const StudentInEventScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<StudentInEventScreen> createState() => _StudentInEventScreenState();
}

class _StudentInEventScreenState extends State<StudentInEventScreen> {
  final StudentInEventService _service = StudentInEventService();

  late Future<List<StudentInEvent>> _studentsInEvent;
  List<Map<String, dynamic>> _events = [];
  int? _selectedEventId;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    try {
      final events = await _service.fetchAllEvents();

      final uniqueEvents = {
        for (var e in events) e['event_id'] as int: e,
      }.values.toList();

      setState(() {
        _events = uniqueEvents;
        _selectedEventId = widget.eventId;
        _studentsInEvent = _service.fetchStudentsByEvent(_selectedEventId!);
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
      NotificationService.showError(context, "Lỗi khi tải sự kiện: $e");
    }
  }

  void _loadStudents(int eventId) {
    setState(() {
      _studentsInEvent = _service.fetchStudentsByEvent(eventId);
    });
  }

  void _handleMenuSelection(String value, StudentInEvent student) async {
    try {
      if (value == "attended" || value == "cancelled") {
        await _service.updateStudentStatus(student.studentInEventId, value);
        NotificationService.showSuccess(context, 'Cập nhật trạng thái sinh viên thành công!');
      } else if (value == "delete") {
        await _service.deleteStudentFromEvent(student.studentInEventId);
        NotificationService.showSuccess(context, 'Đã xóa sinh viên khỏi sự kiện thành công.');
      }
      if (_selectedEventId != null) {
        _loadStudents(_selectedEventId!);
      }
    } catch (e) {
      NotificationService.showError(context, 'Đã xảy ra lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SỬ DỤNG MainLayout THAY VÌ Scaffold
    return MainLayout(
      appBar: AppBar(
        title: const Text('SV tham gia sự kiện'),
        backgroundColor: Colors.transparent, // ✅ AppBar trong suốt
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () async {
              try {
                await _service.importStudentsFromExcel();
                if (_selectedEventId != null) {
                  _loadStudents(_selectedEventId!);
                }
                NotificationService.showSuccess(context, '📄 Import sinh viên từ Excel thành công!');
              } catch (e) {
                NotificationService.showError(context, 'Lỗi khi import Excel: $e');
              }
            },
            tooltip: "Import từ file Excel",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedEventId != null) {
                _loadStudents(_selectedEventId!);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final controller = TextEditingController();
          int? selectedEventId;

          final activeEvents = await _service.fetchActiveEvents();

          await showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text("Thêm sinh viên vào sự kiện"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: "Nhập mã sinh viên",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: selectedEventId,
                          decoration: const InputDecoration(
                            labelText: "Chọn sự kiện",
                            border: OutlineInputBorder(),
                          ),
                          items: activeEvents.map((event) {
                            return DropdownMenuItem<int>(
                              value: event['event_id'],
                              child: Text(event['title']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEventId = value;
                            });
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Hủy"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final code = controller.text.trim();
                          if (code.isNotEmpty && selectedEventId != null) {
                            try {
                              await _service.addStudentToEvent(
                                  selectedEventId!, code);
                              Navigator.pop(context);
                              _loadStudents(selectedEventId!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Thêm sinh viên thành công!")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                        child: const Text("Thêm"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      // ✅ useScrollView = false để tránh lỗi layout
      useScrollView: false,
      // ✅ Tất cả nội dung chính được bỏ vào child
      child: Column(
        children: [
          // 🔽 Dropdown chọn sự kiện
          if (_isLoadingEvents)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material( // ✅ THÊM CÁI NÀY
                color: Colors.transparent,
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _events.any((e) => e['event_id'] == _selectedEventId)
                      ? _selectedEventId
                      : null,
                  decoration: const InputDecoration(
                    labelText: "Chọn sự kiện",
                    border: OutlineInputBorder(),
                  ),
                  items: _events.map((event) {
                    return DropdownMenuItem<int>(
                      value: event['event_id'],
                      child: Text(event['title']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEventId = value;
                      if (_selectedEventId != null) {
                        _loadStudents(_selectedEventId!);
                      }
                    });
                  },
                ),
              ),
            ),

          // 🔽 Danh sách sinh viên
          Expanded(
            child: FutureBuilder<List<StudentInEvent>>(
              future: _studentsInEvent,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Chưa có sinh viên nào trong sự kiện này."));
                }

                final students = snapshot.data!;
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    print('Student: ${student.toString()}');
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(student.studentId != null ? '${student.studentId}' : '?'),
                        ),
                        title: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: "MSSV: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: student.student != null && student.student!.studentCode != null
                                    ? student.student!.studentCode
                                    : 'Null',
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "Sự kiện: ${student.event != null && student.event!['title'] != null ? student.event!['title'] : 'Không có'}\n"
                              "Trạng thái: ${student.status ?? 'Không rõ'}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              tooltip: "Đánh dấu: Đã tham dự",
                              onPressed: () => _handleMenuSelection("attended", student),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.orange),
                              tooltip: "Đánh dấu: Đã hủy",
                              onPressed: () => _handleMenuSelection("cancelled", student),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Xóa khỏi sự kiện",
                              onPressed: () => _handleMenuSelection("delete", student),
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
    );
  }
}