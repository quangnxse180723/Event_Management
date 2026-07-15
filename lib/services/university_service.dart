import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/University.dart';

class UniversityService {
  final supabase = Supabase.instance.client;

  Future<void> addUniversity(University university) async {
    try {
      await supabase.from('university').insert({
        'name': university.name,
        'address': university.address,
        'contact_info': university.contactInfo,
      });
    } catch (e) {
      throw Exception("Insert failed: $e");
    }
  }

  Future<void> updateUniversity(University university) async {
    if (university.universityId == null) {
      throw Exception("universityId is required to update");
    }

    try {
      await supabase
          .from('university')
          .update({
            'name': university.name,
            'address': university.address,
            'contact_info': university.contactInfo,
          })
          .eq('university_id', university.universityId!);
    } catch (e) {
      throw Exception("Update failed: $e");
    }
  }

  Future<void> deleteUniversity(int id) async {
    try {
      // Thêm .select() để lấy về danh sách các bản ghi đã bị xóa.
      final deletedData = await supabase
          .from('university')
          .delete()
          .eq('university_id', id)
          .select();

      // Nếu không có bản ghi nào được trả về, có nghĩa là việc xóa không thành công.
      // Nguyên nhân phổ biến là do chính sách Row Level Security (RLS) của Supabase
      // không cho phép người dùng hiện tại thực hiện hành động xóa.
      if (deletedData.isEmpty) {
        throw Exception(
            "Không có mục nào được xóa. Vui lòng kiểm tra quyền truy cập hoặc ID của mục.");
      }
    } catch (e) {
      // Ném lại ngoại lệ để lớp UI có thể bắt và hiển thị thông báo.
      throw Exception("Xóa thất bại: $e");
    }
  }

  Future<List<University>> fetchUniversities({String? searchQuery, int limit = 15, int offset = 0}) async {
    try {
      var query = supabase.from('university').select();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }
      final data = await query.range(offset, offset + limit - 1).order('name', ascending: true);
      return (data as List)
          .map((json) => University.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception("Fetch failed: $e");
    }
  }

  // --- CRUD cho Campus ---
  Future<List<Map<String, dynamic>>> getCampuses(int universityId) async {
    try {
      final data = await supabase
          .from('university_campus')
          .select()
          .eq('university_id', universityId)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception("Lỗi lấy danh sách cơ sở: $e");
    }
  }

  Future<void> addCampus(int universityId, String name, String address) async {
    try {
      await supabase.from('university_campus').insert({
        'university_id': universityId,
        'name': name,
        'address': address,
      });
    } catch (e) {
      throw Exception("Thêm cơ sở thất bại: $e");
    }
  }

  Future<void> updateCampus(int campusId, String name, String address) async {
    try {
      await supabase
          .from('university_campus')
          .update({
            'name': name,
            'address': address,
          })
          .eq('campus_id', campusId);
    } catch (e) {
      throw Exception("Sửa cơ sở thất bại: $e");
    }
  }

  Future<void> deleteCampus(int campusId) async {
    try {
      final deletedData = await supabase
          .from('university_campus')
          .delete()
          .eq('campus_id', campusId)
          .select();
      if (deletedData.isEmpty) {
        throw Exception("Không thể xóa cơ sở. Có thể cơ sở này đang được tham chiếu.");
      }
    } catch (e) {
      throw Exception("Xóa cơ sở thất bại: $e");
    }
  }
}
