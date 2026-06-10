import 'api_client.dart';
import 'api_config.dart';
import 'package:flutter/foundation.dart';

class EscrowService {
  final ApiClient _client = ApiClient();

  /// Initiates a refund for an Escrow (Waiting COD) transaction.
  /// API: POST /v1/escrow/{transactionId}/refund
  Future<void> refundPayment(int transactionId, String refundReason) async {
    final endpoint = ApiConfig.escrowRefund(transactionId);
    try {
      await _client.post(
        endpoint,
        body: {'refund_reason': refundReason},
      );
    } on ApiException catch (e) {
      debugPrint(
        '[EscrowService] POST $endpoint failed (${e.statusCode}): ${e.message}',
      );
      throw Exception('Gagal memproses refund: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memproses refund.');
    }
  }

  /// Claims a payment for the seller using the auth code provided by the buyer.
  /// API: POST /v1/escrow/{transactionId}/claim { auth_code }
  Future<Map<String, dynamic>> claimPayment(
      int transactionId, String authCode) async {
    final endpoint = ApiConfig.escrowClaim(transactionId);
    try {
      final response = await _client.post(
        endpoint,
        body: {'auth_code': authCode},
      );
      return (response['data'] as Map<String, dynamic>?) ?? response;
    } on ApiException catch (e) {
      debugPrint(
        '[EscrowService] POST $endpoint failed (${e.statusCode}): ${e.message}',
      );
      throw Exception('Gagal klaim pembayaran: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat klaim pembayaran.');
    }
  }
}
