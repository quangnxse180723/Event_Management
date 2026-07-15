import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- THÊM IMPORT SUPABASE
import 'package:student_attendance/data/models/student.dart';
import 'package:student_attendance/data/services/student_service.dart';
import 'package:student_attendance/data/services/notification_service.dart';
import 'package:student_attendance/data/services/university_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

// Import cái MainLayout (bản nâng cấp)
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _studentService = StudentService();
  List<Student> students = [];
  bool isLoading = true;

  // Các biến tìm kiếm và phân trang
  String _searchQuery = '';
  int _offset = 0;
  final int _limit = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  
  // thêm map để chọn trường
  List<Map<String, dynamic>> _universities = [];
  bool _isUniversitiesLoading = true;
  // ------------------------------------

  // --- Biến màu chung cho dễ chỉnh ---
  final Color primaryColor = Colors.green;
  final Color primaryColorDark = Colors.green[800]!;

  @override
  void initState() {
    super.initState();
    _loadStudents(refresh: true);
    _loadUniversities(); // <-- TẢI DANH SÁCH TRƯỜNG
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
        _loadStudents(refresh: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        isLoading = true;
        _offset = 0;
        _hasMore = true;
        students.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final data = await _studentService.getStudents(
        searchQuery: _searchQuery,
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        if (data.length < _limit) {
          _hasMore = false;
        }
        students.addAll(data);
        _offset += data.length;
        isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) NotificationService.showError(context, "Lỗi tải dữ liệu: $e");
    }
  }

  // --- HÀM MỚI (LẤY TRỰC TIẾP TỪ SUPABASE) ---
  Future<void> _loadUniversities() async {
    setState(() => _isUniversitiesLoading = true);
    final supabase = Supabase.instance.client;
    try {
      final universityList = await supabase
          .from('university')
          .select('university_id, name')
          .order('name');
      setState(() {
        _universities = List<Map<String, dynamic>>.from(universityList);
        _isUniversitiesLoading = false;
      });
    } catch (e) {
      setState(() => _isUniversitiesLoading = false);
      if (mounted) {
        NotificationService.showError(
            context, 'Lỗi tải danh sách trường: $e');
      }
    }
  }
  // ----------------------------------------

  // --- HÀM _showStudentForm ĐÃ "TÂN TRANG" VÀ SỬA LOGIC ---
  Future<void> _showStudentForm({Student? student}) async {
    final nameController = TextEditingController(text: student?.name ?? '');
    final codeController = TextEditingController(text: student?.studentCode ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // Dùng context cục bộ
    final currentContext = context;

    // --- HÀM TẠO DECORATION CHO TEXTFIELD CHO ĐỠ LẶP CODE ---
    InputDecoration buildInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color ?? primaryColorDark),
        filled: true,
        fillColor: Theme.of(context).cardColor,
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
      builder: (_) {
        // --- DÙNG STATEFULBUILDER ĐỂ CẬP NHẬT DROPDOWN TRONG DIALOG ---
        int? _dialogSelectedUniversityId = student?.universityId;
        int? _dialogSelectedCampusId = student?.campusId;
        List<Map<String, dynamic>> _dialogCampuses = [];
        bool _isDialogCampusesLoading = false;

        return StatefulBuilder(builder: (context, setDialogState) {
          // Hàm gọi API lấy danh sách campus
          Future<void> _loadCampusesForDialog(int uniId) async {
            setDialogState(() {
              _isDialogCampusesLoading = true;
              _dialogCampuses = [];
              // Không clear campusId nếu đây là lần load đầu tiên và uniId khớp với student.universityId
              if (student != null && uniId != student.universityId) {
                 _dialogSelectedCampusId = null;
              }
            });
            try {
              final cps = await UniversityService().getCampuses(uniId);
              setDialogState(() {
                _dialogCampuses = cps;
                _isDialogCampusesLoading = false;
                
                // Nếu campusId hiện tại không nằm trong danh sách mới, reset nó
                if (_dialogSelectedCampusId != null) {
                  bool exists = cps.any((c) => int.parse(c['campus_id'].toString()) == _dialogSelectedCampusId);
                  if (!exists) _dialogSelectedCampusId = null;
                }
              });
            } catch (e) {
              setDialogState(() { _isDialogCampusesLoading = false; });
            }
          }

          // Load campuses lần đầu nếu đã có trường
          if (_dialogSelectedUniversityId != null && _dialogCampuses.isEmpty && !_isDialogCampusesLoading) {
            _loadCampusesForDialog(_dialogSelectedUniversityId!);
          }
          return AlertDialog(
            // --- LÀM ĐẸP DIALOG ---
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Center(
              child: Text(
                student == null ? "Thêm sinh viên" : "Cập nhật sinh viên",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      decoration:
                      buildInputDecoration("Tên", Icons.person_outline)),
                  const SizedBox(height: 12), // Tăng khoảng cách
                  TextField(
                      controller: codeController,
                      decoration:
                      buildInputDecoration("Mã SV", Icons.badge_outlined)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                      buildInputDecoration("SĐT", Icons.phone_outlined)),
                  const SizedBox(height: 12),

                  // --- THAY BẰNG DROPDOWN  ---
                  _isUniversitiesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int>(
                    value: _dialogSelectedUniversityId,
                    decoration: buildInputDecoration(
                        "Trường Đại học", Icons.school_outlined),
                    items: _universities.map((uni) { // <-- Dùng List<Map>
                      return DropdownMenuItem<int>(
                        value: uni['university_id'] as int, // <-- Lấy từ Map
                        child: Text(uni['name'] ?? '', // <-- Lấy từ Map
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        _dialogSelectedUniversityId = value;
                      });
                      if (value != null) {
                        _loadCampusesForDialog(value);
                      }
                    },
                    validator: (value) =>
                    value == null ? 'Vui lòng chọn trường' : null,
                    isExpanded: true, // Cho phép tên dài
                  ),
                  const SizedBox(height: 12),
                  // --- DROPDOWN CHỌN CƠ SỞ ---
                  if (_dialogSelectedUniversityId != null)
                    _isDialogCampusesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _dialogSelectedCampusId,
                            decoration: buildInputDecoration("Cơ sở (Campus)", Icons.domain_outlined),
                            items: _dialogCampuses.map((c) {
                              return DropdownMenuItem<int>(
                                value: int.parse(c['campus_id'].toString()),
                                child: Text(c['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                _dialogSelectedCampusId = value;
                              });
                            },
                            validator: (value) => value == null ? 'Vui lòng chọn cơ sở' : null,
                            isExpanded: true,
                          ),
                  // ----------------------------------------

                  if (student == null) ...[
                    const SizedBox(height: 12),
                    TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: buildInputDecoration(
                            "Email", Icons.email_outlined)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: buildInputDecoration(
                            "Mật khẩu", Icons.lock_outline)),
                  ],
                ],
              ),
            ),
            actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            actions: [
              // --- LÀM ĐẸP NÚT BẤM ---
              TextButton(
                  onPressed: () => Navigator.pop(currentContext),
                  child: Text("HỦY", style: TextStyle(color: Colors.grey[700]))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
                onPressed: () async {

                  // --- KIỂM TRA ĐÃ CHỌN TRƯỜNG CHƯA ---
                  if (_dialogSelectedUniversityId == null) {
                    NotificationService.showError(
                        currentContext, 'Vui lòng chọn trường đại học.');
                    return; // Dừng lại nếu chưa chọn
                  }
                  // ------------------------------------

                  try {
                    if (student == null) {
                      final newStudent = Student.createForInsert(
                        name: nameController.text,
                        studentCode: codeController.text,
                        phone: phoneController.text,
                        universityId: _dialogSelectedUniversityId, // <-- LẤY ID TỪ DROPDOWN
                        campusId: _dialogSelectedCampusId,
                        createdAt: DateTime.now(),
                      );
                      await _studentService.addStudent(
                        newStudent,
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );

                      if (!mounted) return;
                      NotificationService.showSuccess(
                          currentContext, 'Thêm sinh viên thành công!');
                    } else {
                      final updatedStudent = Student(
                        studentId: student.studentId,
                        name: nameController.text,
                        studentCode: codeController.text,
                        phone: phoneController.text,
                        universityId: _dialogSelectedUniversityId,
                        campusId: _dialogSelectedCampusId,
                        userId: student.userId,
                        createdAt: student.createdAt,
                      );
                      await _studentService.updateStudent(updatedStudent);

                      if (!mounted) return;
                      NotificationService.showSuccess(
                          currentContext, 'Cập nhật thành công!');
                    }

                    if (!mounted) return;
                    Navigator.pop(currentContext);
                    _loadStudents(); // Tải lại danh sách sinh viên
                    // Không cần tải lại danh sách trường
                  } catch (e) {
                    print('❌ Lỗi bị bắt ở UI: $e');
                    if (mounted) {
                      NotificationService.showError(
                          currentContext, '❌ Lỗi: $e');
                    }
                  }
                },
                child: const Text("LƯU"),
              )
            ],
          );
        });
      },
    );
  }

  Future<void> _deleteStudent(Student s) async {
    // Dùng context cục bộ
    final currentContext = context;

    final confirm = await showDialog<bool>(
      context: currentContext,
      builder: (_) => AlertDialog(
        // --- LÀM ĐẸP DIALOG XÓA ---
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa sinh viên ${s.name}?"),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                    borderRadius: BorderRadius.circular(10))),
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
      NotificationService.showSuccess(
          currentContext, '✅ Import sinh viên từ Excel thành công!');
      _loadStudents(); // refresh danh sách

    } catch (e) {
      if (mounted) {
        Navigator.pop(currentContext); // tắt loading
        NotificationService.showError(currentContext, '❌ Lỗi khi import: $e');
      }
    }
  }

  // --- HÀM MỚI ĐỂ LẤY TÊN TRƯỜNG TỪ MAP ---
  String _getUniversityName(int? universityId) {
    if (universityId == null) return "Chưa cập nhật";
    if (_isUniversitiesLoading) return "Đang tải...";
    try {
      // Tìm tên trường trong danh sách Map đã tải
      final uni = _universities.firstWhere(
              (map) => map['university_id'] == universityId);
      return uni['name'] ?? 'ID không xác định';
    } catch (e) {
      // Nếu không tìm thấy (ví dụ: dữ liệu cũ)
      return "ID không xác định: $universityId";
    }
  }
  // -------------------------------------

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: AppBar(
        // Style của AppBar sẽ tự động lấy từ MainLayout
        // (chữ đen, đậm, nền trong suốt)
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên sinh viên...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchQuery = value.trim();
                _loadStudents(refresh: true);
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
                    itemCount: students.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == students.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final s = students[index];
          return Card(
            color: Theme.of(context).cardColor,
            shadowColor:
            Colors.green[900]?.withAlpha((255 * 0.1).round()),
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 16.0),
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
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Mã SV: ${s.studentCode}"),
                  if (s.phone.isNotEmpty) Text("SĐT: ${s.phone}"),

                  // --- HIỂN THỊ TÊN TRƯỜNG ---
                  Text("Trường: ${_getUniversityName(s.universityId)}"),
                  // --------------------------
                  if (s.campusId != null) Text("Campus ID: ${s.campusId}"),

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
          ),
        ],
      ),
    );
  }
}