import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/student_card_ocr_service.dart';
import '../widgets/home_screen.dart';
import '../widgets/main_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _authService = AuthService();
  final _ocrService = StudentCardOcrService();
  final _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _universities = const [];
  List<Map<String, dynamic>> _campuses = const [];
  int? _universityId;
  int? _campusId;
  bool _loadingUniversities = true;
  bool _loadingCampuses = false;
  bool _loading = false;
  bool _isScanning = false;
  bool _obscureText = true;
  String? _scanSummary;
  String? _detectedUniversityName;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      final universities = await _authService.getUniversities();
      if (!mounted) return;
      setState(() => _universities = universities);
    } catch (_) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Khong the tai danh sach truong. Hay thu lai sau.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingUniversities = false);
    }
  }

  Future<void> _loadCampuses(int universityId) async {
    setState(() {
      _loadingCampuses = true;
      _campuses = const [];
      _campusId = null;
    });
    try {
      final campuses = await _authService.getCampuses(universityId);
      if (!mounted) return;
      setState(() => _campuses = campuses);
    } catch (_) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Khong the tai danh sach co so. Hay thu lai sau.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCampuses = false);
    }
  }

  Future<void> _onUniversityChanged(int? universityId) async {
    setState(() {
      _universityId = universityId;
      _campusId = null;
      _campuses = const [];
    });
    if (universityId != null) await _loadCampuses(universityId);
  }

  Future<void> _scanStudentCard(ImageSource source) async {
    if (_isScanning) return;
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (image == null) return;

      setState(() => _isScanning = true);
      final result = await _ocrService.extract(await image.readAsBytes());
      if (!mounted) return;

      final matchedUniversityId = _findUniversityId(result.universityName);
      setState(() {
        if (result.fullName != null) _nameController.text = result.fullName!;
        if (result.studentCode != null) {
          _studentCodeController.text = result.studentCode!;
        }
        // Never keep or select an unrelated university after a failed match.
        _universityId = matchedUniversityId;
        _campusId = null;
        _campuses = const [];
        _detectedUniversityName = result.universityName;
        final populated = <String>[
          if (result.fullName != null) 'ho ten',
          if (result.studentCode != null) 'MSSV',
          if (matchedUniversityId != null) 'truong',
        ];
        _scanSummary = populated.isEmpty
            ? 'Da doc duoc the, hay nhap thong tin con thieu.'
            : 'Da dien ${populated.join(', ')}. Kiem tra lai truoc khi dang ky.';
      });
      if (matchedUniversityId != null) {
        await _loadCampuses(matchedUniversityId);
      }
      if (!mounted) return;
      NotificationService.showSuccess(context, 'Da quet the sinh vien.');
    } on StudentCardOcrException catch (error) {
      if (mounted) NotificationService.showError(context, error.message);
    } catch (_) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Khong the doc anh the. Hay thu lai voi anh sang va ro hon.',
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  int? _findUniversityId(String? ocrName) {
    if (ocrName == null || ocrName.trim().isEmpty) return null;
    final candidateTokens = _universityTokens(ocrName);
    if (candidateTokens.isEmpty) return null;

    for (final university in _universities) {
      final name = university['name']?.toString() ?? '';
      final universityTokens = _universityTokens(name);
      final commonTokens = candidateTokens.intersection(universityTokens);
      final isSingleDistinctiveMatch =
          candidateTokens.length == 1 && commonTokens.length == 1;
      final isUniversityAcronymMatch =
          universityTokens.length == 1 && commonTokens.length == 1;
      final isStrongMultiWordMatch = commonTokens.length >= 2 &&
          commonTokens.length / candidateTokens.length >= 0.6;
      if (isSingleDistinctiveMatch ||
          isUniversityAcronymMatch ||
          isStrongMultiWordMatch) {
        return university['university_id'] as int?;
      }
    }
    return null;
  }

  Set<String> _universityTokens(String value) {
    const ignored = {
      'truong',
      'dai',
      'hoc',
      'university',
      'college',
      'education',
      'of',
      'the',
      'and',
    };
    final tokens = value
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 1 && !ignored.contains(token))
        .toSet();
    // Preserve well-known acronyms even when Vietnamese accents are present.
    if (_normalize(value).contains('fpt')) tokens.add('fpt');
    return tokens;
  }

  String _normalize(String value) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final index = from.indexOf(character);
      buffer.write(index >= 0 ? to[index] : character);
    }
    return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate() || _universityId == null) {
      if (_universityId == null) {
        NotificationService.showError(context, 'Vui long chon truong cua ban.');
      }
      return;
    }
    if (_campuses.isNotEmpty && _campusId == null) {
      NotificationService.showError(context, 'Vui long chon co so cua ban.');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _authService.signUpStudent(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        studentCode: _studentCodeController.text.trim(),
        universityId: _universityId,
        campusId: _campusId,
      );
      if (!mounted) return;
      if (user['emailConfirmationRequired'] == true) {
        NotificationService.showSuccess(
          context,
          'Da tao tai khoan. Hay xac nhan email roi dang nhap.',
        );
        Navigator.pop(context);
        return;
      }

      NotificationService.showSuccess(
        context,
        'Dang ky tai khoan thanh cong! Chao mung ban den voi he thong.',
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            role: user['role'] as String,
            userId: user['id'] as int,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Dang ky khong thanh cong: ${_readableError(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('duplicate key') ||
        message.contains('already registered')) {
      return 'Email hoac ma sinh vien da ton tai.';
    }
    return message;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.green;
    return MainLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: BackButton(
                color: Colors.green.shade800,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Image.asset(
                'assets/icon/logo_app.png',
                width: 88,
                height: 88,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Dang ky sinh vien',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'AI doc the sinh vien de tu dong dien thong tin.',
              style: TextStyle(color: Colors.green.shade900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kiem tra va sua lai thong tin truoc khi dang ky.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning
                        ? null
                        : () => _scanStudentCard(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Chup the'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning
                        ? null
                        : () => _scanStudentCard(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Chon anh'),
                  ),
                ),
              ],
            ),
            if (_isScanning) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              const Center(child: Text('Dang doc thong tin tren the...')),
            ],
            if (_scanSummary != null) ...[
              const SizedBox(height: 10),
              Text(_scanSummary!,
                  style: TextStyle(color: Colors.green.shade800)),
            ],
            const SizedBox(height: 20),
            _input(
              controller: _nameController,
              label: 'Ho va ten',
              icon: Icons.person_outline,
              validator: _required('Vui long nhap ho va ten.'),
            ),
            const SizedBox(height: 14),
            _input(
              controller: _studentCodeController,
              label: 'Ma so sinh vien',
              icon: Icons.badge_outlined,
              textCapitalization: TextCapitalization.characters,
              validator: _required('Vui long nhap ma so sinh vien.'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              key: ValueKey(_universityId),
              initialValue: _universityId,
              isExpanded: true,
              decoration: _decoration('Truong dai hoc', Icons.school_outlined),
              hint: Text(
                  _loadingUniversities ? 'Dang tai truong...' : 'Chon truong'),
              items: _universities
                  .map(
                    (university) => DropdownMenuItem<int>(
                      value: university['university_id'] as int,
                      child: Text(
                        university['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _loadingUniversities ? null : _onUniversityChanged,
              validator: (value) =>
                  value == null ? 'Vui long chon truong.' : null,
            ),
            if (_detectedUniversityName != null && _universityId == null) ...[
              const SizedBox(height: 6),
              Text(
                'OCR doc truong: $_detectedUniversityName. Truong nay chua co trong danh sach.',
                style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
              ),
            ],
            if (_loadingCampuses) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            if (_campuses.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                key: ValueKey('campus-$_campusId'),
                initialValue: _campusId,
                isExpanded: true,
                decoration: _decoration('Co so', Icons.location_city_outlined),
                hint: const Text('Chon co so'),
                items: _campuses
                    .map(
                      (campus) => DropdownMenuItem<int>(
                        value: campus['campus_id'] as int,
                        child: Text(
                          campus['name']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _campusId = value),
                validator: (value) =>
                    value == null ? 'Vui long chon co so.' : null,
              ),
            ],
            const SizedBox(height: 14),
            _input(
              controller: _emailController,
              label: 'Email sinh vien',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui long nhap email.';
                }
                if (!value.contains('@')) {
                  return 'Email chua dung dinh dang.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: _decoration('Mat khau', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Mat khau can it nhat 6 ky tu.';
                }
                return null;
              },
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'DANG KY',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Da co tai khoan? Dang nhap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: _decoration(label, icon),
      validator: validator,
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  String? Function(String?) _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }
}
