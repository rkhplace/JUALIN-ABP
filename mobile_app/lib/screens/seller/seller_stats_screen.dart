import 'package:flutter/material.dart';
import '../../services/seller_service.dart';
import '../../widgets/ui/frosted_app_bar.dart';
import '../../widgets/ui/logo_loader.dart';

class SellerStatsScreen extends StatefulWidget {
  const SellerStatsScreen({super.key});

  @override
  State<SellerStatsScreen> createState() => _SellerStatsScreenState();
}

class _SellerStatsScreenState extends State<SellerStatsScreen> {
  final SellerService _sellerService = SellerService();

  String _period = 'Month';
  String _chartType = 'sales';
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
      final stats = await _sellerService.getSellerStats(
        period: _period,
        type: _chartType,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic val) {
    int amount = 0;
    if (val is num) {
      amount = val.toInt();
    } else if (val is String) {
      amount = double.tryParse(val)?.toInt() ?? 0;
    }
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      showAppBar: false,
      body: RefreshIndicator(
        color: const Color(0xFFE83030),
        onRefresh: _fetchStats,
        child: SafeArea(
          child: _isLoading
              ? const JualinLogoLoader(size: 64)
              : _errorMessage != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed('/seller_main');
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _fetchStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final balance = _stats?['balance'] ?? 0;
    final totalSales = _stats?['total_sales'] ?? balance;
    final completedTransactions = _stats?['total_completed_transactions'] ??
        _stats?['valid_order_count'] ??
        0;
    final transferred = _stats?['transferred'] ?? 0;
    final chartData = (_stats?['chart_data'] as List<dynamic>?) ?? [];
    final walletBalance = _stats?['wallet_balance'] ?? balance;
    final chartTitle =
        _chartType == 'sales' ? 'Grafik Penjualan' : 'Grafik Penarikan Saldo';
    final emptyText = _chartType == 'sales'
        ? 'Belum ada data penjualan untuk periode ini.'
        : 'Belum ada data penarikan saldo untuk periode ini.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _buildPageHeader(),
                const SizedBox(height: 14),
                _buildBalanceHero(walletBalance),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Penjualan',
                        _formatCurrency(totalSales),
                        Icons.trending_up,
                        const Color(0xFF1687FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Transaksi Selesai',
                        completedTransactions.toString(),
                        Icons.check_circle_outline,
                        const Color(0xFF22A447),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'Sudah Ditransfer',
                  _formatCurrency(transferred),
                  Icons.account_balance,
                  const Color(0xFF9C27B0),
                  wide: true,
                  actionLabel: 'Riwayat',
                  onActionTap: () => Navigator.pushNamed(
                    context,
                    '/seller_withdrawals',
                  ).then((_) => _fetchStats()),
                ),
                const SizedBox(height: 16),
                _buildChartCard(chartTitle, emptyText, chartData),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFF64A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83030).withValues(alpha: 0.24),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -32,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.13),
                  width: 2,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.arrow_back_rounded,
                onTap: _handleBack,
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistik Penjualan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pantau saldo, penjualan, dan penarikan toko.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBalanceHero(dynamic walletBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE83030), Color(0xFFF64A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83030).withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -34,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Saldo Tersedia',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _formatCurrency(walletBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/seller_withdraw',
                ).then((_) => _fetchStats()),
                icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                label: const Text('Tarik Saldo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE83030),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    String chartTitle,
    String emptyText,
    List<dynamic> chartData,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFFE83030),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chartTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Pantau performa berdasarkan periode pilihan.',
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSegmentedSurface(
            children: [
              _buildChartTypeButton('sales', 'Penjualan'),
              _buildChartTypeButton('withdraw', 'Penarikan'),
            ],
          ),
          const SizedBox(height: 10),
          _buildSegmentedSurface(
            children: ['Week', 'Month', 'Year'].map((p) {
              final labels = {
                'Week': 'Minggu',
                'Month': 'Bulan',
                'Year': 'Tahun',
              };
              return _buildPeriodButton(p, labels[p] ?? p);
            }).toList(),
          ),
          const SizedBox(height: 16),
          chartData.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      emptyText,
                      style:
                          const TextStyle(color: Colors.black38, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildLineChart(chartData),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool wide = false,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 18 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(width: 10),
            Material(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onActionTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: color,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentedSurface({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: children),
    );
  }

  Widget _buildChartTypeButton(String value, String label) {
    final selected = _chartType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _chartType = value);
          _fetchStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE83030) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE83030).withValues(alpha: 0.24),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final selected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _period = value);
          _fetchStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      spreadRadius: -5,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFFE83030) : Colors.black45,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> data) {
    final points = data.map((item) {
      final map = item as Map<String, dynamic>;
      final raw = map['amount'] ?? map['income'] ?? map['value'] ?? 0;
      final amount = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
      return _ChartPoint(
        label: map['label']?.toString() ?? '',
        amount: amount,
      );
    }).toList();

    final total = points.fold<double>(0, (sum, point) => sum + point.amount);
    final metricLabel = _chartType == 'sales'
        ? 'Nominal penjualan (Rp)'
        : 'Nominal penarikan (Rp)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 226,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: CustomPaint(
            painter: _SellerLineChartPainter(
              points,
              yAxisLabel: metricLabel,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                points.first.label,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                points.last.label,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD7D7)),
          ),
          child: Text(
            'Total ${_chartType == 'sales' ? 'penjualan' : 'penarikan saldo'}: ${_formatCurrency(total)}',
            style: const TextStyle(
              color: Color(0xFFE83030),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPoint {
  final String label;
  final double amount;

  const _ChartPoint({required this.label, required this.amount});
}

String _formatCompactCurrency(double value) {
  final amount = value.round();
  if (amount <= 0) return 'Rp0';
  if (amount >= 1000000000) {
    final text =
        (amount / 1000000000).toStringAsFixed(amount % 1000000000 == 0 ? 0 : 1);
    return 'Rp${text.replaceAll('.', ',')} M';
  }
  if (amount >= 1000000) {
    final text =
        (amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1);
    return 'Rp${text.replaceAll('.', ',')} jt';
  }
  if (amount >= 1000) {
    final text = (amount / 1000)
        .toStringAsFixed(amount < 10000 && amount % 1000 != 0 ? 1 : 0);
    return 'Rp$text rb';
  }
  return 'Rp$amount';
}

class _SellerLineChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final String yAxisLabel;

  const _SellerLineChartPainter(
    this.points, {
    required this.yAxisLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const chartPadding = EdgeInsets.fromLTRB(66, 34, 16, 28);
    final chartRect = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.horizontal,
      size.height - chartPadding.vertical,
    );

    final maxAmount = points
        .map((point) => point.amount)
        .fold<double>(0, (max, value) => value > max ? value : max);
    final safeMax = maxAmount <= 0 ? 1 : maxAmount;

    _drawText(
      canvas,
      yAxisLabel,
      Offset(chartRect.left, 11),
      const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: chartRect.width,
    );

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = chartRect.top + chartRect.height * (i / 4);
      final value = safeMax * (1 - i / 4);
      _drawText(
        canvas,
        _formatCompactCurrency(value),
        Offset(8, y - 7),
        const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        maxWidth: chartPadding.left - 14,
      );
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + (chartRect.width * i / (points.length - 1));
      final y =
          chartRect.bottom - (chartRect.height * (points[i].amount / safeMax));
      offsets.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(offsets.first.dx, chartRect.bottom);
    for (final offset in offsets) {
      fillPath.lineTo(offset.dx, offset.dy);
    }
    fillPath
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x30E83030), Color(0x00E83030)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      linePath.lineTo(offsets[i].dx, offsets[i].dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFE83030)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = const Color(0xFFE83030);
    final dotBorderPaint = Paint()..color = Colors.white;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 5.4, dotBorderPaint);
      canvas.drawCircle(offset, 3.1, dotPaint);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SellerLineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.yAxisLabel != yAxisLabel;
  }
}
