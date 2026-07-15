import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';
import 'package:student_attendance/data/services/notification_service.dart';

class OrganizerProfileScreen extends StatefulWidget {
  final int userId;
  const OrganizerProfileScreen({super.key, required this.userId});

  @override
  State<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends State<OrganizerProfileScreen> {
  final _orgNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = true;
  bool _isNew = false;
  bool _editing = false;
  int? _organizerId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    try {
      // Truy vấn thông tin organizer theo user_id
      final data = await supabase
          .from('organizer')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (data == null) {
        setState(() {
          _isNew = true;
          _editing = true;
          _loading = false;
        });
        return;
      }

      setState(() {
        _organizerId = data['id'] as int?;
        _orgNameController.text = data['organization_name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _isNew = false;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Chưa có bảng organizer hoặc lỗi rls: $e');
    }
  }

  Future<void> _saveProfile() async {
    final supabase = Supabase.instance.client;

    final orgName = _orgNameController.text.trim();
    final phone = _phoneController.text.trim();
    final description = _descriptionController.text.trim();

    if (orgName.isEmpty || phone.isEmpty) {
      NotificationService.showWarning(context, 'Vui lòng điền tên đơn vị và số điện thoại');
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isNew) {
        await supabase.from('organizer').insert({
          'user_id': widget.userId,
          'organization_name': orgName,
          'phone': phone,
          'description': description,
        });
        setState(() {
          _isNew = false;
          _editing = false;
        });
        NotificationService.showSuccess(context, '🎉 Tạo hồ sơ Ban tổ chức thành công!');
      } else {
        await supabase.from('organizer').update({
          'organization_name': orgName,
          'phone': phone,
          'description': description,
        }).eq('user_id', widget.userId);

        setState(() {
          _editing = false;
        });
        NotificationService.showSuccess(context, '✅ Cập nhật hồ sơ thành công!');
      }
    } catch (e) {
      NotificationService.showError(context, 'Lưu thất bại: $e');
    } finally {
      setState(() => _loading = false);
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
        // Đã tích hợp sẵn BackButton chuẩn mực
        leading: const BackButton(),
        title: const Text(
          "Hồ sơ Ban tổ chức",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: !_editing
          ? FloatingActionButton(
        onPressed: () => setState(() => _editing = true),
        child: const Icon(Icons.edit),
      )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thông tin chi tiết giúp sinh viên dễ dàng nhận diện và liên hệ với đơn vị tổ chức của bạn.',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Tên Đơn vị / CLB / Khoa',
                border: OutlineInputBorder(),
              ),
              readOnly: !_editing,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại liên hệ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              readOnly: !_editing,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết (Địa chỉ, vai trò...)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              readOnly: !_editing,
            ),
            const SizedBox(height: 24),
            if (_editing)
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: Text(_isNew ? 'Tạo hồ sơ' : 'Lưu thay đổi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}