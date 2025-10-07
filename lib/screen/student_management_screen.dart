import 'package:flutter/material.dart';
import '../../domain/entities/Student.dart';
import '../services/student_service.dart';
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

  /// Tính student_id tiếp theo (local)
  int _nextStudentId() {
    if (students.isEmpty) return 1;
    final ids = students.map((s) => s.studentId).toList();
    return ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _showStudentForm({Student? student}) async {
    final nameController = TextEditingController(text: student?.name ?? '');
    final codeController = TextEditingController(text: student?.studentCode ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final uniController = TextEditingController(text: student?.universityId?.toString() ?? '');
    final userController = TextEditingController(text: student?.userId?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student == null ? "Thêm sinh viên" : "Cập nhật sinh viên"),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Tên", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: "Mã SV", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "SĐT", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: uniController,
                  decoration: const InputDecoration(labelText: "University ID", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(labelText: "User ID", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final newStudent = Student(
                studentId: student?.studentId ?? _nextStudentId(),
                name: nameController.text,
                studentCode: codeController.text,
                phone: phoneController.text,
                universityId: int.tryParse(uniController.text),
                userId: int.tryParse(userController.text),
                createdAt: student?.createdAt ?? DateTime.now(),
              );

              if (student == null) {
                await _studentService.addStudent(newStudent);
              } else {
                await _studentService.updateStudent(newStudent);
              }

              if (context.mounted) Navigator.pop(context);
              _loadStudents();
            },
            child: const Text("Lưu"),
          ),
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
      await _studentService.deleteStudent(s.studentId);
      _loadStudents();
    }
  }

  Future<void> _importStudents() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final imported = await _studentService.importFromExcel(file);

      for (var s in imported) {
        await _studentService.addStudent(s);
      }

      _loadStudents();
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
}
