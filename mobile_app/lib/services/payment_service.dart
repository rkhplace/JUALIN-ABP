import 'api_client.dart';
import 'api_config.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  final ApiClient _client = ApiClient();

  /// Fetches the buyer's purchase history.
  /// API: GET /v1/payments/history
  Future<List<dynamic>> getPurchaseHistory() async {
    try {
      final response = await _client.get(ApiConfig.paymentHistory);
      final data = response['data'];
      return data is List ? data : [];
    } on ApiException catch (e) {
      throw Exception('Gagal memuat riwayat: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat riwayat.');
    }
  }

  /// Creates a transaction. Returns the transaction ID.
  /// API: POST /v1/transactions { seller_id, items: [{product_id, quantity}] }
  Future<int> createTransaction(int sellerId, int productId) async {
    try {
      final response = await _client.post(
        ApiConfig.transactions,
        body: {
          'seller_id': sellerId,
          'items': [
            {
              'product_id': productId,
              'quantity': 1,
            }
          ]
        },
      );
      // Depending on API response structure, extract the ID
      final data = response['data'] ?? response;
      return data['id'] as int;
    } on ApiException catch (e) {
      throw Exception('Gagal membuat transaksi: ${e.message}');
    } catch (e) {
      throw Exception('Gagal membuat transaksi.');
    }
  }

  /// Pays directly using wallet balance.
  /// API: POST /v1/transactions/pay-wallet { seller_id, product_id }
  Future<bool> payWallet(int sellerId, int productId) async {
    try {
      await _client.post(
        ApiConfig.payWallet,
        body: {
          'seller_id': sellerId,
          'product_id': productId,
        },
      );
      return true;
    } on ApiException catch (e) {
      throw Exception('Pembayaran saldo gagal: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat membayar dengan saldo.');
    }
  }

  /// Creates a Midtrans Snap payment URL.
  /// API: POST /v1/payments/create { transaction_id, customer_details }
  Future<Map<String, dynamic>> createGatewayPayment(
      int transactionId, Map<String, dynamic> customerDetails) async {
    try {
      final response = await _client.post(
        ApiConfig.createPayment,
        body: {
          'transaction_id': transactionId,
          'customer_details': customerDetails,
        },
      );
      return response['data'] ?? response;
    } on ApiException catch (e) {
      debugPrint(
        '[PaymentService] POST ${ApiConfig.createPayment} failed '
        '(${e.statusCode}): ${e.message}',
      );
      throw Exception('Gagal membuka payment gateway: ${e.message}');
    } catch (e) {
      throw Exception('Gagal memuat pembayaran.');
    }
  }

  /// Checks the payment status with Midtrans and forces the backend to sync.
  /// API: GET /v1/payments/status/{orderId}
  Future<void> checkPaymentStatus(String orderId) async {
    try {
      await _client.get('/payments/status/$orderId');
    } catch (e) {
      // It's mostly a sync endpoint, ignore errors if it fails so the 
      // original purchase history fetch can still run.
    }
  }
    /// Creates an escrow transaction.
  /// API: POST /v1/escrow { seller_id, items: [...] }
  Future<Map<String, dynamic>> createEscrow(int sellerId, int productId) async {
    try {
      final response = await _client.post(
        ApiConfig.escrow,
        body: {
          'seller_id': sellerId,
          'items': [
            {
              'product_id': productId,
              'quantity': 1,
            }
          ],
        },
      );
      return response['data'] ?? response;
    } on ApiException catch (e) {
      throw Exception('Gagal membuat escrow: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat membuat escrow.');
    }
  }
}
