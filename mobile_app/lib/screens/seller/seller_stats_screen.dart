import 'package:flutter/material.dart';
import '../../services/seller_service.dart';

class SellerStatsScreen extends StatefulWidget {
  const SellerStatsScreen({super.key});

  @override
  State<SellerStatsScreen> createState() => _SellerStatsScreenState();
}

class _SellerStatsScreenState extends State<SellerStatsScreen> {
  final SellerService _sellerService = SellerService();

  String _period = 'Month';
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final stats = await _sellerService.getSellerStats(period: _period);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic val) {
    int amount = 0;
    if (val is num) {
      amount = val.toInt();
    } else if (val is String) {
      amount = double.tryParse(val)?.toInt() ?? 0;
    }
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Statistik Penjualan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE83030),
        onRefresh: _fetchStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE83030)))
            : _errorMessage != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _fetchStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final balance = _stats?['balance'] ?? 0;
    final totalSales = _stats?['total_sales'] ?? balance;
    final completedTransactions =
        _stats?['total_completed_transactions'] ?? _stats?['valid_order_count'] ?? 0;
    final transferred = _stats?['transferred'] ?? 0;
    final chartData = (_stats?['chart_data'] as List<dynamic>?) ?? [];
    final walletBalance = _stats?['wallet_balance'] ?? balance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Balance Card ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE83030), Color(0xFFE84444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE83030).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo Tersedia',
                style: TextStyle(color: Colors.white70, fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                _formatCurrency(walletBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/seller_withdraw')
                    .then((_) => _fetchStats()),
                icon: const Icon(Icons.account_balance_wallet, size: 18),
                label: const Text('Tarik Saldo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE83030),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Summary Row ───────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Penjualan',
                _formatCurrency(totalSales),
                Icons.trending_up,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Transaksi Selesai',
                completedTransactions.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Sudah Ditransfer',
          _formatCurrency(transferred),
          Icons.account_balance,
          Colors.purple,
        ),
        const SizedBox(height: 16),

        // ── Period Toggle ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grafik Pendapatan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Period selector
              Row(
                children: ['Week', 'Month', 'Year'].map((p) {
                  final selected = _period == p;
                  final labels = {'Week': 'Minggu', 'Month': 'Bulan', 'Year': 'Tahun'};
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _period = p);
                        _fetchStats();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE83030) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          labels[p] ?? p,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black54,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Chart (simple bar-style list if no chart lib)
              chartData.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Belum ada data pendapatan untuk periode ini.',
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _buildSimpleChart(chartData),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<dynamic> data) {
    // Find the max income for scaling
    double maxIncome = 1;
    for (final item in data) {
      final incomeRaw = (item as Map)['income'];
      double inc = 0.0;
      if (incomeRaw is num) {
        inc = incomeRaw.toDouble();
      } else if (incomeRaw is String) {
        inc = double.tryParse(incomeRaw) ?? 0.0;
      }
      if (inc > maxIncome) maxIncome = inc;
    }

    return Column(
      children: data.map((item) {
        final map = item as Map<String, dynamic>;
        final label = map['label']?.toString() ?? '';
        final mapMap = map['income'];
        double income = 0.0;
        if (mapMap is num) {
          income = mapMap.toDouble();
        } else if (mapMap is String) {
          income = double.tryParse(mapMap) ?? 0.0;
        }
        final ratio = (income / maxIncome).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE83030).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  _formatCurrency(income),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
