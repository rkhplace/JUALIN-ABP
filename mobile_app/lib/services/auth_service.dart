import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'api_config.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String roleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userJsonKey = 'user_json';

  Future<String?> login(String email, String password) async {
    try {
      final response = await _client.post(
        ApiConfig.login,
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      await _persistAuthPayload(response);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) return 'Email atau password salah.';
      if (e.statusCode == 422) return e.message;
      return 'Login gagal (${e.statusCode}): ${e.message}';
    } catch (_) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
    }
  }

  Future<String?> register(
    String name,
    String email,
    String password, {
    String role = 'customer',
    String? passwordConfirmation,
  }) async {
    try {
      final username = _usernameFromName(name);
      final response = await _client.post(
        ApiConfig.register,
        body: {
          'username': username,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation ?? password,
          'role': role,
        },
        requiresAuth: false,
      );

      await _persistAuthPayload(response, fallbackUsername: username, fallbackRole: role);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 422) return e.message;
      return 'Registrasi gagal (${e.statusCode}): ${e.message}';
    } catch (_) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
    }
  }

  Future<String?> sendResetLink(String email) async {
    try {
      await _client.post(
        ApiConfig.passwordEmail,
        body: {'email': email.trim().toLowerCase()},
        requiresAuth: false,
      );
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 422) return e.message;
      return 'Gagal mengirim link reset (${e.statusCode}): ${e.message}';
    } catch (_) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _client.post(
        ApiConfig.passwordReset,
        body: {
          'token': token,
          'email': email.trim().toLowerCase(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        requiresAuth: false,
      );
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 422) return e.message;
      return 'Gagal mereset password (${e.statusCode}): ${e.message}';
    } catch (_) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
    }
  }

  Future<Map<String, dynamic>?> me({bool persist = true}) async {
    try {
      final response = await _client.get(ApiConfig.me);
      final user = _extractUser(response);
      if (persist && user != null) {
        await _persistUser(user);
      }
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await clearLocalSession();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConfig.logout);
    } catch (_) {
      // Keep logout local-first, matching the web app behavior.
    } finally {
      await clearLocalSession();
    }
  }

  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(roleKey);
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userJsonKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return _normalizeRole(prefs.getString(roleKey));
  }

  Future<Map<String, dynamic>> getUserIdAndRole() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt(userIdKey) ?? 0,
      'role': _normalizeRole(prefs.getString(roleKey)),
      'name': prefs.getString(userNameKey) ?? '',
      'email': prefs.getString(userEmailKey) ?? '',
    };
  }

  Future<String> resolveInitialRoute() async {
    if (!await isLoggedIn()) return '/main';

    final user = await me();
    if (user == null) return '/main';

    return routeForRole(_normalizeRole(user['role']?.toString()));
  }

  String routeForRole(String? role) {
    switch (_normalizeRole(role)) {
      case 'admin':
        return '/admin_home';
      case 'seller':
        return '/seller_main';
      default:
        return '/main';
    }
  }

  Future<void> _persistAuthPayload(
    Map<String, dynamic> response, {
    String? fallbackUsername,
    String? fallbackRole,
  }) async {
    final data = _extractAuthData(response);
    final token = data['access_token']?.toString();

    if (token == null || token.isEmpty) {
      throw ApiException('Token tidak ditemukan dari server.', 422);
    }

    final user = _extractUser(data) ?? <String, dynamic>{};
    final role = _normalizeRole(data['role']?.toString() ??
        user['role']?.toString() ??
        fallbackRole ??
        'customer');

    user['role'] = role;
    user['username'] = user['username'] ?? data['username'] ?? fallbackUsername;
    user['email'] = user['email'] ?? data['email'];
    user['id'] = user['id'] ?? data['id'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);

    final refreshToken = data['refresh_token']?.toString();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(refreshTokenKey, refreshToken);
    }

    await _persistUser(user);
  }

  Map<String, dynamic> _extractAuthData(Map<String, dynamic> response) {
    final wrapped = response['data'];
    if (wrapped is Map) return Map<String, dynamic>.from(wrapped);
    return Map<String, dynamic>.from(response);
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> payload) {
    final wrapped = payload['data'];
    if (wrapped is Map && (wrapped['id'] != null || wrapped['email'] != null)) {
      return Map<String, dynamic>.from(wrapped);
    }

    final user = payload['user'];
    if (user is Map) return Map<String, dynamic>.from(user);

    if (payload['id'] != null || payload['email'] != null || payload['username'] != null) {
      return Map<String, dynamic>.from(payload);
    }

    return null;
  }

  Future<void> _persistUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final role = _normalizeRole(user['role']?.toString());
    final name = (user['username'] ?? user['name'] ?? user['email'] ?? '').toString();
    final email = (user['email'] ?? '').toString();

    final id = _parseInt(user['id'] ?? user['user_id'] ?? user['userId']);
    if (id > 0) await prefs.setInt(userIdKey, id);

    await prefs.setString(roleKey, role);
    await prefs.setString(userNameKey, name);
    await prefs.setString(userEmailKey, email);
    await prefs.setString(userJsonKey, jsonEncode(user));
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalizeRole(String? role) {
    final normalized = (role ?? 'customer').toLowerCase().trim();
    if (normalized == 'buyer') return 'customer';
    return normalized.isEmpty ? 'customer' : normalized;
  }

  String _usernameFromName(String name) {
    final username = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return username;
  }
}
