import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/ui/app_chrome.dart';
import '../widgets/ui/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  bool _isSendingResetLink = false;
  String _userRole = 'customer';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[ProfileScreen] _fetchProfile: starting...');
      final user = await _profileService.getProfile();
      final idAndRole = await _authService.getUserIdAndRole();
      if (!mounted) return;

      setState(() {
        _user = user;
        _userRole = idAndRole['role'] as String? ?? user?.role ?? 'customer';
        _isLoading = false;
        _errorMessage = user == null
            ? 'Profil tidak ditemukan. Pastikan Anda sudah login.'
            : null;
      });
    } catch (e) {
      debugPrint('[ProfileScreen] _fetchProfile ERROR: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _user?.email.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email profil tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSendingResetLink = true);
    final error = await _authService.sendResetLink(email);
    if (!mounted) return;

    setState(() => _isSendingResetLink = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    await _authService.logout();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link reset telah dikirim ke email Anda. Silakan cek inbox.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      showTopBar: false,
      showNavbar: true,
      showSearch: false,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE83030)),
            )
          : (_user == null || _errorMessage != null)
              ? _buildErrorState(context)
              : RefreshIndicator(
                  color: const Color(0xFFE83030),
                  onRefresh: _fetchProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildHeader(_user!),
                        const SizedBox(height: 20),
                        if (_userRole != 'seller') ...[
                          _buildPurchaseHistoryMenu(),
                          const SizedBox(height: 16),
                        ] else ...[
                          _buildVerificationMission(_user!),
                          const SizedBox(height: 16),
                        ],
                        _buildAccountInfo(_user!),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Profil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            side: const BorderSide(color: Colors.black12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final updated =
                                await Navigator.pushNamed(context, '/profile_edit');
                            if (updated == true) {
                              _fetchProfile();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: _isSendingResetLink
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.lock_reset, size: 18),
                          label: Text(
                            _isSendingResetLink
                                ? 'Mengirim link reset...'
                                : 'Reset Password',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE83030),
                            side: const BorderSide(color: Color(0xFFE83030)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed:
                              _isSendingResetLink ? null : _handlePasswordReset,
                        ),
                        const SizedBox(height: 48),
                        CustomButton(
                          text: 'Logout',
                          isSecondary: true,
                          onPressed: () async {
                            await _authService.logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                )
    );
  }

  Widget _buildPurchaseHistoryMenu() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pushNamed(context, '/purchase_history'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: const Row(
          children: [
            Icon(Icons.receipt_long_outlined, color: Color(0xFFE83030)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Riwayat Pembelian',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Gagal memuat profil.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE83030),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Masuk / Daftar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFFF5F5F5),
          backgroundImage:
              user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
          child: user.avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(user.email, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _userRole == 'seller'
                ? const Color(0xFFFFF0F0)
                : const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _userRole == 'seller'
                  ? const Color(0xFFE83030).withValues(alpha: 0.4)
                  : Colors.blue.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            _userRole == 'seller' ? 'Penjual' : 'Pembeli',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _userRole == 'seller' ? const Color(0xFFE83030) : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationMission(User user) {
    final status = user.verificationStatus.toLowerCase();
    final isVerified = status == 'verified' || status == 'approved';
    final isPending =
        status == 'pending' || status == 'in_review' || status == 'processing';
    final label = isVerified
        ? 'Sudah Terverifikasi'
        : isPending
            ? 'Dalam Proses'
            : 'Belum Terverifikasi';
    final color = isVerified
        ? Colors.green
        : isPending
            ? Colors.orange
            : const Color(0xFFE83030);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified_user : Icons.assignment_turned_in_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Misi Verifikasi Akun',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Nama', user.name),
          _buildInfoRow('Email', user.email),
          _buildInfoRow('Nomor HP', user.phone),
          _buildInfoRow('Alamat / Provinsi', user.region),
          _buildInfoRow('Kota', user.city),
          _buildInfoRow('Tempat Lahir', user.birthPlace),
          _buildInfoRow('Tanggal Lahir', user.birthday),
          _buildInfoRow('Role', _userRole == 'seller' ? 'Penjual' : 'Pembeli'),
          _buildInfoRow('Status Akun', user.status),
          _buildInfoRow(
            'Status Verifikasi',
            user.verificationStatus.isEmpty
                ? 'Belum Terverifikasi'
                : user.verificationStatus,
          ),
          _buildInfoRow('Bio', user.bio),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final display = value.trim().isEmpty ? 'Belum diisi' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
