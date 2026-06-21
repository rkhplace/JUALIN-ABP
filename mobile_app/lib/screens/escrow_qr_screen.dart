import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/ui/frosted_app_bar.dart';

class EscrowQrScreen extends StatefulWidget {
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

  @override
  State<EscrowQrScreen> createState() => _EscrowQrScreenState();
}

class _EscrowQrScreenState extends State<EscrowQrScreen>
    with WidgetsBindingObserver {
  Timer? _expiryTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateRemaining();
    _expiryTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final expiresAt = widget.expiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _expiryTimer?.cancel();
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (mounted) setState(() => _remainingSeconds = remaining);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiryTimer?.cancel();
    super.dispose();
  }

  String _payload() {
    final payload = {
      'type': 'payment_code',
      'transaction_id': widget.transactionId,
      'amount': widget.amount,
      'seller_id': widget.sellerId,
      if (widget.authCode != null) 'auth_code': widget.authCode,
    };
    return jsonEncode(payload);
  }

  String _formatRp(int val) {
    final f = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return f.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final payloadString = _payload();
    return FrostedScaffold(
      title: 'QR Kode Pembayaran',
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
              _formatRp(widget.amount),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi: ${widget.transactionId}',
              style: const TextStyle(fontSize: 12),
            ),
            if (widget.authCode != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Kode: ${widget.authCode}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: widget.authCode!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode disalin ke clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Salin'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 36)),
                  ),
                ],
              ),
            ],
            const Spacer(),
            if (widget.expiresAt != null)
              Text(
                'Otomatis tersembunyi dalam ${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE83030),
                    fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}
