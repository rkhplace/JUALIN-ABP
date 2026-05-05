import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final ApiClient _client = ApiClient();

  /// Fetches the currently authenticated user's profile.
  ///
  /// API: GET /v1/me
  /// The endpoint returns the User object DIRECTLY (flat, no 'data' wrapper)
  /// because AuthController::me() uses response()->json($user) directly.
  Future<User?> getProfile() async {
    try {
      // Debug: log the token being sent
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      debugPrint('[ProfileService] getProfile → token: ${token != null ? "${token.substring(0, token.length > 20 ? 20 : token.length)}..." : "NULL (not logged in!)"}');

      if (token == null || token.isEmpty) {
        debugPrint('[ProfileService] getProfile: No token found in SharedPreferences. User is not logged in.');
        return null;
      }

      debugPrint('[ProfileService] getProfile → calling ${ApiConfig.baseUrl}${ApiConfig.me}');
      final response = await _client.get(ApiConfig.me);
      debugPrint('[ProfileService] getProfile ← response keys: ${response.keys.toList()}');
      debugPrint('[ProfileService] getProfile ← raw response: $response');

      // /me returns the user object directly at the top level (flat),
      // because AuthController::me() uses response()->json($user) not ApiResponse::success().
      // ApiClient._decode() passes Map<String,dynamic> through as-is.
      Map<String, dynamic> userData;
      if (response.containsKey('id')) {
        debugPrint('[ProfileService] getProfile: detected flat response (has "id" key)');
        userData = response; // flat response: { id, username, email, role, ... }
      } else if (response['data'] is Map) {
        debugPrint('[ProfileService] getProfile: detected wrapped response (has "data" key)');
        userData = response['data'] as Map<String, dynamic>;
      } else {
        debugPrint('[ProfileService] getProfile: unexpected response structure: $response');
        return null;
      }

      debugPrint('[ProfileService] getProfile: parsing user — id=${userData['id']}, name=${userData['username'] ?? userData['name']}, email=${userData['email']}');
      final user = User.fromJson(userData);
      debugPrint('[ProfileService] getProfile: success — User(id=${user.id}, name=${user.name}, role=${user.role})');
      return user;
    } on ApiException catch (e) {
      debugPrint('[ProfileService] getProfile ApiException: status=${e.statusCode}, message=${e.message}');
      if (e.statusCode == 401) {
        debugPrint('[ProfileService] getProfile: 401 Unauthorized — token invalid or expired.');
        return null; // Not authenticated
      }
      throw Exception('Gagal memuat profil (${e.statusCode}): ${e.message}');
    } catch (e) {
      debugPrint('[ProfileService] getProfile error: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  /// Updates the authenticated user's profile.
  ///
  /// API: PATCH /v1/profile/update
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? location,
    String? bio,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (location != null) body['location'] = location;
      if (bio != null) body['bio'] = bio;

      debugPrint('[ProfileService] updateProfile → body: $body');
      await _client.patch(ApiConfig.profileUpdate, body: body);
      debugPrint('[ProfileService] updateProfile: success');
      return true;
    } on ApiException catch (e) {
      debugPrint('[ProfileService] updateProfile ApiException: ${e.statusCode} ${e.message}');
      throw Exception('Gagal memperbarui profil: ${e.message}');
    } catch (e) {
      debugPrint('[ProfileService] updateProfile error: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }
}
