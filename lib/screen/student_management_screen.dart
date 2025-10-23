import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/Student.dart';
import '../services/app_user_service.dart';
import '../services/student_service.dart';
import '../services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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

  Future<void> _showStudentForm({Student? student}) async {
    final nameController = TextEditingController(text: student?.name ?? '');
    final codeController = TextEditingController(text: student?.studentCode ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final uniController = TextEditingController(text: student?.universityId?.toString() ?? '');
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student == null ? "Thêm sinh viên" : "Cập nhật sinh viên"),
        content: SingleChildScrollView(
          child: Column(
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {

              // ✨ BỌC BẰNG TRY...CATCH Ở ĐÂY ✨
              try {
                // (Optional) Anh có thể thêm dialog loading ở đây

                if (student == null) {
                  final newStudent = Student.createForInsert(
                    name: nameController.text,
                    studentCode: codeController.text,
                    phone: phoneController.text,
                    universityId: int.tryParse(uniController.text),
                    createdAt: DateTime.now(),
                  );

                  // Hàm này sẽ ném lỗi nếu email trùng
                  await _studentService.addStudent(
                    newStudent,
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );

                  // Nếu không lỗi, thông báo thành công
                  if (context.mounted) {
                    NotificationService.showSuccess(context, 'Thêm sinh viên thành công!');
                  }

                } else {
                  // Logic update (anh cũng nên bọc try...catch cho cả update)
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

                  if (context.mounted) {
                    NotificationService.showSuccess(context, 'Cập nhật thành công!');
                  }
                }

                // Nếu mọi thứ êm đẹp: đóng dialog và tải lại danh sách
                if (context.mounted) Navigator.pop(context);
                _loadStudents();

              } catch (e) {
                // ✨ BẮT LỖI TỪ SERVICE VÀ HIỂN THỊ RA CHO NGƯỜI DÙNG ✨
                print('❌ Lỗi bị bắt ở UI: $e');
                if (context.mounted) {
                  // Hiển thị lỗi (ví dụ: "Email này đã tồn tại")
                  NotificationService.showError(context, '❌ Lỗi: $e');
                }
              }
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }




  Future<void> _deleteStudent(Student s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa sinh viên ${s.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _studentService.deleteStudent(s.studentId);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Đã xóa ${s.name}');
        }
        _loadStudents();
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, '❌ Lỗi khi xóa: $e');
        }
      }
    }
  }

  Future<void> _importStudents() async {
    // Mở file picker để chọn Excel file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.isEmpty) return; // User cancel
    final filePath = result.files.single.path!;
    final file = File(filePath);

    // Hiển thị dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _studentService.importStudentsFromExcel(file);
      if (context.mounted) {
        Navigator.pop(context); // tắt loading
        NotificationService.showSuccess(context, '✅ Import sinh viên từ Excel thành công!');
        _loadStudents(); // refresh danh sách
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // tắt loading
        NotificationService.showError(context, '❌ Lỗi khi import: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Sinh viên"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: "Import từ Excel",
            onPressed: _importStudents,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final s = students[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                s.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentForm(),
        tooltip: 'Thêm sinh viên',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showStudentCredentials(String email, String password) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thông tin đăng nhập sinh viên"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Email: $email"),
            Text("Password: $password"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

}
