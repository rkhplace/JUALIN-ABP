import 'package:flutter/material.dart';
import '../widgets/ui/app_chrome.dart';
import '../widgets/ui/custom_button.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

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
      debugPrint('[ProfileScreen] _fetchProfile: user=$user, idAndRole=$idAndRole');
      if (mounted) {
        setState(() {
          _user = user;
          _userRole = idAndRole['role'] as String? ?? 'customer';
          _isLoading = false;
          _errorMessage = user == null ? 'Profil tidak ditemukan. Pastikan Anda sudah login.' : null;
        });
      }
    } catch (e) {
      debugPrint('[ProfileScreen] _fetchProfile ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE83030)))
          : (_user == null || _errorMessage != null)
              ? Center(
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
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar & Basic Info
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFF5F5F5),
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user!.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _user!.email,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      // Role badge
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
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
                            color: _userRole == 'seller'
                                ? const Color(0xFFE83030)
                                : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Actions
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
                        onPressed: () =>
                            Navigator.pushNamed(context, '/profile_edit'),
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
                        onPressed: _isSendingResetLink ? null : _handlePasswordReset,
                      ),
                      const SizedBox(height: 32),

                      // ── Navigation Links ──────────────────────────────────

                      // Show Seller Dashboard ONLY for sellers
                      if (_userRole == 'seller') ...[
                        _buildListTile(
                          context,
                          Icons.store,
                          'Dashboard Penjual',
                          () => Navigator.pushNamed(context, '/seller_main'),
                        ),
                        const Divider(height: 1),
                      ],

                      // Buyer links (shown to all)
                      _buildListTile(
                        context,
                        Icons.receipt_long,
                        'Riwayat Pembelian',
                        () => Navigator.pushNamed(context, '/purchase_history'),
                      ),
                      const Divider(height: 1),
                      _buildListTile(
                          context, Icons.history, 'Riwayat Pembelian', () {}),
                      const Divider(height: 1),
                      _buildListTile(context, Icons.account_balance_wallet,
                          'Saldo & Transaksi', () {}),
                      const Divider(height: 1),

                      const SizedBox(height: 48),
                      CustomButton(
                        text: 'Logout',
                        isSecondary: true,
                        onPressed: () async {
                          await _authService.logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/main',
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title,
      VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
