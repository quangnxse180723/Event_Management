import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  int? _universityId;
  int? _studentId; // 👈 khóa chính student_id để update chính xác
  bool _loading = true;
  bool _isNew = false;
  bool _editing = false;

  List<Map<String, dynamic>> _universities = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    try {
      // Lấy danh sách trường
      final universityList = await supabase
          .from('university')
          .select('university_id, name')
          .order('name');

      // Lấy hồ sơ student theo user_id (lấy record mới nhất nếu có nhiều)
      final data = await supabase
          .from('student')
          .select('student_id, name, student_code, phone, university_id')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _universities = List<Map<String, dynamic>>.from(universityList);
      });

      if (data == null) {
        setState(() {
          _isNew = true;
          _editing = true; // Hồ sơ mới thì bật nhập
          _loading = false;
        });
        return;
      }

      // Gán dữ liệu khi đã có hồ sơ
      setState(() {
        _studentId = data['student_id'] as int;
        _nameController.text = data['name'] ?? '';
        _studentCodeController.text = data['student_code'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _universityId = data['university_id'] as int?;
        _isNew = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      NotificationService.showError(context, 'Lỗi tải dữ liệu: $e');
    }
  }

  Future<void> _saveProfile() async {
    final supabase = Supabase.instance.client;
    try {
      if (_universityId == null) {
        NotificationService.showWarning(context, 'Bạn phải chọn trường đại học');
        return;
      }

      if (_isNew) {
        // Insert mới
        final inserted = await supabase.from('student').insert({
          'user_id': widget.userId,
          'name': _nameController.text.trim(),
          'student_code': _studentCodeController.text.trim(),
          'phone': _phoneController.text.trim(),
          'university_id': _universityId,
        }).select('student_id').single(); // 👈 chỉ lấy student_id

        setState(() {
          _studentId = inserted['student_id'] as int;
          _isNew = false;
          _editing = false;
        });

        NotificationService.showSuccess(context, '🎉 Tạo hồ sơ thành công!');
      } else {
        print("👉 Updating student_id = $_studentId");

        // Update theo student_id
        final updated = await supabase.from('student').update({
          'name': _nameController.text.trim(),
          'student_code': _studentCodeController.text.trim(),
          'phone': _phoneController.text.trim(),
          'university_id': _universityId,
        }).eq('student_id', _studentId!).select('student_id');

        print("✅ Update result: $updated");

        if (updated.isEmpty) {
          NotificationService.showError(context, 'Không tìm thấy hồ sơ để cập nhật');
          return;
        }

        setState(() {
          _editing = false;
        });

        NotificationService.showSuccess(context, '✅ Cập nhật hồ sơ thành công!');
      }
    } catch (e) {
      NotificationService.showError(context, 'Lưu thất bại: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin cá nhân")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              readOnly: !_editing,
            ),
            TextField(
              controller: _studentCodeController,
              decoration: const InputDecoration(labelText: 'Mã sinh viên'),
              readOnly: !_editing,
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              readOnly: !_editing,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _universityId,
              decoration: const InputDecoration(labelText: 'Trường đại học'),
              items: _universities.map((uni) {
                return DropdownMenuItem<int>(
                  value: uni['university_id'] as int,
                  child: Text(uni['name'] ?? ''),
                );
              }).toList(),
              onChanged: _editing
                  ? (value) {
                setState(() {
                  _universityId = value;
                });
              }
                  : null,
            ),
            const SizedBox(height: 20),

            // Nút hành động
            _editing
                ? ElevatedButton(
              onPressed: _saveProfile,
              child: Text(_isNew ? 'Tạo hồ sơ' : 'Lưu'),
            )
                : ElevatedButton(
              onPressed: () {
                setState(() {
                  _editing = true;
                });
              },
              child: const Text("Sửa"),
            ),
          ],
        ),
      ),
    );
  }
}
