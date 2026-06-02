import 'dart:io';
import '../models/seller_product.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'product_service.dart';

class SellerService {
  final ApiClient _client = ApiClient();
  final ProductService _productService = ProductService();

  // ── Products ─────────────────────────────────────────────────────────────

  /// Fetches all products that belong to the authenticated seller.
  ///
  /// API: GET /v1/seller/products → { products: [...], ... }
  Future<List<SellerProduct>> getSellerProducts() async {
    try {
      final response = await _client.get(ApiConfig.sellerProducts);
      final rawList = _extractList(response, ['products']);
      return rawList
          .whereType<Map>()
          .map((json) => SellerProduct.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on ApiException catch (e) {
      throw Exception('Gagal memuat produk: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  /// Creates a new product for the authenticated seller.
  Future<bool> createProduct(Map<String, String> data, {File? imageFile}) async {
    try {
      await _productService.createProduct(data, imageFile: imageFile);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing seller product.
  Future<bool> updateProduct(int id, Map<String, String> data,
      {File? imageFile}) async {
    try {
      await _productService.updateProduct(id, data, imageFile: imageFile);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the total product count for the authenticated seller.
  Future<int> getSellerProductTotal() async {
    try {
      final response = await _client.get(ApiConfig.sellerProducts);
      final total = response['totalProducts'] ??
          response['total_products'] ??
          response['data']?['totalProducts'] ??
          response['data']?['total_products'] ??
          response['pagination']?['total'];
      if (total is num) return total.toInt();
      final parsed = int.tryParse(total?.toString() ?? '');
      if (parsed != null) return parsed;

      final rawList = _extractList(response, ['products']);
      return rawList.length;
    } on ApiException catch (e) {
      throw Exception('Gagal memuat total produk: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  /// Deletes a seller's product by ID.
  Future<bool> deleteProduct(int id) async {
    try {
      return await _productService.deleteProduct(id);
    } catch (e) {
      rethrow;
    }
  }

  // ── Orders ───────────────────────────────────────────────────────────────

  /// Fetches all transactions where the current user is the seller.
  ///
  /// API: GET /v1/transactions → paginated list (both buyer + seller transactions).
  /// The API returns all transactions for the authenticated user as buyer or seller.
  Future<List<Map<String, dynamic>>> getSellerOrders() async {
    try {
      final response = await _client.get(
        ApiConfig.transactions,
        queryParams: {'per_page': '50'},
      );

      final items = _extractList(response, ['transactions']);
      return items.cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      throw Exception('Gagal memuat pesanan: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  /// Fetches income statistics for the seller dashboard.
  ///
  /// API: GET /v1/transactions/income/statistics?period=Month
  /// Returns { balance, transferred, chart_data, period }
  Future<Map<String, dynamic>> getSellerStats({String period = 'Month'}) async {
    try {
      final response = await _client.get(
        ApiConfig.sellerStats,
        queryParams: {'period': period},
      );
      final stats = Map<String, dynamic>.from(
        (response['data'] as Map<String, dynamic>?) ?? response,
      );

      try {
        final orders = await getSellerOrders();
        final completedOrders = orders.where(_isCompletedOrder).toList();
        final totalSales = completedOrders.fold<double>(
          0,
          (sum, order) => sum + _parseDouble(order['total_amount']),
        );

        stats['total_sales'] = totalSales;
        stats['total_completed_transactions'] = completedOrders.length;
        stats['valid_order_count'] = completedOrders.length;
      } catch (_) {
        stats['total_sales'] ??= stats['chart_total'] ?? 0;
        stats['total_completed_transactions'] ??= 0;
        stats['valid_order_count'] ??= 0;
      }
      stats['wallet_balance'] =
          stats['current_balance'] ?? stats['wallet_balance'] ?? stats['balance'] ?? 0;
      return stats;
    } on ApiException catch (e) {
      throw Exception('Gagal memuat statistik: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  bool _isCompletedOrder(Map<String, dynamic> order) {
    final status = (order['status'] ??
            order['transaction_status'] ??
            order['payment_status'] ??
            '')
        .toString()
        .toLowerCase();
    return status == 'verified' || status == 'completed';
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  List<dynamic> _extractList(Map<String, dynamic> response, List<String> keys) {
    for (final key in keys) {
      final value = response[key];
      if (value is List) return value;
    }

    final data = response['data'];
    if (data is List) return data;
    if (data is Map) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
      }
      final nested = data['data'];
      if (nested is List) return nested;
    }

    final products = response['products'];
    if (products is List) return products;

    return [];
  }

  // ── Withdraw ──────────────────────────────────────────────────────────────

  /// Requests a wallet withdrawal for the seller.
  ///
  /// API: POST /v1/transactions/withdraw
  Future<double> withdrawWallet({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final response = await _client.post(
        ApiConfig.sellerWithdraw,
        body: {
          'amount': amount,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_name': accountName,
        },
      );
      final data = (response['data'] as Map<String, dynamic>?) ?? {};
      final bal = data['remaining_balance'];
      if (bal is num) return bal.toDouble();
      if (bal is String) return double.tryParse(bal) ?? 0.0;
      return 0.0;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }
}
