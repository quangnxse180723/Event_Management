import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class DatabaseInitService {
  final _supabase = Supabase.instance.client;

  /// Gọi hàm RPC trên Supabase để tự động tạo bảng nếu chưa có.
  /// Lưu ý: Bạn cần phải tạo hàm RPC `init_database_tables` trên SQL Editor của Supabase trước.
  Future<bool> initializeTables() async {
    try {
      // Gọi hàm RPC có tên là 'init_database_tables'
      await _supabase.rpc('init_database_tables');
      
      if (kDebugMode) {
        print('Khởi tạo bảng thành công!');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi khởi tạo bảng: $e');
      }
      return false;
    }
  }
}
