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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final data = await UniversityService().fetchUniversities();
    setState(() {
      universities = data;
      isLoading = false;
    });
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
                    _loadData();
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
      _loadData();
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
      useScrollView: true, // ✅ Sử dụng SingleChildScrollView
      child: isLoading
          ? SizedBox(
        height: MediaQuery
            .of(context)
            .size
            .height * 0.5,
        child: Center(child: CircularProgressIndicator()),
      )
          : Column(
        children: universities.map((uni) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              isThreeLine: true,
              title: Text(
                uni.name,
                style: TextStyle(fontWeight: FontWeight.bold),
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
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showForm(uni: uni),
                  ),
                  if (uni.universityId != null)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUniversity(uni.universityId!),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
