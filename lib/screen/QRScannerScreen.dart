import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../widgets/main_layout.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  bool _isNavigating = false; // ✅ Cờ ngăn chặn lỗi Double Pop (Thoát 2 lần)
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
      final data = jsonDecode(rawValue);
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
        'checkin_time': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        NotificationService.showSuccess(
          context,
          "🎉 Điểm danh thành công! Cảm ơn bạn đã tham gia.",
        );

        _isNavigating = true; // Khóa điều hướng để user không bấm Back giữa chừng được nữa

        // ✅ Tắt camera an toàn trước khi pop để tránh crash ngầm
        await _controller.stop();

        await Future.delayed(const Duration(milliseconds: 1500));

        // ✅ Kiểm tra canPop để tuyệt đối không bao giờ pop nhầm Navigator root
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, "❌ Lỗi khi quét mã QR: $e");
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      useScrollView: false,
      appBar: AppBar(
        // ✅ Quản lý nút Back thủ công để dọn dẹp bộ nhớ an toàn nếu user tự bấm thoát
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            if (_isNavigating) return;
            _isNavigating = true;
            await _controller.stop();
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
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
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
    );
  }
}