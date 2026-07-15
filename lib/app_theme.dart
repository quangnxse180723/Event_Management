import 'package:flutter/material.dart';

// --- BẢNG MÀU MỚI: DEEP PURPLE & BLUE ---

// --- MÀU SẮC CHO GIAO DIỆN SÁNG (Phiên bản "ban ngày") ---
class AppColors {
  static const Color primary = Color(0xFF3D5AFE); // Xanh dương đậm
  static const Color accent = Color(0xFF7C4DFF); // Tím đậm
  static const Color background = Color(0xFFF3F4F8); // Nền xám rất nhạt
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textLight = Color(0xFF6E6D7A);

  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;
    for (int i = 1; i < 10; i++) { strengths.add(0.1 * i); }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
  static final MaterialColor primarySwatch = createMaterialColor(primary);
}


// --- MÀU SẮC CHO GIAO DIỆN TỐI (Dựa trên hình ảnh) ---
class AppDarkColors {
  static const Color primary = Color(0xFF4A4AFF); // Xanh dương rực rỡ
  static const Color accent = Color(0xFFC74AEF); // Tím/Hồng rực rỡ
  static const Color background = Color(0xFF1A1A2E); // Nền tím than đậm
  static const Color card = Color(0xFF24243E); // Thẻ màu tím đậm hơn
  static const Color textDark = Color(0xFFF0F0F0); // Chữ trắng ngà
  static const Color textLight = Color(0xFF9E9ECB); // Chữ phụ màu tím nhạt
}


// --- HÀM XÂY DỰNG THEME ---
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.card,
    primarySwatch: AppColors.primarySwatch,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.background,
      surface: AppColors.card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.textDark,
      elevation: 0.5,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppDarkColors.primary,
    scaffoldBackgroundColor: AppDarkColors.background,
    cardColor: AppDarkColors.card,
    primarySwatch: AppColors.primarySwatch,
    colorScheme: const ColorScheme.dark(
      primary: AppDarkColors.primary,
      secondary: AppDarkColors.accent,
      background: AppDarkColors.background,
      surface: AppDarkColors.card,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, // Nền AppBar trong suốt
      foregroundColor: AppDarkColors.textDark,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppDarkColors.card,
      elevation: 2, // Tăng nhẹ elevation để có bóng đổ
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: AppDarkColors.textDark),
      titleSmall: TextStyle(color: AppDarkColors.textDark),
    ),
  );
}