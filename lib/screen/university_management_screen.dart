import 'package:flutter/material.dart';
import '../domain/entities/University.dart';
import '../services/university_service.dart';
import '../widgets/main_layout.dart';

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
        break;
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
      builder: (_) => AlertDialog(
        title: Text(uni == null ? "Thêm Trường/Đơn vị" : "Sửa Trường/Đơn vị"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Tên"),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: "Địa chỉ"),
              ),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: "Liên hệ"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            // Đảm bảo text hiển thị rõ trên cả Dark/Light mode
            child: Text("Hủy", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (uni == null) {
                await UniversityService().addUniversity(
                  University(
                    name: nameCtrl.text,
                    address: addressCtrl.text,
                    contactInfo: contactCtrl.text,
                  ),
                );
              } else {
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
            child: const Text("Lưu"),
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
            // Thích ứng màu Dark/Light Mode
            child: Text("Hủy", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Xóa"),
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: AppBar(
        title: const Text("Quản lý Trường/Đơn vị"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ✅ FIX TASK: Bổ sung nút Back để người dùng không bị kẹt lại
        leading: const BackButton(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      useScrollView: true,
      child: isLoading
          ? SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: const Center(child: CircularProgressIndicator()),
      )
          : Column(
        children: universities.map((uni) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            // Thích ứng Dark/Light Mode cho Card
            color: Theme.of(context).cardColor,
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
        }).toList(),
      ),
    );
  }
}