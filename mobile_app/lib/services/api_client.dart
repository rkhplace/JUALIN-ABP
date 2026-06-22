import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Exception thrown when the API returns an error response.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> data;

  ApiException(this.message, this.statusCode, [this.data = const {}]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Centralized HTTP client that automatically attaches the Bearer token,
/// decodes JSON, and maps error status codes to [ApiException].
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint(
            '[ApiClient] Token: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      } else {
        debugPrint(
            '[ApiClient] WARNING: No auth_token found in SharedPreferences!');
      }
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    debugPrint(
        '[ApiClient] ← HTTP ${response.statusCode} | body: ${response.body.length > 500 ? "${response.body.substring(0, 500)}..." : response.body}');
    final body = response.body.trim().isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final msg = body is Map
          ? _errorMessage(body, fallback: 'Request failed')
          : 'Request failed';
      throw ApiException(
        msg.toString(),
        response.statusCode,
        body is Map ? Map<String, dynamic>.from(body) : const {},
      );
    }
    return body is Map<String, dynamic> ? body : {'data': body};
  }

  String _errorMessage(Map<dynamic, dynamic> body,
      {String fallback = 'Request failed'}) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages = <String>[];
      const metadataFields = {
        'reason',
        'remaining_attempts',
        'retry_after',
        'locked_until',
        'reset_email_sent',
      };

      for (final entry in errors.entries) {
        if (metadataFields.contains(entry.key.toString())) continue;
        final label = _fieldLabel(entry.key.toString());
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          messages.add('$label: ${value.first}');
        } else if (value != null) {
          messages.add('$label: $value');
        }
      }

      if (messages.isNotEmpty) return messages.join('\n');
    }

    return (body['message'] ?? fallback).toString();
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'username':
        return 'Nama pengguna';
      case 'email':
        return 'Email';
      case 'password':
        return 'Kata sandi';
      case 'profile_picture':
        return 'Foto profil';
      case 'gender':
        return 'Gender';
      case 'birthday':
        return 'Tanggal lahir';
      case 'region':
        return 'Provinsi';
      case 'city':
        return 'Kota';
      case 'phone':
        return 'Nomor HP';
      case 'bio':
        return 'Bio';
      default:
        return field;
    }
  }

  // ── Public Methods ───────────────────────────────────────────────────────

  /// GET request (optionally authenticated).
  Future<Map<String, dynamic>> get(String path,
      {bool requiresAuth = true, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: queryParams);
    final headers = await _authHeaders(requiresAuth: requiresAuth);
    debugPrint('[ApiClient] → GET $uri');

    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw ApiException('Request timed out', 408),
        );

    return _decode(response);
  }

  /// POST request (optionally authenticated).
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _authHeaders(requiresAuth: requiresAuth);

    final response = await http
        .post(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw ApiException('Request timed out', 408),
        );

    return _decode(response);
  }

  /// PATCH request (optionally authenticated).
  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _authHeaders(requiresAuth: requiresAuth);

    final response = await http
        .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw ApiException('Request timed out', 408),
        );

    return _decode(response);
  }

  /// DELETE request (optionally authenticated).
  Future<Map<String, dynamic>> delete(String path,
      {bool requiresAuth = true, Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _authHeaders(requiresAuth: requiresAuth);

    final response = await http
        .delete(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw ApiException('Request timed out', 408),
        );

    return _decode(response);
  }

  /// Multipart POST for file uploads (e.g. product images).
  Future<Map<String, dynamic>> postMultipart(
      String path, Map<String, String> fields,
      {File? imageFile,
      String imageField = 'image',
      String method = 'POST'}) async {
    final normalizedMethod = method.toUpperCase();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final request = http.MultipartRequest(normalizedMethod, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..fields.addAll(fields);

    if (imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath(imageField, imageFile.path));
    }

    final streamed = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw ApiException('Upload timed out', 408),
        );
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }
}
