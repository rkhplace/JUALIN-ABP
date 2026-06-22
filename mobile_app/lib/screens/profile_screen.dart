import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/seller_service.dart';
import '../widgets/ui/logo_loader.dart';
import '../widgets/ui/user_avatar.dart';
import '../screens/report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _DeletionVerificationDialog extends StatefulWidget {
  const _DeletionVerificationDialog();

  @override
  State<_DeletionVerificationDialog> createState() =>
      _DeletionVerificationDialogState();
}

class _DeletionVerificationDialogState
    extends State<_DeletionVerificationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phraseController = TextEditingController();
  bool _obscurePassword = true;

  bool get _canSubmit =>
      _passwordController.text.isNotEmpty &&
      _phraseController.text == 'HAPUS AKUN';

  @override
  void dispose() {
    _passwordController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop({
      'password': _passwordController.text,
      'confirmation_phrase': _phraseController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 34,
                spreadRadius: -12,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFEF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Color(0xFFE83030),
                      size: 31,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verifikasi Penghapusan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Langkah ini memastikan hanya pemilik akun yang dapat menjadwalkan penghapusan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Masukkan password akun Jualin.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE83030), width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ketik HAPUS AKUN untuk melanjutkan.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phraseController,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'HAPUS AKUN',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFE83030), width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE83030),
                          side: const BorderSide(color: Color(0xFFFFC7C7)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Batal',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE83030),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Jadwalkan',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  bool _isSendingResetLink = false;
  bool _isAccountInfoExpanded = false;
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
        content: Text(
            'Tautan reset telah dikirim ke email Anda. Silakan cek kotak masuk.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<bool?> _showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 34,
                  spreadRadius: -12,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE83030),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Konfirmasi Keluar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apakah Anda yakin ingin keluar dari akun Jualin?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE83030),
                          side: const BorderSide(color: Color(0xFFFFC7C7)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE83030),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text(
                          'Ya, Keluar',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteAccountConfirmation() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 34,
                  spreadRadius: -12,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFEF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete_forever_outlined,
                    color: Color(0xFFE83030),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hapus Akun?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Profil, riwayat transaksi, chat, produk, dan data terkait akan dijadwalkan untuk dihapus permanen. Anda memiliki 14 hari untuk membatalkannya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE83030),
                          side: const BorderSide(color: Color(0xFFFFC7C7)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE83030),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showDeletionVerificationDialog() async {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (_) => const _DeletionVerificationDialog(),
    );
  }

  Future<void> _showAccountDeletedDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF41B34D),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Penghapusan Dijadwalkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Akun akan dihapus permanen dalam 14 hari. Login kembali sebelum tenggat untuk membatalkannya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE83030),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await _showDeleteAccountConfirmation();
    if (confirmed != true) return;
    final verification = await _showDeletionVerificationDialog();
    if (verification == null) return;

    try {
      await _authService.deleteAccount(
        verification['password']!,
        verification['confirmation_phrase']!,
      );
      if (!mounted) return;
      await _showAccountDeletedDialog();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCancelAccountDeletion() async {
    try {
      await _authService.cancelAccountDeletion();
      await _fetchProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Penghapusan akun berhasil dibatalkan.'),
            backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const JualinLogoLoader(size: 64)
            : (_user == null || _errorMessage != null)
                ? _buildErrorState(context)
                : RefreshIndicator(
                    color: const Color(0xFFE83030),
                    onRefresh: _fetchProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildProfileHero(_user!),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                            child: Column(
                              children: [
                                if (_userRole != 'seller') ...[
                                  _buildWalletBalanceCard(_user!),
                                  const SizedBox(height: 12),
                                ] else ...[
                                  _buildVerificationMission(_user!),
                                  const SizedBox(height: 12),
                                ],
                                _buildAccountInfo(_user!),
                                const SizedBox(height: 12),
                                _buildProfileMenuItem(
                                  icon: Icons.edit_outlined,
                                  title: 'Edit Profil',
                                  subtitle: _userRole == 'seller'
                                      ? 'Ubah informasi profil dan toko'
                                      : 'Ubah informasi profil Anda',
                                  onTap: () async {
                                    final updated = await Navigator.pushNamed(
                                        context, '/profile_edit');
                                    if (updated == true) _fetchProfile();
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildProfileMenuItem(
                                  icon: Icons.lock_reset_outlined,
                                  title: _isSendingResetLink
                                      ? 'Mengirim tautan reset...'
                                      : 'Ubah Kata Sandi',
                                  subtitle: 'Ganti kata sandi akun Anda',
                                  isOutlined: true,
                                  isLoading: _isSendingResetLink,
                                  onTap: _isSendingResetLink
                                      ? null
                                      : _handlePasswordReset,
                                ),
                                const SizedBox(height: 12),
                                _buildProfileMenuItem(
                                  icon: Icons.report_gmailerrorred_outlined,
                                  title: 'Laporan Umum',
                                  subtitle: 'Kirim atau lihat laporan umum',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const ReportScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildProfileMenuItem(
                                  icon: Icons.logout_outlined,
                                  title: 'Keluar',
                                  subtitle: 'Keluar dari akun Anda',
                                  isDanger: true,
                                  showChevron: false,
                                  onTap: () async {
                                    final confirmed =
                                        await _showLogoutConfirmation();
                                    if (confirmed == true) {
                                      await _authService.logout();
                                      if (context.mounted) {
                                        Navigator.pushReplacementNamed(
                                            context, '/login');
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildProfileMenuItem(
                                  icon: Icons.delete_forever_outlined,
                                  title:
                                      (_user?.scheduledDeletionAt.isNotEmpty ??
                                              false)
                                          ? 'Batalkan Penghapusan'
                                          : 'Hapus Akun',
                                  subtitle: (_user?.scheduledDeletionAt
                                              .isNotEmpty ??
                                          false)
                                      ? 'Akun dijadwalkan untuk dihapus'
                                      : 'Hapus permanen setelah masa pemulihan 14 hari',
                                  isDanger: true,
                                  showChevron: false,
                                  onTap:
                                      (_user?.scheduledDeletionAt.isNotEmpty ??
                                              false)
                                          ? _handleCancelAccountDeletion
                                          : _handleDeleteAccount,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildWalletBalanceCard(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFE84444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83030).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Dompet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(user.walletBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic val) {
    int amount = 0;
    if (val is num) {
      amount = val.toInt();
    } else if (val is String) {
      amount = double.tryParse(val)?.toInt() ?? 0;
    }
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Masuk / Daftar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHero(User user) {
    final roleLabel = _userRole == 'seller' ? 'Penjual' : 'Pembeli';
    final roleColor = _userRole == 'seller'
        ? const Color(0xFFE83030)
        : const Color(0xFF2563EB);
    final isVerifiedProfile = ['verified', 'approved']
        .contains(user.verificationStatus.toLowerCase());

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          height: 178,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE83030), Color(0xFFF13A3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final updated =
                          await Navigator.pushNamed(context, '/profile_edit');
                      if (updated == true) _fetchProfile();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 132,
          left: 0,
          right: 0,
          child: Container(
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 90),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: isVerifiedProfile
                      ? Border.all(
                          color:
                              const Color(0xFF22C55E).withValues(alpha: 0.75),
                          width: 2,
                        )
                      : null,
                  boxShadow: [
                    if (isVerifiedProfile) ...[
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.42),
                        blurRadius: 34,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFF86EFAC).withValues(alpha: 0.34),
                        blurRadius: 50,
                        spreadRadius: 10,
                        offset: const Offset(0, 18),
                      ),
                    ],
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isVerifiedProfile ? 0.12 : 0.18,
                      ),
                      blurRadius: 26,
                      spreadRadius: -5,
                      offset: const Offset(0, 14),
                    ),
                    if (!isVerifiedProfile)
                      BoxShadow(
                        color: const Color(0xFFE83030).withValues(alpha: 0.16),
                        blurRadius: 22,
                        spreadRadius: -8,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: UserAvatar(
                  name: user.name,
                  imageUrl: user.avatarUrl,
                  radius: 52,
                  showBorder: false,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black38, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDanger = false,
    bool isOutlined = false,
    bool isLoading = false,
    bool showChevron = true,
  }) {
    final accentColor = isDanger ? const Color(0xFFE83030) : Colors.black87;
    const iconColor = Color(0xFFE83030);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOutlined ? const Color(0xFFE83030) : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE83030),
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
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

    return Material(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
            onTap: () => _showVerificationBottomSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE83030).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVerified
                          ? Icons.verified_user
                          : Icons.assignment_turned_in_outlined,
                      color: const Color(0xFFE83030),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verifikasi Akun',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(label,
                            style: TextStyle(color: color, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVerified ? Icons.check_circle : Icons.info_outline,
                          color: color,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVerified ? 'Terverifikasi' : label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }

  void _showVerificationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Progress Verifikasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>>(
                  future: SellerService().getVerificationStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFE83030)),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Terjadi kesalahan:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final data = snapshot.data ?? {};
                    final totalSales =
                        (data['total_sales'] as num?)?.toInt() ?? 0;
                    final target = (data['target'] as num?)?.toInt() ?? 3;
                    final progress = target > 0
                        ? (totalSales / target).clamp(0.0, 1.0)
                        : 0.0;
                    final profileRequirements =
                        _profileRequirementStatuses(_user);
                    final localProfileComplete = profileRequirements.every(
                      (item) => item['isComplete'] == true,
                    );
                    final apiMissingProfileFields =
                        (data['missing_profile_fields'] as List<dynamic>? ?? [])
                            .whereType<Map>()
                            .map((item) => item['label']?.toString() ?? '')
                            .where((label) => label.isNotEmpty)
                            .toList();
                    final missingProfileFields =
                        apiMissingProfileFields.isNotEmpty
                            ? apiMissingProfileFields
                            : profileRequirements
                                .where((item) => item['isComplete'] != true)
                                .map((item) => item['label'].toString())
                                .toList();
                    final profileComplete = data['profile_complete'] == true ||
                        (apiMissingProfileFields.isEmpty &&
                            localProfileComplete);
                    final salesComplete = totalSales >= target;
                    final allMissionsComplete =
                        salesComplete && profileComplete;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (allMissionsComplete) ...[
                          _buildVerificationSuccessBanner(),
                          const SizedBox(height: 14),
                        ],
                        _buildVerificationCard(
                          isComplete: salesComplete,
                          title: 'Selesaikan $target transaksi berhasil',
                          subtitle: salesComplete
                              ? 'Target transaksi sudah terpenuhi.'
                              : 'Masih perlu ${target - totalSales} transaksi berhasil lagi.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFFFE8E8),
                                  color: salesComplete
                                      ? Colors.green
                                      : const Color(0xFFE83030),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$totalSales/$target',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: salesComplete
                                        ? Colors.green
                                        : const Color(0xFFE83030),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildVerificationCard(
                          isComplete: profileComplete,
                          title: 'Lengkapi data diri dan foto profil',
                          subtitle: profileComplete
                              ? 'Semua data profil sudah lengkap.'
                              : missingProfileFields.isEmpty
                                  ? 'Cek ulang field profil yang wajib diisi.'
                                  : 'Belum lengkap: ${missingProfileFields.join(', ')}',
                          child: _buildProfileRequirementChecklist(
                            profileRequirements,
                            missingProfileFields,
                          ),
                        ),
                        if (!profileComplete && missingProfileFields.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: Color(0xFFD97706),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Buka Edit Profil lalu isi: ${missingProfileFields.join(', ')}.',
                                    style: const TextStyle(
                                      color: Color(0xFF7C4A03),
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE83030),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Tutup',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerificationSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9FFF0), Color(0xFFF7FFFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YEAY! Semua misi selesai',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF14532D),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kamu mendapatkan badge Terverifikasi. Profil toko jadi lebih dipercaya pembeli, transaksi terlihat lebih aman, dan produkmu tampil lebih meyakinkan.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard({
    required bool isComplete,
    required String title,
    required String subtitle,
    Widget? child,
  }) {
    final color = isComplete ? Colors.green : const Color(0xFFE83030);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFF0FDF4) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete ? Icons.check_circle : Icons.info_outline,
                  color: color,
                  size: isComplete ? 21 : 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isComplete ? 'Selesai' : 'Belum selesai',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRequirementChecklist(
    List<Map<String, Object>> requirements,
    List<String> missingLabels,
  ) {
    final visibleRequirements = requirements.map((item) {
      final label = item['label'].toString();
      final isComplete = item['isComplete'] == true &&
          !missingLabels.any((missing) => missing == label);

      return MapEntry(label, isComplete);
    }).toList();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: visibleRequirements.map((entry) {
        final isComplete = entry.value;
        final color = isComplete ? Colors.green : const Color(0xFFE83030);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.info_outline,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 11,
                  color: isComplete ? Colors.black87 : color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, Object>> _profileRequirementStatuses(User? user) {
    final currentUser = user ?? _user;

    bool filled(String? value) => (value ?? '').trim().isNotEmpty;

    return [
      {'label': 'Nama', 'isComplete': filled(currentUser?.name)},
      {'label': 'Email', 'isComplete': filled(currentUser?.email)},
      {'label': 'Gender', 'isComplete': filled(currentUser?.gender)},
      {
        'label': 'Tanggal lahir',
        'isComplete': filled(currentUser?.birthday),
      },
      {'label': 'Provinsi', 'isComplete': filled(currentUser?.region)},
      {'label': 'Kota', 'isComplete': filled(currentUser?.city)},
      {'label': 'Nomor HP', 'isComplete': filled(currentUser?.phone)},
      {'label': 'Bio', 'isComplete': filled(currentUser?.bio)},
      {
        'label': 'Foto profil',
        'isComplete': filled(currentUser?.avatarUrl),
      },
    ];
  }

  Widget _buildAccountInfo(User user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _isAccountInfoExpanded = !_isAccountInfoExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFFE83030),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Akun',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Lihat & kelola informasi akun Anda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isAccountInfoExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _buildInfoRow('Nama', user.name),
                  _buildInfoRow('Email', user.email),
                  _buildInfoRow('Nomor HP', user.phone),
                  _buildInfoRow('Alamat / Provinsi', user.region),
                  _buildInfoRow('Kota', user.city),
                  _buildInfoRow('Tanggal Lahir', user.birthday),
                  _buildInfoRow('Gender', _genderDisplay(user.gender)),
                  _buildInfoRow('Foto Profil',
                      user.avatarUrl.trim().isEmpty ? '' : 'Sudah diisi'),
                  _buildInfoRow(
                      'Peran', _userRole == 'seller' ? 'Penjual' : 'Pembeli'),
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
            ),
            crossFadeState: _isAccountInfoExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
          ),
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

  String _genderDisplay(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return 'Laki-laki';
      case 'female':
        return 'Perempuan';
      case 'other':
        return 'Lainnya';
      default:
        return value;
    }
  }
}
