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
      final rawList = response['products'];
      if (rawList is! List) return [];
      return rawList
          .map((json) => SellerProduct.fromJson(json as Map<String, dynamic>))
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

      // The response can be paginated: { data: [...] } or { transactions: [...] }
      final raw = response['data'] ?? response['transactions'] ?? response;
      List<dynamic> items = [];

      if (raw is Map && raw['data'] is List) {
        items = raw['data'] as List;
      } else if (raw is List) {
        items = raw;
      } else if (raw is Map && raw.containsKey('data')) {
        final nested = raw['data'];
        if (nested is List) {
          items = nested;
        } else if (nested is Map && nested['data'] is List) {
          items = nested['data'] as List;
        }
      }

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
      // ApiResponse wraps in 'data'
      return (response['data'] as Map<String, dynamic>?) ?? response;
    } on ApiException catch (e) {
      throw Exception('Gagal memuat statistik: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
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
