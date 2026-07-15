import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/data/services/notification_service.dart';
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({Key? key}) : super(key: key);

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      NotificationService.showError(context, 'Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (password.length < 6) {
      NotificationService.showError(context, 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (password != confirmPassword) {
      NotificationService.showError(context, 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;
      NotificationService.showSuccess(context, 'Cập nhật mật khẩu thành công! Vui lòng đăng nhập lại.');
      
      // Đăng xuất và đưa về màn hình Login
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, 'Lỗi cập nhật mật khẩu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: true,
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Nhập mật khẩu mới của bạn',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
