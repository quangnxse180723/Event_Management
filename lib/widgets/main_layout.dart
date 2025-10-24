import 'package:flutter/material.dart';
import 'dart:ui'; // Cần cho CustomPainter

///
/// Widget layout chung (BẢN NÂNG CẤP)
/// Có thêm appBar, floatingActionButton và cho phép AppBar trong suốt
///
class MainLayout extends StatelessWidget {
  final Widget child;
  final bool useScrollView;
  final AppBar? appBar; // <--- THÊM CÁI NÀY
  final Widget? floatingActionButton; // <--- THÊM CÁI NÀY

  const MainLayout({
    super.key,
    required this.child,
    this.useScrollView = true,
    this.appBar, // <--- THÊM CÁI NÀY
    this.floatingActionButton, // <--- THÊM CÁI NÀY
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Cho phép body nằm đè sau AppBar
      extendBodyBehindAppBar: true,

      // Dùng AppBar được truyền vào (nếu có)
      appBar: appBar,

      // Dùng FAB được truyền vào (nếu có)
      floatingActionButton: floatingActionButton,

      body: Stack(
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

          // Lớp 2: Sóng trên
          CustomPaint(
            size: Size(screenWidth, screenHeight * 0.4),
            painter: WavyHeaderPainter(),
          ),

          // Lớp 2.5: Sóng dưới
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size(screenWidth, screenHeight * 0.2),
              painter: WavyFooterPainter(),
            ),
          ),

          // Lớp 3: Nội dung (child)
          // SafeArea sẽ tự động đẩy nội dung xuống dưới AppBar trong suốt
          SafeArea(
            child: useScrollView
                ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16.0),
              child: child,
            )
            // Sửa padding cho ListView (ngang 16, dọc 0)
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// --- CLASS VẼ SÓNG TRÊN ---
// (Giữ nguyên)
class WavyHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sóng 1 (sau, đậm hơn)
    var paint1 = Paint()
      ..color = Colors.green[300]!
      ..style = PaintingStyle.fill;

    var path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.4,
        size.width * 0.5, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.75, size.height * 0.2,
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
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.5,
        size.width * 0.55, size.height * 0.35);
    path2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.2, size.width, size.height * 0.3);
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

// --- CLASS VẼ SÓNG DƯỚI ---
// (Giữ nguyên)
class WavyFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sóng 1 (sau, đậm hơn)
    var paint1 = Paint()
      ..color = Colors.green[300]!
      ..style = PaintingStyle.fill;

    var path1 = Path();
    path1.moveTo(0, size.height * 0.8);
    path1.quadraticBezierTo(
        size.width * 0.25, size.height * 0.6, size.width * 0.5, size.height * 0.7);
    path1.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, size.width, size.height * 0.75);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Sóng 2 (trước, nhạt hơn)
    var paint2 = Paint()
      ..color = Colors.green[200]!
      ..style = PaintingStyle.fill;

    var path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.quadraticBezierTo(
        size.width * 0.3, size.height * 0.5, size.width * 0.55, size.height * 0.65);
    path2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.8, size.width, size.height * 0.7);
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

