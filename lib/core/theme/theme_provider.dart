import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lớp này quản lý trạng thái theme của ứng dụng
class ThemeProvider with ChangeNotifier {
  // Key để lưu trữ lựa chọn theme vào bộ nhớ của điện thoại
  static const String _themeModeKey = 'themeMode';

  // Biến lưu trữ trạng thái theme hiện tại, mặc định là theo hệ thống
  ThemeMode _themeMode = ThemeMode.system;

  // Getter để các phần khác của ứng dụng có thể đọc được theme hiện tại
  ThemeMode get themeMode => _themeMode;

  // Constructor: Khi ThemeProvider được tạo, nó sẽ cố gắng tải theme đã lưu
  ThemeProvider() {
    _loadThemeMode();
  }

  // Hàm để thay đổi theme
  Future<void> setThemeMode(ThemeMode mode) async {
    // Nếu theme không thay đổi thì không làm gì cả
    if (mode == _themeMode) {
      return;
    }

    // Cập nhật trạng thái theme
    _themeMode = mode;

    // Thông báo cho tất cả các widget đang "lắng nghe" để chúng build lại với theme mới
    notifyListeners();

    // Lưu lựa chọn theme mới vào bộ nhớ
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeModeKey, _themeMode.index);
  }

  // Hàm nội bộ để tải theme đã được lưu từ lần sử dụng trước
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Đọc giá trị đã lưu, nếu không có thì dùng giá trị mặc định là của hệ thống (index = 0)
    final savedThemeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;

    // Chuyển đổi index đã lưu thành đối tượng ThemeMode
    _themeMode = ThemeMode.values[savedThemeIndex];

    // Thông báo cho các widget sau khi đã tải xong
    notifyListeners();
  }
}