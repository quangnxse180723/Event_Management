import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/main_layout.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

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
  final _majorController = TextEditingController();

  final _authService = AuthService();

  int? _universityId;
  int? _campusId;
  int? _studentId;
  bool _loading = true;
  bool _isNew = false;
  bool _editing = false;
  bool _loadingCampuses = false;

  List<Map<String, dynamic>> _universities = [];
  List<Map<String, dynamic>> _campuses = [];

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
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    try {
      final universityList = await supabase
          .from('university')
          .select('university_id, name')
          .order('name');

      if (mounted) {
        setState(() {
          _universities = List<Map<String, dynamic>>.from(universityList);
        });
      }

      final data = await supabase
          .from('student')
          .select('student_id, name, student_code, phone, university_id, campus_id, major')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

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
        _majorController.text = data['major'] ?? '';

        if (data['university_id'] != null) {
          int? fetchedUniId = int.tryParse(data['university_id'].toString());
          if (_universities.any((uni) => int.tryParse(uni['university_id'].toString()) == fetchedUniId)) {
            _universityId = fetchedUniId;
          }
        }
        
        if (data['campus_id'] != null) {
          _campusId = int.tryParse(data['campus_id'].toString());
        }

        _isNew = false;
        _loading = false;
      });
      
      if (_universityId != null) {
        await _loadCampuses(_universityId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        NotificationService.showError(context, 'Lỗi tải dữ liệu: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    final supabase = Supabase.instance.client;

    final name = _nameController.text.trim();
    final studentCode = _studentCodeController.text.trim();
    final phone = _phoneController.text.trim();
    final major = _majorController.text.trim();

    if (name.isEmpty || studentCode.isEmpty || phone.isEmpty) {
      NotificationService.showWarning(context, 'Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (_universityId == null) {
      NotificationService.showWarning(context, 'Bạn phải chọn trường đại học');
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ TỰ ĐỘNG LẤY EMAIL CỦA TÀI KHOẢN ĐANG ĐĂNG NHẬP
      final currentUser = supabase.auth.currentUser;
      final userEmail = currentUser?.email ?? '';

      if (_isNew) {
        final inserted = await supabase
            .from('student')
            .insert({
          'user_id': widget.userId,
          'email': userEmail, // THÊM EMAIL VÀO ĐÂY ĐỂ TRÁNH LỖI NOT NULL
          'name': name,
          'student_code': studentCode,
          'phone': phone,
          'major': major.isNotEmpty ? major : null,
          'university_id': _universityId,
          'campus_id': _campusId,
        })
            .select('student_id')
            .maybeSingle();

        if (inserted == null) {
          throw Exception('Không thể tạo hồ sơ.');
        }

        if (mounted) {
          setState(() {
            _studentId = inserted['student_id'] as int?;
            _isNew = false;
            _editing = false;
          });
          NotificationService.showSuccess(context, '🎉 Tạo hồ sơ thành công!');
        }
      } else {
        if (_studentId == null) throw Exception('Lỗi: Không tìm thấy ID Sinh viên.');

        final updated = await supabase
            .from('student')
            .update({
          'email': userEmail, // CẬP NHẬT CẢ EMAIL NẾU CẦN
          'name': name,
          'student_code': studentCode,
          'phone': phone,
          'major': major.isNotEmpty ? major : null,
          'university_id': _universityId,
          'campus_id': _campusId,
        })
            .eq('student_id', _studentId!)
            .select('student_id');

        if (mounted) {
          if (updated.isEmpty) {
            NotificationService.showError(context, 'Không tìm thấy hồ sơ để cập nhật');
          } else {
            setState(() => _editing = false);
            NotificationService.showSuccess(context, '✅ Cập nhật hồ sơ thành công!');
          }
        }
      }
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Lưu thất bại: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCampuses(int universityId) async {
    setState(() {
      _loadingCampuses = true;
      _campuses = [];
      // Keep _campusId if it's already set from fetch, otherwise null
    });
    try {
      final campuses = await _authService.getCampuses(universityId);
      if (!mounted) return;
      setState(() => _campuses = campuses);
    } catch (_) {
      // Ignore errors for campuses
    } finally {
      if (mounted) setState(() => _loadingCampuses = false);
    }
  }

  Future<void> _onUniversityChanged(int? universityId) async {
    setState(() {
      _universityId = universityId;
      _campusId = null;
      _campuses = [];
    });
    if (universityId != null) await _loadCampuses(universityId);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Thông tin cá nhân",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: (!_loading && !_editing)
          ? FloatingActionButton(
        onPressed: () => setState(() => _editing = true),
        child: const Icon(Icons.edit),
      )
          : null,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
            TextField(
              controller: _majorController,
              decoration: const InputDecoration(labelText: 'Ngành học'),
              readOnly: !_editing,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _universityId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Trường đại học'),
              items: _universities.map((uni) {
                final int uniId = int.tryParse(uni['university_id'].toString()) ?? 0;
                return DropdownMenuItem<int>(
                  value: uniId,
                  child: Text(
                    uni['name']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _editing ? _onUniversityChanged : null,
            ),
            if (_loadingCampuses) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_campuses.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _campuses.any((c) => int.tryParse(c['campus_id'].toString()) == _campusId) ? _campusId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cơ sở'),
                items: _campuses.map((campus) {
                  final int campusId = int.tryParse(campus['campus_id'].toString()) ?? 0;
                  return DropdownMenuItem<int>(
                    value: campusId,
                    child: Text(
                      campus['name']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _editing ? (value) => setState(() => _campusId = value) : null,
              ),
            ],
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