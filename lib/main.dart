import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_attendance/screen/university_management_screen.dart';
import 'package:student_attendance/widgets/admin_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme_provider.dart';
import 'screen/login_screen.dart';
import 'app_theme.dart';
import 'services/notification_service.dart';

// Biến toàn cục để bắt sự kiện đổi mật khẩu khi app đang tắt (cold start)
bool isPasswordRecoveryEvent = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  await Supabase.initialize(
    url: 'https://qegseyeqojeeuvkdtzxx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFlZ3NleWVxb2plZXV2a2R0enh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNjY4OTAsImV4cCI6MjA5NDk0Mjg5MH0.3AUDhkm9ayuOj1FujviUgL6GkhOLa65-tRHEtljdYUU',
  );

  // Initialize Local Notifications and Realtime listener
  await NotificationService.initLocalNotifications();
  NotificationService.initRealtimeListener();

  // Lắng nghe ngay lập tức sau khi khởi tạo để không bị trượt mất sự kiện
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      isPasswordRecoveryEvent = true;
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Student Attendance',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildAppDarkTheme(),
          themeMode: themeProvider.themeMode,
          home: const LoginScreen(),
          routes: {
            // ** ĐÃ SỬA LỖI: Thêm kiểm tra null để tránh crash **
            '/admin_home': (context) {
              // Lấy tham số một cách an toàn
              final args = ModalRoute.of(context)?.settings.arguments;

              // Kiểm tra nếu tham số là null hoặc không đúng định dạng
              if (args == null || args is! Map<String, dynamic>) {
                // Hiển thị trang lỗi thay vì crash
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Lỗi: Không nhận được thông tin đăng nhập để vào trang admin.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final role = args['role'] as String?;
              final userId = args['userId'] as int?;

              // Kiểm tra nếu dữ liệu trong tham số không hợp lệ
              if (role == null || userId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Lỗi: Thông tin vai trò hoặc ID người dùng không hợp lệ.',
                       textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // ** ĐÃ SỬA: Sử dụng AdminHomeScreen mới **
              return AdminHomeScreen(role: role, userId: userId);
            },
            '/admin_management': (context) => const UniversityScreen(),
            // Thêm các routes khác của bạn tại đây
          },
        );
      },
    );
  }
}
