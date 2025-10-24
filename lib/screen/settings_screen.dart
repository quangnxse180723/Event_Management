import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/main_layout.dart';
import '../screen/login_screen.dart';
import '../theme_provider.dart';
import '../screen/change_password_screen.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;
  String _appVersion = 'Đang tải...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      NotificationService.showSuccess(context, "Đã đăng xuất thành công! Hẹn gặp lại bạn.");
      await Future.delayed(const Duration(seconds: 1));
      await supabase.auth.signOut();
      if (mounted) _logout(context);
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, "Lỗi khi đăng xuất: $e");
      }
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        NotificationService.showError(context, 'Không thể mở liên kết: $url');
      }
    }
  }

  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn giao diện'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Sáng'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    NotificationService.showInfo(context, "Đã chuyển sang giao diện sáng");
                  }
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Tối'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    NotificationService.showInfo(context, "Đã chuyển sang giao diện tối");
                  }
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Theo hệ thống'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    NotificationService.showInfo(context, "Đã chuyển về giao diện theo hệ thống");
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCurrentThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.system:
        return 'Hệ thống';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = supabase.auth.currentUser?.email ?? 'Không có thông tin';
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MainLayout(
      useScrollView: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 Header custom có icon quay lại + tiêu đề
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              const Text(
                "Cài đặt",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSectionHeader('Tài khoản'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(currentUserEmail),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text('Đăng xuất', style: TextStyle(color: Colors.red.shade700)),
            onTap: _handleLogout,
          ),
          const Divider(height: 32),

          _buildSectionHeader('Giao diện'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Chế độ'),
            subtitle: Text(_getCurrentThemeName(themeProvider.themeMode)),
            onTap: _showThemeDialog,
          ),

          const Divider(height: 32),

          _buildSectionHeader('Về ứng dụng'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Phiên bản'),
            subtitle: Text(_appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Chính sách bảo mật'),
            onTap: () => _launchURL('https://github.com/nemobutnoem'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
