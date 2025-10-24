import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Cần cho CustomPainter

import '../services/auth_service.dart';
import '../widgets/home_screen.dart';
import '../screen/sign_up_screen.dart';
import '../services/notification_service.dart';

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(
                  role: user['role'],
                  userId: user['id'],
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, "Đăng nhập thất bại: ${e.toString()}");
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

  // --- PHƯƠNG THỨC BUILD ĐÃ CẬP NHẬT (THÊM SÓNG DƯỚI) ---
  @override
  Widget build(BuildContext context) {
    Color primaryColor = Colors.green;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack( // Dùng Stack để xếp chồng
        children: [
          // Lớp 1: Nền Gradient
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[100]!,
                  Colors.green[50]!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Lớp 2: Sóng lượn TRÊN
          CustomPaint(
            size: Size(screenWidth, screenHeight * 0.4), // Chiều cao sóng = 40% màn hình
            painter: WavyHeaderPainter(),
          ),

          // LỚP 2.5: SÓNG LƯỢN DƯỚI
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size(screenWidth, screenHeight * 0.2), // Sóng dưới cao 20%
              painter: WavyFooterPainter(),
            ),
          ),

          // Lớp 3: Nội dung (Form)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Đẩy Logo xuống dưới sóng
                  const SizedBox(height: 140), // <-- ĐÃ TĂNG TỪ 120

                  Center(
                    child: Image.asset(
                      'assets/icon/logo_app.png',
                      width: 120, // <-- ĐÃ SỬA
                      height: 120, // <-- ĐÃ SỬA
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

                  // Ô Email
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

                  // Nút ĐĂNG NHẬP
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

                  // Nút ĐĂNG KÝ
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
                  const SizedBox(height: 40), // Thêm khoảng đệm ở dưới
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// --- CLASS VẼ SÓNG TRÊN ---
class WavyHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sóng 1 (sau, đậm hơn)
    var paint1 = Paint()
      ..color = Colors.green[300]!
      ..style = PaintingStyle.fill;

    var path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.quadraticBezierTo(
        size.width * 0.25, size.height * 0.4,
        size.width * 0.5, size.height * 0.3);
    path1.quadraticBezierTo(
        size.width * 0.75, size.height * 0.2,
        size.width, size.height * 0.25);
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Sóng 2 (trước, nhạt hơn)
    var paint2 = Paint()
      ..color = Colors.green[200]!
      ..style = PaintingStyle.fill;

    var path2 = Path();
    path2.moveTo(0, size.height * 0.25);
    path2.quadraticBezierTo(
        size.width * 0.3, size.height * 0.5,
        size.width * 0.55, size.height * 0.35);
    path2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.2,
        size.width, size.height * 0.3);
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// --- CLASS VẼ SÓNG DƯỚI (MỚI) ---
class WavyFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sóng 1 (sau, đậm hơn)
    var paint1 = Paint()
      ..color = Colors.green[300]!
      ..style = PaintingStyle.fill;

    var path1 = Path();
    path1.moveTo(0, size.height * 0.8); // Bắt đầu ở 80% chiều cao (gần đáy)
    path1.quadraticBezierTo(
        size.width * 0.25, size.height * 0.6, // Control point 1 (cong lên)
        size.width * 0.5, size.height * 0.7); // Điểm giữa
    path1.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, // Control point 2 (cong lên)
        size.width, size.height * 0.75); // Điểm cuối
    path1.lineTo(size.width, size.height); // Góc dưới phải
    path1.lineTo(0, size.height); // Góc dưới trái
    path1.close();
    canvas.drawPath(path1, paint1);

    // Sóng 2 (trước, nhạt hơn)
    var paint2 = Paint()
      ..color = Colors.green[200]!
      ..style = PaintingStyle.fill;

    var path2 = Path();
    path2.moveTo(0, size.height * 0.75); // Bắt đầu cao hơn sóng 1
    path2.quadraticBezierTo(
        size.width * 0.3, size.height * 0.5, // Control point 1
        size.width * 0.55, size.height * 0.65); // Điểm giữa
    path2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.8, // Control point 2
        size.width, size.height * 0.7); // Điểm cuối
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}