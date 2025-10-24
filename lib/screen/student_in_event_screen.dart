import 'package:flutter/material.dart';
import '../model/student_in_event_model.dart';
import '../services/student_in_event_service.dart';
import '../services/notification_service.dart';
import '../widgets/main_layout.dart';

enum _StudentAction { attended, cancelled, delete }

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

  final GlobalKey _dropdownKey = GlobalKey();

  late Future<List<StudentInEvent>> _studentsInEventFuture;
  List<Map<String, dynamic>> _events = [];
  int? _selectedEventId;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    _selectedEventId = widget.eventId;
    _studentsInEventFuture = _service.fetchStudentsByEvent(_selectedEventId!);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _service.fetchAllEvents();
      final uniqueEvents = {
        for (var e in events) e['event_id'] as int: e,
      }.values.toList();

      if (mounted) {
        setState(() {
          _events = uniqueEvents;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
        NotificationService.showError(context, "Lỗi khi tải sự kiện: $e");
      }
    }
  }

  void _reloadStudents() {
    if (_selectedEventId != null) {
      setState(() {
        _studentsInEventFuture = _service.fetchStudentsByEvent(_selectedEventId!);
      });
    }
  }

  Future<void> _handleStudentAction(_StudentAction action, StudentInEvent student) async {
    try {
      String successMessage;
      switch (action) {
        case _StudentAction.attended:
          await _service.updateStudentStatus(student.studentInEventId, 'attended');
          successMessage = 'Cập nhật trạng thái sinh viên thành công!';
          break;
        case _StudentAction.cancelled:
          await _service.updateStudentStatus(student.studentInEventId, 'cancelled');
          successMessage = 'Cập nhật trạng thái sinh viên thành công!';
          break;
        case _StudentAction.delete:
          await _service.deleteStudentFromEvent(student.studentInEventId);
          successMessage = 'Đã xóa sinh viên khỏi sự kiện.';
          break;
      }
      NotificationService.showSuccess(context, successMessage);
      _reloadStudents();
    } catch (e) {
      NotificationService.showError(context, 'Đã xảy ra lỗi: $e');
    }
  }

  Future<void> _importFromExcel() async {
    try {
      await _service.importStudentsFromExcel();
      _reloadStudents();
      NotificationService.showSuccess(context, '📄 Import sinh viên từ Excel thành công!');
    } catch (e) {
      NotificationService.showError(context, 'Lỗi khi import Excel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      useScrollView: false,
      child: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('SV tham gia sự kiện'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.file_upload),
          onPressed: _importFromExcel,
          tooltip: "Import từ file Excel",
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _reloadStudents,
          tooltip: "Tải lại danh sách",
        ),
      ],
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showAddStudentDialog(context),
      child: const Icon(Icons.add),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildEventSelector(),
        Expanded(child: _buildStudentList()),
      ],
    );
  }

  Widget _buildEventSelector() {
    if (_isLoadingEvents) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: LinearProgressIndicator(),
      );
    }

    final selectedEvent = _events.firstWhere(
            (e) => e['event_id'] == _selectedEventId,
        orElse: () => <String, dynamic>{});

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        key: _dropdownKey,
        onTap: _showDropdownMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade600),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedEvent['title'] ?? 'Chọn sự kiện',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIX: Phiên bản cuối cùng, tính toán chính xác vị trí và chiều rộng
  void _showDropdownMenu() {
    final renderBox = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    // showMenu có padding ngang bên trong, thường là 8.0 mỗi bên.
    // Chúng ta sẽ dùng nó để bù trừ.
    const double menuInternalHorizontalPadding = 8.0;

    showMenu<int>(
      context: context,
      // Cung cấp vị trí chính xác cho menu
      position: RelativeRect.fromLTRB(
        offset.dx,                      // Khoảng cách từ lề trái màn hình đến lề trái menu
        offset.dy + size.height,        // Khoảng cách từ lề trên màn hình đến lề trên menu
        screenWidth - offset.dx - size.width, // Khoảng cách từ lề phải menu đến lề phải màn hình
        0,                              // Không giới hạn lề dưới
      ),
      // Danh sách các item
      items: _events.map((event) {
        return PopupMenuItem<int>(
          value: event['event_id'],
          // Bỏ padding mặc định của PopupMenuItem để kiểm soát hoàn toàn
          padding: EdgeInsets.zero,
          child: Container(
            // Chiều rộng của item = chiều rộng ô chọn - padding nội bộ của menu
            width: size.width - (menuInternalHorizontalPadding * 2),
            // Thêm lại padding cho nội dung bên trong item
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              event['title'] ?? 'Sự kiện không tên',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
      elevation: 4.0, // Giảm elevation cho giống dropdown hơn
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
    ).then((value) {
      if (value != null && value != _selectedEventId) {
        setState(() {
          _selectedEventId = value;
        });
        _reloadStudents();
      }
    });
  }

  Widget _buildStudentList() {
    return FutureBuilder<List<StudentInEvent>>(
      future: _studentsInEventFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Chưa có sinh viên nào trong sự kiện này."),
          );
        }

        final students = snapshot.data!;
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            return _buildStudentCard(students[index]);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(StudentInEvent student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student.studentId?.toString() ?? '?'),
        ),
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: "MSSV: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: student.student?.studentCode ?? 'N/A'),
            ],
          ),
        ),
        subtitle: Text(
          "Trạng thái: ${student.status ?? 'Không rõ'}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: "Đánh dấu: Đã tham dự",
              onPressed: () => _handleStudentAction(_StudentAction.attended, student),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.orange),
              tooltip: "Đánh dấu: Đã hủy",
              onPressed: () => _handleStudentAction(_StudentAction.cancelled, student),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "Xóa khỏi sự kiện",
              onPressed: () => _handleStudentAction(_StudentAction.delete, student),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStudentDialog(BuildContext parentContext) async {
    FocusScope.of(parentContext).unfocus();

    final codeController = TextEditingController();
    int? dialogSelectedEventId;
    List<Map<String, dynamic>> activeEvents = [];

    try {
      activeEvents = await _service.fetchActiveEvents();
      if (_selectedEventId != null && activeEvents.any((e) => e['event_id'] == _selectedEventId)) {
        dialogSelectedEventId = _selectedEventId;
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(parentContext, "Lỗi tải sự kiện hoạt động: $e");
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Thêm sinh viên vào sự kiện"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: "Nhập mã sinh viên"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: dialogSelectedEventId,
                    decoration: const InputDecoration(
                      labelText: "Chọn sự kiện",
                      border: OutlineInputBorder(),
                    ),
                    items: activeEvents.map((event) {
                      return DropdownMenuItem<int>(
                        value: event['event_id'],
                        child: Text(event['title'] ?? 'Sự kiện không tên'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        dialogSelectedEventId = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                final studentCode = codeController.text.trim();
                if (studentCode.isEmpty || dialogSelectedEventId == null) {
                  NotificationService.showError(
                    dialogContext, "Vui lòng nhập mã sinh viên và chọn sự kiện.",
                  );
                  return;
                }
                try {
                  await _service.addStudentToEvent(dialogSelectedEventId!, studentCode);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  NotificationService.showSuccess(parentContext, "Thêm sinh viên thành công!");
                  if (dialogSelectedEventId == _selectedEventId) {
                    _reloadStudents();
                  }
                } catch (e) {
                  if (!mounted) return;
                  NotificationService.showError(dialogContext, e.toString());
                }
              },
              child: const Text("Thêm"),
            ),
          ],
        );
      },
    );

    codeController.dispose();
  }
}