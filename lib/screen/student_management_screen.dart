import 'package:flutter/material.dart';
import '../../domain/entities/Student.dart';
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

  // --- Biến màu chung cho dễ chỉnh ---
  final Color primaryColor = Colors.green;
  final Color primaryColorDark = Colors.green[800]!;

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

  // --- HÀM _showStudentForm ĐÃ "TÂN TRANG" LẠI GIAO DIỆN ---
  Future<void> _showStudentForm({Student? student}) async {
    final nameController = TextEditingController(text: student?.name ?? '');
    final codeController = TextEditingController(text: student?.studentCode ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final uniController = TextEditingController(text: student?.universityId?.toString() ?? '');
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // Dùng context cục bộ
    final currentContext = context;

    // --- HÀM TẠO DECORATION CHO TEXTFIELD CHO ĐỠ LẶP CODE ---
    InputDecoration buildInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColorDark),
        filled: true,
        fillColor: Colors.green[50]?.withAlpha(150),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Bỏ viền
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2), // Viền khi focus
        ),
      );
    }
    // --------------------------------------------------------

    await showDialog(
      context: currentContext,
      builder: (_) => AlertDialog(
        // --- LÀM ĐẸP DIALOG ---
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0)
        ),
        backgroundColor: Colors.grey[50], // Màu nền dialog
        title: Center(
          child: Text(
            student == null ? "Thêm sinh viên" : "Cập nhật sinh viên",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColorDark),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: buildInputDecoration("Tên", Icons.person_outline)),
              const SizedBox(height: 12), // Tăng khoảng cách
              TextField(controller: codeController, decoration: buildInputDecoration("Mã SV", Icons.badge_outlined)),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: buildInputDecoration("SĐT", Icons.phone_outlined)),
              const SizedBox(height: 12),
              TextField(controller: uniController, keyboardType: TextInputType.number, decoration: buildInputDecoration("University ID", Icons.school_outlined)),
              if (student == null) ...[
                const SizedBox(height: 12),
                TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: buildInputDecoration("Email", Icons.email_outlined)),
                const SizedBox(height: 12),
                TextField(controller: passwordController, obscureText: true, decoration: buildInputDecoration("Mật khẩu", Icons.lock_outline)),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        actions: [
          // --- LÀM ĐẸP NÚT BẤM ---
          TextButton(
              onPressed: () => Navigator.pop(currentContext),
              child: Text("HỦY", style: TextStyle(color: Colors.grey[700]))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
            ),
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
                  NotificationService.showError(currentContext, ' Lỗi: $e');
                }
              }
            },
            child: const Text("LƯU"),
          )
        ],
      ),
    );
  }


  Future<void> _deleteStudent(Student s) async {
    // Dùng context cục bộ
    final currentContext = context;

    final confirm = await showDialog<bool>(
      context: currentContext,
      builder: (_) => AlertDialog(
        // --- LÀM ĐẸP DIALOG XÓA ---
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0)
        ),
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa sinh viên ${s.name}?"),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(currentContext, false),
            child: Text("HỦY", style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(currentContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                )
            ),
            child: const Text("XÓA"),
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


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryColorDark,
        title: const Text("Quản lý Sinh viên"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: "Import từ Excel",
            onPressed: _importStudents,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentForm(),
        tooltip: 'Thêm sinh viên',
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),

      useScrollView: false,

      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final s = students[index];
          return Card(
            color: Colors.white.withAlpha((255 * 0.9).round()),
            shadowColor: Colors.green[900]?.withAlpha((255 * 0.1).round()),
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                foregroundColor: primaryColorDark,
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

