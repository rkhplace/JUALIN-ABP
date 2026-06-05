import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/ui/frosted_app_bar.dart';
import '../widgets/ui/logo_loader.dart';

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
  final _birthPlaceController = TextEditingController();
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
    _birthPlaceController.dispose();
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
        _birthPlaceController.text = user.birthPlace;
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
        userId: _user!.id,
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender.isEmpty ? null : _gender,
        birthday: _birthdayController.text.trim().isEmpty
            ? null
            : _birthdayController.text.trim(),
        region: _regionController.text.trim(),
        city: _cityController.text.trim(),
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
      backgroundColor: Colors.white,
      title: 'Edit Profil',
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
      body: _isLoading
          ? const JualinLogoLoader(size: 64)
          : _errorMessage != null && _user == null
              ? _buildError()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProfilePhotoPicker(),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(_errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nama',
                        validator: (value) =>
                            value == null || value.trim().length < 3
                                ? 'Nama minimal 3 karakter'
                                : null,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || !value.contains('@')
                                ? 'Email tidak valid'
                                : null,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Nomor HP',
                        enabled: false,
                        helperText: 'Field ini belum tersedia di API akun.',
                      ),
                      _buildGenderField(),
                      _buildTextField(
                        controller: _regionController,
                        label: 'Alamat / Provinsi',
                      ),
                      _buildTextField(
                        controller: _cityController,
                        label: 'Kota',
                      ),
                      _buildTextField(
                        controller: _birthPlaceController,
                        label: 'Tempat Lahir',
                        enabled: false,
                        helperText: 'Field ini belum tersedia di API akun.',
                      ),
                      _buildTextField(
                        controller: _birthdayController,
                        label: 'Tanggal Lahir',
                        readOnly: true,
                        onTap: _pickBirthday,
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      _buildTextField(
                        controller: _bioController,
                        label: 'Bio',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE83030),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                            _isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
                      ),
                    ],
                  ),
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

    return Center(
      child: Column(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: _isSaving ? null : _showProfileImageOptions,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFFF5F5F5),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(Icons.person, size: 52, color: Colors.grey)
                      : null,
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE83030),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _isSaving ? null : _showProfileImageOptions,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Ubah Foto Profil'),
          ),
        ],
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

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _gender.isEmpty ? null : _gender,
        decoration: const InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
          DropdownMenuItem(value: 'female', child: Text('Perempuan')),
          DropdownMenuItem(value: 'other', child: Text('Lainnya')),
        ],
        onChanged: (value) => setState(() => _gender = value ?? ''),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
