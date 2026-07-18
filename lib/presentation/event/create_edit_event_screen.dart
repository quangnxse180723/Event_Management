import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:student_attendance/core/theme/app_theme.dart';
import 'package:student_attendance/data/models/event_model.dart';
import 'package:student_attendance/data/services/api_service.dart';
import 'package:student_attendance/data/services/notification_service.dart';
import 'package:student_attendance/presentation/shared/layouts/main_layout.dart';

class CreateEditEventScreen extends StatefulWidget {
  final Event? event;
  final int userId;
  final String role;

  const CreateEditEventScreen({
    super.key,
    this.event,
    required this.userId,
    required this.role,
  });

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _organizerController; // ✅ Giữ 1 bản duy nhất
  late TextEditingController _imageUrlController;
  late TextEditingController _locationController;
  late TextEditingController _categoryController;
  DateTime? _startDate;
  DateTime? _endDate;

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isUploading = false;
  late final bool _isEditMode;

  List<Map<String, dynamic>> _organizers = [];
  int? _selectedOrganizerId;
  bool _isOrganizersLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.event != null;
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _organizerController = TextEditingController(text: widget.event?.organizer ?? '');
    _imageUrlController = TextEditingController(text: widget.event?.imageUrl ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _categoryController = TextEditingController(text: widget.event?.category ?? '');
    _startDate = widget.event?.startDate;
    _endDate = widget.event?.endDate;
    _selectedOrganizerId = widget.event?.userId;

    if (widget.role == 'admin') {
      _loadOrganizers();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _imageUrlController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizers() async {
    setState(() => _isOrganizersLoading = true);
    try {
      final data = await _apiService.fetchOrganizers();
      setState(() {
        _organizers = data;
        if (_isEditMode && _selectedOrganizerId != null) {
          if (!_organizers.any((org) => org['user_id'] == _selectedOrganizerId)) {
            _selectedOrganizerId = null;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Lỗi tải danh sách Organizer: $e');
      }
    } finally {
      if (mounted) setState(() => _isOrganizersLoading = false);
    }
  }



  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      
      final supabase = Supabase.instance.client;
      // Upload file lên bucket 'events'
      await supabase.storage.from('events').upload(fileName, file);
      
      // Lấy link public
      final imageUrl = supabase.storage.from('events').getPublicUrl(fileName);
      
      setState(() {
        _imageUrlController.text = imageUrl;
      });
      if (mounted) NotificationService.showSuccess(context, 'Tải ảnh lên thành công!');
    } catch (e) {
      if (mounted) NotificationService.showError(context, 'Lỗi tải ảnh: Hãy đảm bảo đã chạy script SQL tạo bucket "events". Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveForm() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;
    if (_startDate == null || _endDate == null) {
      NotificationService.showWarning(context, 'Vui lòng chọn ngày bắt đầu và kết thúc');
      return;
    }
    if (_endDate!.isBefore(_startDate!) || _endDate!.isAtSameMomentAs(_startDate!)) {
      NotificationService.showWarning(context, 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }
    if (widget.role == 'admin' && _selectedOrganizerId == null) {
      NotificationService.showWarning(context, 'Vui lòng chọn một Organizer để gán');
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'organizer': _organizerController.text,
      'image_url': _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
      'location': _locationController.text.isNotEmpty ? _locationController.text : null,
      'category': _categoryController.text.isNotEmpty ? _categoryController.text : null,
      'start_date': _startDate!.toIso8601String(),
      'end_date': _endDate!.toIso8601String(),
      'user_id': (widget.role == 'admin') ? _selectedOrganizerId : widget.userId,
    };

    try {
      if (_isEditMode) {
        await _apiService.updateEvent(widget.event!.id!, data);
      } else {
        await _apiService.createEvent(data);
      }
      if (!mounted) return;

      NotificationService.showSuccess(
        context,
        _isEditMode ? '✅ Cập nhật sự kiện thành công!' : '🎉 Tạo sự kiện mới thành công!',
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, 'Đã xảy ra lỗi: ${e.toString().replaceFirst("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      // ✅ Giữ nút Back hoàn chỉnh
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Chỉnh sửa sự kiện' : 'Tạo sự kiện mới',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên sự kiện'),
                validator: (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerController,
                decoration: const InputDecoration(labelText: 'Đơn vị tổ chức (VD: Khoa CNTT)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              if (widget.role == 'admin')
                _isOrganizersLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                  value: _selectedOrganizerId,
                  decoration: const InputDecoration(
                    labelText: 'Gán cho người phụ trách',
                    border: OutlineInputBorder(),
                  ),
                  items: _organizers.map((org) {
                    return DropdownMenuItem<int>(
                      value: org['user_id'] as int,
                      child: Text(org['email'].toString()),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedOrganizerId = v),
                  validator: (v) => v == null ? 'Vui lòng chọn người phụ trách' : null,
                ),
              if (widget.role == 'admin') const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Địa điểm tổng (Location)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Danh mục (Category) - VD: Công nghệ'),
                validator: (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Đường dẫn ảnh Cover (Tùy chọn)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(),
                        )
                      : ElevatedButton.icon(
                          onPressed: _pickAndUploadImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Tải ảnh'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ngày bắt đầu'),
                        child: Text(_startDate == null
                            ? 'Chọn ngày'
                            : DateFormat('dd/MM/yyyy').format(_startDate!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ngày kết thúc'),
                        child: Text(_endDate == null
                            ? 'Chọn ngày'
                            : DateFormat('dd/MM/yyyy').format(_endDate!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditMode ? 'CẬP NHẬT' : 'LƯU SỰ KIỆN',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}