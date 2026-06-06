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
  Future<Map<String, dynamic>> getNotifications({bool markRead = false}) async {
    try {
      final endpoint = markRead ? '${ApiConfig.notifications}?mark_read=1' : ApiConfig.notifications;
      final response = await _client.get(endpoint);
      final data = response['data'] ?? response;
      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }
}
