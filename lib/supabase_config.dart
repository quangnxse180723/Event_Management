import 'package:supabase_flutter/supabase_flutter.dart';

/// Cấu hình kết nối Supabase/PostgreSQL.
/// Có thể ghi đè bằng `--dart-define=SUPABASE_URL=...` và
/// `--dart-define=SUPABASE_ANON_KEY=...` khi chạy ứng dụng.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qegseyeqojeeuvkdtzxx.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_B4j1A7-uME9Cp94afqb9sQ_rhwv1XbH',
  );
}

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
}
