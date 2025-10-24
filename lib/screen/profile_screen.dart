import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/main_layout.dart';
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
  int? _studentId;
  bool _loading = true;
  bool _isNew = false;
  bool _editing = false;

  List<Map<String, dynamic>> _universities = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    try {
      // Lấy danh sách trường
      final universityList = await supabase
          .from('university')
          .select('university_id, name')
          .order('name');

      // Lấy hồ sơ student theo user_id
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
          _editing = true;
          _loading = false;
        });
        return;
      }

      setState(() {
        _studentId = data['student_id'] as int?;
        _nameController.text = data['name'] ?? '';
        _studentCodeController.text = data['student_code'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _universityId = data['university_id'] as int?;
        _isNew = false;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      NotificationService.showError(context, 'Lỗi tải dữ liệu: $e');
    }
  }

  Future<void> _saveProfile() async {
    final supabase = Supabase.instance.client;

    final name = _nameController.text.trim();
    final studentCode = _studentCodeController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || studentCode.isEmpty || phone.isEmpty) {
      NotificationService.showWarning(context, 'Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (_universityId == null) {
      NotificationService.showWarning(context, 'Bạn phải chọn trường đại học');
      return;
    }

    try {
      if (_isNew) {
        // Insert mới
        final inserted = await supabase
            .from('student')
            .insert({
          'user_id': widget.userId,
          'name': name,
          'student_code': studentCode,
          'phone': phone,
          'university_id': _universityId,
        })
            .select('student_id')
            .single();

        setState(() {
          _studentId = inserted['student_id'] as int?;
          _isNew = false;
          _editing = false;
        });

        NotificationService.showSuccess(context, '🎉 Tạo hồ sơ thành công!');
      } else {
        // Update theo student_id
        final updated = await supabase
            .from('student')
            .update({
          'name': name,
          'student_code': studentCode,
          'phone': phone,
          'university_id': _universityId,
        })
            .eq('student_id', _studentId!)
            .select('student_id');

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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MainLayout(
      useScrollView: true,
      appBar: AppBar(
        title: const Text(
          "Thông tin cá nhân",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: !_editing
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _editing = true;
          });
        },
        child: const Icon(Icons.edit),
      )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              readOnly: !_editing,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _studentCodeController,
              decoration: const InputDecoration(labelText: 'Mã sinh viên'),
              readOnly: !_editing,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
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
                  ? (value) => setState(() => _universityId = value)
                  : null,
            ),
            const SizedBox(height: 24),
            if (_editing)
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: Text(_isNew ? 'Tạo hồ sơ' : 'Lưu thay đổi'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
