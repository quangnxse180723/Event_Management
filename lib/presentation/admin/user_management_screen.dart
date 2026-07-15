import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/data/models/app_user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Client mặc định (dùng để đọc dữ liệu thông thường)
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ CLIENT ĐẶC QUYỀN ADMIN (Sử dụng Service Role Key để tạo/xóa tài khoản)
  final SupabaseClient _adminClient = SupabaseClient(
    'https://qegseyeqojeeuvkdtzxx.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFlZ3NleWVxb2plZXV2a2R0enh4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTM2Njg5MCwiZXhwIjoyMDk0OTQyODkwfQ.qx255OmIjcZLdC9J6nSR59gcIqIt6SZ0iswupN_Muxw',
  );

  List<AppUserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Lấy danh sách tài khoản
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('app_user')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _users = response.map((json) => AppUserModel.fromJson(json)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải người dùng: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog Thêm tài khoản mới
  void _showCreateUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'student';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Thêm tài khoản mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                        DropdownMenuItem(value: 'organizer', child: Text('Ban tổ chức')),
                        DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedRole = val);
                      },
                      decoration: const InputDecoration(labelText: 'Vai trò'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    setStateDialog(() => isSaving = true);
                    try {
                      // 1. Tạo user trong auth.users (Đã đổi sang _adminClient)
                      final authRes = await _adminClient.auth.admin.createUser(
                        AdminUserAttributes(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          emailConfirm: true,
                        ),
                      );

                      if (authRes.user != null) {
                        // 2. Thêm vào bảng app_user (Đã đổi sang _adminClient để tránh RLS)
                        await _adminClient.from('app_user').insert({
                          'auth_id': authRes.user!.id,
                          'email': emailController.text.trim(),
                          'role': selectedRole,
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          _fetchUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tạo tài khoản thành công!')),
                          );
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    } finally {
                      setStateDialog(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Tạo mới'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog Cập nhật vai trò (Role)
  void _showEditRoleDialog(AppUserModel user) {
    String selectedRole = user.role;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Sửa quyền: ${user.email}', style: const TextStyle(fontSize: 16)),
              content: DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                  DropdownMenuItem(value: 'organizer', child: Text('Ban tổ chức')),
                  DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                ],
                onChanged: (val) {
                  if (val != null) setStateDialog(() => selectedRole = val);
                },
                decoration: const InputDecoration(labelText: 'Vai trò'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    setStateDialog(() => isSaving = true);
                    try {
                      // Đã đổi sang _adminClient để cập nhật an toàn
                      await _adminClient
                          .from('app_user')
                          .update({'role': selectedRole})
                          .eq('user_id', user.userId);

                      if (mounted) {
                        Navigator.pop(context);
                        _fetchUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cập nhật vai trò thành công!')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    } finally {
                      setStateDialog(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Cập nhật'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Xác nhận và Xóa tài khoản tận gốc
  Future<void> _confirmDelete(AppUserModel user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa vĩnh viễn tài khoản ${user.email} khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Truy xuất auth_id trước khi xóa dữ liệu
                final userData = await _adminClient
                    .from('app_user')
                    .select('auth_id')
                    .eq('user_id', user.userId)
                    .maybeSingle();
                final authId = userData?['auth_id'];

                // 1. Xóa trong bảng app_user (Đã đổi sang _adminClient)
                await _adminClient.from('app_user').delete().eq('user_id', user.userId);

                // 2. Xóa tận gốc trong auth.users (Đã đổi sang _adminClient)
                if (authId != null) {
                  await _adminClient.auth.admin.deleteUser(authId);
                }

                _fetchUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa tài khoản tận gốc')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi xóa tài khoản: $e')),
                  );
                }
                _fetchUsers(); // Tải lại để đồng bộ state
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(user.role.substring(0, 1).toUpperCase()),
            ),
            title: Text(user.email, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Vai trò: ${user.role}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditRoleDialog(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(user),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}