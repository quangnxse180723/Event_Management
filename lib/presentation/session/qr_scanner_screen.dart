import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/data/services/notification_service.dart';
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  bool _isNavigating = false; // Cờ ngăn chặn lỗi Double Pop
  final MobileScannerController _controller = MobileScannerController();

  Future<Map<String, int>> _getStudentInfo() async {
    final authId = Supabase.instance.client.auth.currentUser?.id;
    if (authId == null) throw Exception('Chưa đăng nhập');

    // Lấy user_id theo auth_id
    final appUser = await Supabase.instance.client
        .from('app_user')
        .select('user_id')
        .eq('auth_id', authId)
        .single();

    final int userId = appUser['user_id'];

    // Lấy student_id theo user_id
    final student = await Supabase.instance.client
        .from('student')
        .select('student_id')
        .eq('user_id', userId)
        .single();

    final int studentId = student['student_id'];

    return {'userId': userId, 'studentId': studentId};
  }

  Future<void> _handleBarcode(String rawValue) async {
    if (_isProcessing || _isNavigating) return;
    _isProcessing = true;

    try {
      // Try-catch bọc riêng phần decode để tránh sập app nếu quét nhầm mã QR văn bản thường
      final data = jsonDecode(rawValue);
      if (!data.containsKey('session_id')) {
        throw Exception('Mã QR không đúng định dạng của hệ thống');
      }

      final int sessionId = data['session_id'];
      final info = await _getStudentInfo();

      // Kiểm tra nếu đã điểm danh
      final existing = await Supabase.instance.client
          .from('session_checkin')
          .select()
          .eq('session_id', sessionId)
          .eq('student_id', info['studentId']!)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          NotificationService.showWarning(context, "⚠️ Bạn đã điểm danh phiên này rồi!");
        }
        return;
      }

      // Điểm danh mới
      await Supabase.instance.client.from('session_checkin').insert({
        'session_id': sessionId,
        'user_id': info['userId'],
        'student_id': info['studentId'],
        'method': 'QR',
      });

      if (mounted) {
        // Tắt camera an toàn
        await _controller.stop();
        if (!mounted) return;
        _isNavigating = true;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 80),
                    const SizedBox(height: 16),
                    const Text(
                      'Thành công!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bạn đã điểm danh thành công.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Đóng dialog
                        },
                        child: const Text('Hoàn tất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Sau khi đóng dialog, restart camera
        if (mounted) {
          _isNavigating = false;
          _controller.start();
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, "❌ Mã QR không hợp lệ hoặc lỗi kết nối.");
      }
    } finally {
      // Đặt trong cờ điều hướng để tránh mở khóa lặp lại khi đã quét xong
      if (!_isNavigating) {
        _isProcessing = false;
      }
    }
  }

  // Hàm xử lý thoát an toàn tập trung (Dùng chung cho cả nút Back UI và nút Back vật lý)
  Future<void> _safePop() async {
    if (_isNavigating) return;

    if (mounted && Navigator.canPop(context)) {
      _isNavigating = true;
      // Dừng camera dứt điểm trước khi đóng giao diện
      await _controller.stop();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope chặn nút Back cứng của điện thoại, ép hệ thống chạy qua hàm _safePop()
    // Lưu ý: Nếu đang dùng Flutter 3.16+, có thể thay WillPopScope bằng PopScope
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          await _safePop();
          return false; // Ngăn hệ thống tự pop mặc định vì đã xử lý bằng _safePop
        }
        return true; // Cho phép hệ thống xử lý thoát app/đóng tab
      },
      child: MainLayout(
        useScrollView: false,
        appBar: AppBar(
          leading: Navigator.canPop(context) ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _safePop,
          ) : null,
          title: const Text(
            "Quét mã QR",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camera Scanner
            MobileScanner(
              controller: _controller,
              errorBuilder: (BuildContext context, MobileScannerException error) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Không thể truy cập Camera.\nVui lòng cấp quyền trong Cài đặt hệ thống.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
              onDetect: (barcodeCapture) {
                final barcode = barcodeCapture.barcodes.first;
                if (barcode.rawValue != null && !_isProcessing) {
                  _handleBarcode(barcode.rawValue!);
                }
              },
            ),

            // Overlay khung quét
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              width: 250,
              height: 250,
            ),

            // Text hướng dẫn
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Đưa mã QR vào khung để quét",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}