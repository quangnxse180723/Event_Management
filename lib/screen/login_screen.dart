import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/home_screen.dart';
import '../screen/sign_up_screen.dart';
import '../services/notification_service.dart';
import '../widgets/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;
  bool _obscureText = true;

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        NotificationService.showSuccess(context, "Đăng nhập thành công! Chào mừng bạn đến với hệ thống.");
        await Future.delayed(const Duration(seconds: 1));

        // ====== LOGIC ĐIỀU HƯỚNG THEO VAI TRÒ (ĐÃ SỬA) ======
        final userRole = user['role'];
        final userId = user['id']; // Lấy userId

        if (userRole == 'admin') {
          // Nếu là admin, điều hướng và gửi kèm tham số
          Navigator.pushReplacementNamed(
            context,
            '/admin_home',
            arguments: {
              'role': userRole,
              'userId': userId,
            },
          );
        } else {
          // Các vai trò khác giữ nguyên
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                role: userRole,
                userId: userId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, "Email hoặc mật khẩu không đúng! Vui lòng thử lại.");
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Colors.green;

    return MainLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 140),
          Center(
            child: Image.asset(
              'assets/icon/logo_app.png',
              width: 120,
              height: 120,
            ),
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              "Đăng nhập",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: "Email",
              prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2)
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: "Mật khẩu",
              prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2)
              ),
            ),
          ),
          const SizedBox(height: 40),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "ĐĂNG NHẬP",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              "Chưa có tài khoản?",
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                foregroundColor: primaryColor,
                backgroundColor: Colors.white.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "ĐĂNG KÝ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
