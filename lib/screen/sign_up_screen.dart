import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'dart:ui'; // <--- KHÔNG CẦN NỮA

import '../services/auth_service.dart';
import '../widgets/home_screen.dart';
import '../services/notification_service.dart';

// Import layout chung
import '../widgets/main_layout.dart';

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
  bool _obscureText = true;

  // --- HÀM _handleSignUp GIỮ NGUYÊN ---
  Future<void> _handleSignUp() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signUpStudent(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        NotificationService.showSuccess(context, "Đăng ký tài khoản thành công! Chào mừng bạn tham gia hệ thống.");

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
      if (mounted) {
        NotificationService.showError(context, "Đăng ký thất bại: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // --- HÀM dispose GIỮ NGUYÊN ---
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- PHƯƠNG THỨC BUILD ĐÃ GỌN LẠI ---
  @override
  Widget build(BuildContext context) {
    Color primaryColor = Colors.green;

    // KHÔNG CẦN screenHeight, screenWidth
    // KHÔNG CẦN Scaffold, Stack, Container, CustomPaint...

    // Chỉ cần gọi MainLayout và truyền nội dung form vào
    return MainLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nút Back
          Align(
            alignment: Alignment.topLeft,
            child: BackButton(
              color: Colors.green[800],
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Đẩy nội dung xuống
          const SizedBox(height: 40),

          // Logo
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
              "Đăng ký",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Ô Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: "Email sinh viên",
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

          // Ô Mật khẩu
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

          // Nút ĐĂNG KÝ
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
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
          const SizedBox(height: 30),

          // Nút Quay lại ĐĂNG NHẬP
          const Center(
            child: Text(
              "Đã có tài khoản?",
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
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
                "ĐĂNG NHẬP",
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

