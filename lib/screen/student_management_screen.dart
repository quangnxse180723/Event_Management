import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // <-- Đã xóa import thừa
import '../../domain/entities/Student.dart';
// import '../services/app_user_service.dart'; // <-- Đã xóa import thừa
import '../services/student_service.dart';
import '../services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

// Import cái MainLayout (bản nâng cấp)
import '../widgets/main_layout.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _studentService = StudentService();
  List<Student> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    final data = await _studentService.getStudents();
    setState(() {
      students = data;
      isLoading = false;
    });
  }

  // --- HÀM _showStudentForm ĐÃ SỬA LỖI NGOẶC ---
  Future<void> _showStudentForm({Student? student}) async {
    final nameController = TextEditingController(text: student?.name ?? '');
    final codeController = TextEditingController(text: student?.studentCode ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final uniController = TextEditingController(text: student?.universityId?.toString() ?? '');
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // Dùng context cục bộ
    final currentContext = context;

    await showDialog(
      context: currentContext,
      builder: (_) => AlertDialog(
        title: Text(student == null ? "Thêm sinh viên" : "Cập nhật sinh viên"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Giúp Column co lại
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên", border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: "Mã SV", border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "SĐT", border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: uniController, decoration: const InputDecoration(labelText: "University ID", border: OutlineInputBorder())),
              if (student == null) ...[
                const SizedBox(height: 8),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder())),
              ],
            ],
          ),
        ),
        actions: [ // <-- Cái 'actions' này phải nằm trong AlertDialog
          TextButton(onPressed: () => Navigator.pop(currentContext), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              try {
                if (student == null) {
                  final newStudent = Student.createForInsert(
                    name: nameController.text,
                    studentCode: codeController.text,
                    phone: phoneController.text,
                    universityId: int.tryParse(uniController.text),
                    createdAt: DateTime.now(),
                  );
                  await _studentService.addStudent(
                    newStudent,
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );

                  if (!mounted) return;
                  NotificationService.showSuccess(currentContext, 'Thêm sinh viên thành công!');

                } else {
                  final updatedStudent = Student(
                    studentId: student.studentId,
                    name: nameController.text,
                    studentCode: codeController.text,
                    phone: phoneController.text,
                    universityId: int.tryParse(uniController.text),
                    userId: student.userId,
                    createdAt: student.createdAt,
                  );
                  await _studentService.updateStudent(updatedStudent);

                  if (!mounted) return;
                  NotificationService.showSuccess(currentContext, 'Cập nhật thành công!');
                }

                if (!mounted) return;
                Navigator.pop(currentContext);
                _loadStudents();

              } catch (e) {
                print('❌ Lỗi bị bắt ở UI: $e');
                if (mounted) {
                  NotificationService.showError(currentContext, '❌ Lỗi: $e');
                }
              }
            },
            child: const Text("Lưu"),
          )
        ],
      ), // <-- Dấu ) của AlertDialog
    ); // <-- Dấu ); của showDialog
  }


  Future<void> _deleteStudent(Student s) async {
    // Dùng context cục bộ
    final currentContext = context;

    final confirm = await showDialog<bool>(
      context: currentContext,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa sinh viên ${s.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(currentContext, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(currentContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _studentService.deleteStudent(s.studentId);

        if (!mounted) return;
        NotificationService.showSuccess(currentContext, 'Đã xóa ${s.name}');

        _loadStudents();
      } catch (e) {
        if (mounted) {
          NotificationService.showError(currentContext, '❌ Lỗi khi xóa: $e');
        }
      }
    }
  }

  Future<void> _importStudents() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path!;
    final file = File(filePath);

    if (!mounted) return;
    final currentContext = context;

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _studentService.importStudentsFromExcel(file);

      if (!mounted) return;
      Navigator.pop(currentContext); // tắt loading
      NotificationService.showSuccess(currentContext, '✅ Import sinh viên từ Excel thành công!');
      _loadStudents(); // refresh danh sách

    } catch (e) {
      if (mounted) {
        Navigator.pop(currentContext); // tắt loading
        NotificationService.showError(currentContext, '❌ Lỗi khi import: $e');
      }
    }
  }

  // --- XÓA HÀM _showStudentCredentials KHÔNG DÙNG ---


  // --- HÀM BUILD ĐÃ CHUYỂN SANG DÙNG MAINLAYOUT ---
  @override
  Widget build(BuildContext context) {
    // BỎ Scaffold đi
    return MainLayout(
      // Truyền AppBar vào MainLayout
      appBar: AppBar(
        // Làm cho AppBar trong suốt
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Đổi màu icon/chữ thành màu đen/xanh đậm cho dễ đọc trên nền sáng
        foregroundColor: Colors.green[800],
        title: const Text("Quản lý Sinh viên"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload), // Màu tự động theo foregroundColor
            tooltip: "Import từ Excel",
            onPressed: _importStudents,
          ),
        ],
      ),

      // Truyền FAB vào MainLayout
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentForm(),
        tooltip: 'Thêm sinh viên',
        backgroundColor: Colors.green[600], // Màu xanh lá cho FAB
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),

      // Đặt useScrollView = false vì mình dùng ListView
      useScrollView: false,

      // Đây là nội dung (child)
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        // Thêm padding trên để nó không bị dính vào AppBar
        // và padding dưới để không bị FAB che
        padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final s = students[index];
          return Card(
            // Card hơi mờ để thấy nền sóng
            color: Colors.white.withAlpha((255 * 0.9).round()),
            shadowColor: Colors.green[900]?.withAlpha((255 * 0.1).round()),
            margin: const EdgeInsets.symmetric(vertical: 8), // Bỏ margin ngang (vì MainLayout đã có)
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[800],
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                s.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Mã SV: ${s.studentCode}"),
                  if (s.phone.isNotEmpty) Text("SĐT: ${s.phone}"),
                  if (s.universityId != null) Text("University ID: ${s.universityId}"),
                  if (s.userId != null) Text("User ID: ${s.userId}"),
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _showStudentForm(student: s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteStudent(s),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

