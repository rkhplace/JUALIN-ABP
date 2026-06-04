import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EscrowQrScreen extends StatelessWidget {
  final String transactionId;
  final int amount;
  final String sellerId;
  final String? authCode;
  final DateTime? expiresAt;

  const EscrowQrScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.sellerId,
    this.authCode,
    this.expiresAt,
  });

  String _payload() {
    final payload = {
      'type': 'payment_code',
      'transaction_id': transactionId,
      'amount': amount,
      'seller_id': sellerId,
      if (authCode != null) 'auth_code': authCode,
    };
    return jsonEncode(payload);
  }

  String _formatRp(int val) {
    final f = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return f.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final payloadString = _payload();
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kode Pembayaran'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Tunjukkan QR ini ke penjual agar mereka bisa scan kode pembayaran.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Center(
              child: QrImageView(
                data: payloadString,
                version: QrVersions.auto,
                size: 240,
                gapless: false,
                errorStateBuilder: (_, __) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatRp(amount),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi: $transactionId',
              style: const TextStyle(fontSize: 12),
            ),
            if (authCode != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Kode: $authCode',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: authCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode disalin ke clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Salin'),
                    style:
                        ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                  ),
                ],
              ),
            ],
            const Spacer(),
            if (expiresAt != null)
              Text(
                'Berlaku sampai: ${DateFormat('dd MMM yyyy HH:mm').format(expiresAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
            ),
          ],
        ),
      ),
    );
  }
}