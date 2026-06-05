import 'api_client.dart';
import 'api_config.dart';

class ReportService {
  final ApiClient _client = ApiClient();

  Future<void> createProductReport({
    required int productId,
    required String type,
    required String description,
    int? reportedUserId,
    String? reportedUsername,
  }) async {
    try {
      await _client.post(
        ApiConfig.reports,
        body: {
          'product_id': productId,
          'type': type,
          'description': description,
          'reported_user_id': reportedUserId,
          'reported_username': reportedUsername,
          'target_username': reportedUsername,
        },
      );
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }
}
