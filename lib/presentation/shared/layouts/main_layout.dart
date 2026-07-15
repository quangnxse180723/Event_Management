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
  // --- THÊM THUỘC TÍNH NÀY ---
  final Widget? bottomNavigationBar;

  const MainLayout({
    super.key,
    required this.child,
    this.useScrollView = true,
    this.appBar, // <--- THÊM CÁI NÀY
    this.floatingActionButton, // <--- THÊM CÁI NÀY
    // --- THÊM VÀO CONSTRUCTOR ---
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    // --- ANH BỌC CÁI SCAFFOLD BẰNG THEME NÀY ---
    return Theme(
      // Dùng Theme.of(context).copyWith để giữ lại style gốc
      // và chỉ ghi đè những gì mình muốn (là cái appBarTheme)
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          // --- CHỈNH MẶC ĐỊNH CHO APPBAR ---
          backgroundColor: Colors.transparent, // Luôn trong suốt
          elevation: 0, // Luôn không có bóng

          // Màu cho ICON (như nút back, nút import)
          iconTheme: IconThemeData(color: textColor),
          // Màu cho ACTIONS (như nút import)
          actionsIconTheme: IconThemeData(color: textColor),

          // Style cho TIÊU ĐỀ (chữ "Quản lý Sinh viên")
          titleTextStyle: TextStyle(
            color: textColor, // <-- Chữ đổi theo theme
            fontWeight: FontWeight.bold, // <-- Chữ đậm
            fontSize: 20, // <-- Cỡ chữ 20 cho rõ
          ),
          // --- KẾT THÚC CHỈNH ---
        ),
      ),
      child: Scaffold(
        // Cho phép body nằm đè sau AppBar
        extendBodyBehindAppBar: true,

        // Dùng AppBar được truyền vào (nếu có)
        // AppBar này sẽ tự động lấy style từ AppBarTheme ở trên
        appBar: appBar,

        // Dùng FAB được truyền vào (nếu có)
        floatingActionButton: floatingActionButton,
        // --- SỬ DỤNG THUỘC TÍNH MỚI Ở ĐÂY ---
        bottomNavigationBar: bottomNavigationBar,

        body: Stack(
          children: [
            // Lớp 1: Nền Gradient
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                      : [
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
              painter: WavyHeaderPainter(isDark: isDark),
            ),

            // Lớp 2.5: Sóng dưới
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: Size(screenWidth, screenHeight * 0.2),
                painter: WavyFooterPainter(isDark: isDark),
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
      ),
    );
  }
}

// --- CLASS VẼ SÓNG TRÊN ---
// (Giữ nguyên)
class WavyHeaderPainter extends CustomPainter {
  final bool isDark;
  WavyHeaderPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Sóng 1 (sau, đậm hơn)
    var paint1 = Paint()
      ..color = isDark ? Colors.green[900]!.withOpacity(0.4) : Colors.green[300]!
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
      ..color = isDark ? Colors.green[800]!.withOpacity(0.3) : Colors.green[200]!
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
  final bool isDark;
  WavyFooterPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Sóng 1 (sau, đậm hơn)
    var paint1 = Paint()
      ..color = isDark ? Colors.green[900]!.withOpacity(0.4) : Colors.green[300]!
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
      ..color = isDark ? Colors.green[800]!.withOpacity(0.3) : Colors.green[200]!
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

