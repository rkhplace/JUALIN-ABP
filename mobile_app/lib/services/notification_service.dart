import 'api_client.dart';
import 'api_config.dart';

class NotificationService {
  final ApiClient _client = ApiClient();

  /// Fetches notifications from the server.
  /// 
  /// Expected JSON Response:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "unread_count": 3,
  ///     "data": [
  ///       { "id": 1, "title": "...", "body": "...", "created_at": "...", "type": "..." }
  ///     ]
  ///   }
  /// }
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _client.get(ApiConfig.notifications);
      final data = response['data'] ?? response;
      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }
}
