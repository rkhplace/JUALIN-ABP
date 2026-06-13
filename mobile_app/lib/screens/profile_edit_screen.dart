import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/ui/frosted_app_bar.dart';
import '../widgets/ui/logo_loader.dart';
import '../widgets/profile/profile_form.dart';
import '../widgets/profile/profile_image_uploader.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _bioController = TextEditingController();

  User? _user;
  File? _selectedProfileImage;
  String _gender = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _birthdayController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _profileService.getProfile();
      if (user == null) {
        throw Exception('Profil tidak ditemukan. Silakan login ulang.');
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
        _regionController.text = user.region;
        _cityController.text = user.city;
        _birthdayController.text = user.birthday;
        _bioController.text = user.bio;
        _gender = user.gender;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickBirthday() async {
    final initialDate = DateTime.tryParse(_birthdayController.text) ??
        DateTime(DateTime.now().year - 20);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE83030),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFFE83030),
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              dayShape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              todayBorder: const BorderSide(color: Color(0xFFE83030)),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE83030),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null) return;
    _birthdayController.text =
        '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      setState(() {
        _selectedProfileImage = File(picked.path);
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = source == ImageSource.camera
            ? 'Gagal membuka kamera. Pastikan izin kamera aktif.'
            : 'Gagal memilih foto dari galeri.';
      });
    }
  }

  Future<void> _showProfileImageOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await _pickProfileImage(source);
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _profileService.updateProfile(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender.isEmpty ? null : _gender,
        birthday: _birthdayController.text.trim().isEmpty
            ? null
            : _birthdayController.text.trim(),
        region: _regionController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        profilePicture: _selectedProfileImage,
      );

      await _authService.me(persist: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      showAppBar: false,
      bottomNavigationBar: _isLoading || _user == null ? null : _buildSaveBar(),
      body: _isLoading
          ? const JualinLogoLoader(size: 64)
          : _errorMessage != null && _user == null
              ? _buildError()
              : SafeArea(
                  bottom: false,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        _buildEditHeader(),
                        const SizedBox(height: 16),
                        _buildProfilePhotoPicker(),
                        const SizedBox(height: 20),
                        if (_errorMessage != null) ...[
                          _buildErrorBanner(_errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        _buildSection(
                          title: 'Informasi Dasar',
                          subtitle: 'Data utama yang terlihat di akun Jualin.',
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nama Pengguna',
                              icon: Icons.person_outline,
                              validator: (value) =>
                                  value == null || value.trim().length < 3
                                      ? 'Nama minimal 3 karakter'
                                      : null,
                            ),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  value == null || !value.contains('@')
                                      ? 'Email tidak valid'
                                      : null,
                            ),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Nomor HP',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                final phone = value?.trim() ?? '';
                                if (phone.isEmpty) return null;
                                if (!RegExp(r'^[0-9+ -]{8,20}$')
                                    .hasMatch(phone)) {
                                  return 'Nomor HP tidak valid';
                                }
                                return null;
                              },
                            ),
                            _buildGenderField(),
                            _buildTextField(
                              controller: _birthdayController,
                              label: 'Tanggal Lahir',
                              icon: Icons.cake_outlined,
                              readOnly: true,
                              onTap: _pickBirthday,
                              suffixIcon:
                                  const Icon(Icons.calendar_today_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSection(
                          title: 'Lokasi',
                          subtitle:
                              'Bantu penjual dan pembeli mengenali area kamu.',
                          children: [
                            _buildTextField(
                              controller: _regionController,
                              label: 'Alamat / Provinsi',
                              icon: Icons.location_on_outlined,
                            ),
                            _buildTextField(
                              controller: _cityController,
                              label: 'Kota',
                              icon: Icons.location_city_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildSection(
                          title: 'Tentang Saya',
                          subtitle:
                              'Ceritakan singkat tentang diri atau toko kamu.',
                          children: [
                            _buildTextField(
                              controller: _bioController,
                              label: 'Bio',
                              icon: Icons.short_text_outlined,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEditHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFF64A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83030).withValues(alpha: 0.24),
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: _buildHeaderCircle(118),
          ),
          Positioned(
            right: 34,
            bottom: -42,
            child: _buildHeaderCircle(92),
          ),
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
    );
  }

  Widget _buildProfilePhotoPicker() {
    ImageProvider? imageProvider;
    if (_selectedProfileImage != null) {
      imageProvider = FileImage(_selectedProfileImage!);
    } else if ((_user?.avatarUrl ?? '').isNotEmpty) {
      imageProvider = NetworkImage(_user!.avatarUrl);
    }

    return ProfileImageUploader(
      imageProvider: imageProvider,
      title: _nameController.text.trim().isEmpty
          ? 'Foto Profil'
          : _nameController.text.trim(),
      subtitle: _emailController.text.trim().isEmpty
          ? 'Lengkapi identitas akun kamu'
          : _emailController.text.trim(),
      isLoading: _isSaving,
      onTap: _showProfileImageOptions,
    );
  }

  Widget _buildSaveBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE83030),
              disabledBackgroundColor:
                  const Color(0xFFE83030).withValues(alpha: 0.45),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 6,
              shadowColor: const Color(0xFFE83030).withValues(alpha: 0.24),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Gagal memuat profil.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return ProfileFormSection(
      title: title,
      subtitle: subtitle,
      icon: switch (title) {
        'Informasi Dasar' => Icons.badge_outlined,
        'Lokasi' => Icons.location_on_outlined,
        _ => Icons.notes_outlined,
      },
      children: children,
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Gender'),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldIcon(Icons.wc_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _isSaving ? null : _showGenderPicker,
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    child: Text(
                      _genderLabel(_gender),
                      style: TextStyle(
                        color:
                            _gender.isEmpty ? Colors.black38 : Colors.black87,
                        fontSize: 14,
                        fontWeight:
                            _gender.isEmpty ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showGenderPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Pilih Gender',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Informasi ini membantu melengkapi identitas profil kamu.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _buildGenderOption(
                  value: 'male',
                  label: 'Laki-laki',
                  icon: Icons.male_rounded,
                ),
                _buildGenderOption(
                  value: 'female',
                  label: 'Perempuan',
                  icon: Icons.female_rounded,
                ),
                _buildGenderOption(
                  value: 'other',
                  label: 'Lainnya',
                  icon: Icons.diversity_1_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() => _gender = selected);
  }

  Widget _buildGenderOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _gender == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? const Color(0xFFE83030).withValues(alpha: 0.08)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context, value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE83030)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE83030)
                        : const Color(0xFFFFEFEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : const Color(0xFFE83030),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFE83030),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return 'Laki-laki';
      case 'female':
        return 'Perempuan';
      case 'other':
        return 'Lainnya';
      default:
        return 'Pilih gender';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
    bool readOnly = false,
    String? helperText,
    int maxLines = 1,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldIcon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: validator,
                  enabled: enabled,
                  readOnly: readOnly,
                  maxLines: maxLines,
                  onTap: onTap,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration(
                    hintText: label,
                    helperText: helperText,
                    suffixIcon: suffixIcon,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildFieldIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFFE83030)),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      helperText: helperText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(
        color: Colors.black26,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      helperStyle: const TextStyle(color: Colors.black38, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE83030), width: 1.1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
    );
  }
}
