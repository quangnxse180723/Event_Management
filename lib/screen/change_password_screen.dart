import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/main_layout.dart';

// Giả sử bạn có AuthService để xử lý logic
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

// Enum để quản lý các bước trong màn hình
enum ChangePasswordStep {
  verifyCurrentPassword,
  enterNewPassword,
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ChangePasswordStep _currentStep = ChangePasswordStep.verifyCurrentPassword;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hàm xử lý việc xác minh mật khẩu hiện tại
  Future<void> _handleVerifyPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.verifyCurrentPassword(
        _currentPasswordController.text,
      );

      if (success && mounted) {
        setState(() {
          _currentStep = ChangePasswordStep.enterNewPassword;
        });
      }
    } on AuthException catch (_) {
      setState(() {
        _errorMessage = "Mật khẩu hiện tại không chính xác.";
      });
    } catch (_) {
      setState(() {
        _errorMessage = "Đã xảy ra lỗi không xác định. Vui lòng thử lại.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hàm xử lý việc cập nhật mật khẩu mới
  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Mật khẩu mới không khớp.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.updateUserPassword(_newPasswordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      setState(() {
        _errorMessage = "Đổi mật khẩu thất bại. Vui lòng thử lại.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Thay vì Scaffold riêng, bọc nội dung bên trong MainLayout
    return MainLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Giữ nguyên AppBar cũ bằng cách tạo thủ công (nút quay lại + tiêu đề)
      Row(
      children: [
      IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    ),
    const SizedBox(width: 8),
    const Text(
    "Đổi mật khẩu",
    style: TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    ),
    ),
    ],
    ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: _currentStep == ChangePasswordStep.verifyCurrentPassword
                ? _buildVerifyStep()
                : _buildNewPasswordStep(),
          ),
        ],
      ),
    );
  }

  // Widget cho bước xác minh mật khẩu hiện tại
  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Để đảm bảo an toàn, vui lòng xác nhận mật khẩu hiện tại của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _currentPasswordController,
          obscureText: !_isCurrentPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Mật khẩu hiện tại',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_isCurrentPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(
                      () => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
            ),
          ),
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Không được để trống' : null,
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
          onPressed: _handleVerifyPassword,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('XÁC MINH'),
        ),
      ],
    );
  }

  // Widget cho bước nhập mật khẩu mới
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Xác minh thành công! Vui lòng nhập mật khẩu mới.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.green),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_isNewPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_isNewPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(
                      () => _isNewPasswordVisible = !_isNewPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Không được để trống';
            if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu mới',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(
                      () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Không được để trống';
            if (value != _newPasswordController.text) {
              return 'Mật khẩu không khớp';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
          onPressed: _handleUpdatePassword,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('ĐỔI MẬT KHẨU'),
        ),
      ],
    );
  }
}
