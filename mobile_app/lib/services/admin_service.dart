import 'api_client.dart';
import 'api_config.dart';

class AdminService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getUsers({int perPage = 100}) async {
    final response = await _client.get(
      '/users',
      queryParams: {'per_page': perPage.toString()},
    );
    return _extractList(response);
  }

  Future<List<Map<String, dynamic>>> getProducts({int perPage = 100}) async {
    final response = await _client.get(
      ApiConfig.products,
      queryParams: {'per_page': perPage.toString()},
    );
    return _extractList(response);
  }

  Future<List<Map<String, dynamic>>> getTransactions(
      {int perPage = 100}) async {
    final response = await _client.get(
      ApiConfig.transactions,
      queryParams: {'per_page': perPage.toString()},
    );
    return _extractList(response);
  }

  Future<List<Map<String, dynamic>>> getReports({int page = 1}) async {
    final response = await _client.get(
      ApiConfig.reports,
      queryParams: {'page': page.toString()},
    );
    return _extractList(response);
  }

  Future<void> banUser(int userId, int durationDays) async {
    await _client.patch(
      '/users/$userId/ban',
      body: {'duration_days': durationDays},
    );
  }

  Future<void> unbanUser(int userId) async {
    await _client.patch('/users/$userId/unban');
  }

  Future<void> deleteProduct(int productId, String reason) async {
    await _client.delete(
      '${ApiConfig.products}/$productId',
      body: {'delete_reason': reason},
    );
  }

  Future<void> updateTransactionStatus(int transactionId, String status) async {
    await _client.patch(
      '${ApiConfig.transactions}/$transactionId/status',
      body: {'status': status},
    );
  }

  Future<void> updateReportStatus(int reportId, String status) async {
    await _client.patch(
      '${ApiConfig.reports}/$reportId/status',
      body: {'status': status},
    );
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    dynamic raw = response['data'];
    raw ??= response['products'];

    if (raw is Map && raw['data'] is List) {
      raw = raw['data'];
    } else if (response['products'] is List) {
      raw = response['products'];
    }

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
