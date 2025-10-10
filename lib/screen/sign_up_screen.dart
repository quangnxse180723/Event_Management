import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/home_screen.dart';
import '../services/notification_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _handleSignUp() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signUpStudent(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        NotificationService.showSuccess(context, "Đăng ký tài khoản thành công! Chào mừng bạn tham gia hệ thống.");
        
        // Chờ 1 giây để hiển thị thông báo trước khi chuyển trang
        await Future.delayed(const Duration(seconds: 1));
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              role: user['role'],
              userId: user['id'],
            ),
          ),
        );
      }
    } catch (e) {
      NotificationService.showError(context, "Đăng ký thất bại: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản sinh viên")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email sinh viên"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _handleSignUp,
              child: const Text("Đăng ký"),
            ),
          ],
        ),
      ),
    );
  }
}