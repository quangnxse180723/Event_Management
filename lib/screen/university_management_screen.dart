import 'package:flutter/material.dart';
import '../domain/entities/University.dart';
import '../services/university_service.dart';
import '../widgets/main_layout.dart'; // THÊM IMPORT NÀY

class UniversityScreen extends StatefulWidget {
  const UniversityScreen({Key? key}) : super(key: key);

  @override
  State<UniversityScreen> createState() => _UniversityScreenState();
}

class _UniversityScreenState extends State<UniversityScreen> {
  List<University> universities = [];
  bool isLoading = true;

  String _searchQuery = '';
  int _offset = 0;
  final int _limit = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
        _loadData(refresh: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        isLoading = true;
        _offset = 0;
        _hasMore = true;
        universities.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final data = await UniversityService().fetchUniversities(
        searchQuery: _searchQuery,
        limit: _limit,
        offset: _offset,
      );
      setState(() {
        if (data.length < _limit) {
          _hasMore = false;
        }
        universities.addAll(data);
        _offset += data.length;
        isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  int _generateNewId() {
    final existingIds = universities
        .map((u) => u.universityId ?? 0)
        .where((id) => id > 0)
        .toList()
      ..sort();

    int newId = 1;
    for (final id in existingIds) {
      if (id == newId) {
        newId++;
      } else if (id > newId) {
        break; // tìm được khoảng trống
      }
    }
    return newId;
  }

  void _showForm({University? uni}) {
    final nameCtrl = TextEditingController(text: uni?.name ?? "");
    final addressCtrl = TextEditingController(text: uni?.address ?? "");
    final contactCtrl = TextEditingController(text: uni?.contactInfo ?? "");

    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text(
                uni == null ? "Thêm Trường/Đơn vị" : "Sửa Trường/Đơn vị"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl,
                      decoration: InputDecoration(labelText: "Tên")),
                  TextField(controller: addressCtrl,
                      decoration: InputDecoration(labelText: "Địa chỉ")),
                  TextField(controller: contactCtrl,
                      decoration: InputDecoration(labelText: "Liên hệ")),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text("Hủy")),
              ElevatedButton(
                onPressed: () async {
                  if (uni == null) {
                    // Thêm mới
                    await UniversityService().addUniversity(
                      University(
                        name: nameCtrl.text,
                        address: addressCtrl.text,
                        contactInfo: contactCtrl.text,
                      ),
                    );
                  } else {
                    // Sửa (giữ nguyên)
                    await UniversityService().updateUniversity(
                      University(
                        universityId: uni.universityId,
                        name: nameCtrl.text,
                        address: addressCtrl.text,
                        contactInfo: contactCtrl.text,
                      ),
                    );
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData(refresh: true);
                  }
                },
                child: Text("Lưu"),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteUniversity(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa trường này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Xóa"),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await UniversityService().deleteUniversity(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xóa trường thành công!"),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi xóa trường: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Thay phần build của UniversityScreen
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: AppBar(
        title: Text("Quản lý Trường/Đơn vị"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: Icon(Icons.add),
      ),
      useScrollView: false, // ✅ Sử dụng false để dùng ListView
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trường/đơn vị...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchQuery = value.trim();
                _loadData(refresh: true);
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: universities.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == universities.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final uni = universities[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          isThreeLine: true,
                          title: Text(
                            uni.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(uni.address ?? "Không có địa chỉ"),
                              const SizedBox(height: 4),
                              Text(uni.contactInfo ?? "Không có thông tin liên hệ"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showForm(uni: uni),
                              ),
                              if (uni.universityId != null)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUniversity(uni.universityId!),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
