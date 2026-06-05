import 'package:flutter/material.dart';
import '../widgets/ui/custom_button.dart';
import '../services/product_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../models/product.dart';
import '../widgets/ui/login_required_dialog.dart';
import '../widgets/ui/frosted_app_bar.dart';
import '../widgets/ui/logo_loader.dart';
import 'chat_screen.dart';
import '../../utils/formatters.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();
  Product? _product;
  bool _isLoading = true;
  bool _isChatLoading = false;
  String? _errorMessage;

  Future<bool> requireLogin(
    BuildContext context, {
    String message = 'Silakan login terlebih dahulu untuk membeli produk.',
  }) async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!context.mounted) return false;

    if (!isLoggedIn) {
      final shouldLogin = await showLoginRequiredDialog(
        context,
        message: message,
      );
      if (!context.mounted) return false;
      if (shouldLogin) Navigator.pushNamed(context, '/login');
      return false;
    }
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    // Product ID is passed as a route argument: Navigator.pushNamed(context, '/product_detail', arguments: id)
    final productId = ModalRoute.of(context)?.settings.arguments as int?;

    if (productId == null) {
      setState(() {
        _errorMessage = 'ID produk tidak ditemukan.';
        _isLoading = false;
      });
      return;
    }

    try {
      final product = await _productService.getProductDetails(productId);
      if (mounted) {
        setState(() {
          _product = product;
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

  Future<void> _handleChatPenjual() async {
    if (_product == null) return;

    final loggedIn = await requireLogin(
      context,
      message: 'Silakan login terlebih dahulu untuk chat dengan penjual.',
    );
    if (!mounted || !loggedIn) return;

    final sellerId = _product!.sellerId;
    final productId = _product!.id;

    if (sellerId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi penjual tidak tersedia.')),
      );
      return;
    }

    setState(() => _isChatLoading = true);

    try {
      final roomId = await _chatService.startRoom(sellerId, productId);

      if (!mounted) return;

      if (roomId == null) {
        throw Exception('Room ID tidak diterima dari server.');
      }

      // Navigate directly to the ChatRoomScreen with the room ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId,
            roomName: _product!.sellerName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e
                .toString()
                .replaceFirst('Exception: ', 'Gagal membuka chat: ')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChatLoading = false);
    }
  }

  Future<void> _handleReportProduct() async {
    if (_product == null) return;

    final loggedIn = await requireLogin(
      context,
      message: 'Silakan login terlebih dahulu untuk melaporkan produk.',
    );
    if (!mounted || !loggedIn) return;

    final idAndRole = await _authService.getUserIdAndRole();
    if (!mounted) return;

    final currentUserId = idAndRole['id'] as int? ?? 0;
    if (_product!.sellerId != 0 && currentUserId == _product!.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak bisa melaporkan produk Anda sendiri.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showReportDialog();
  }

  void _showReportDialog() {
    const reportReasons = [
      'Produk Terlarang',
      'Penipuan',
      'Pornografi',
      'Hak Cipta',
      'Kategori Tidak Sesuai',
      'Lainnya',
    ];

    String selectedReason = '';
    String description = '';
    String? reasonError;
    String? descriptionError;
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickReportReason() async {
            if (isSubmitting) return;

            final picked = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (sheetContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Pilih Alasan Laporan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...reportReasons.map(
                        (reason) {
                          final isSelected = selectedReason == reason;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected
                                  ? const Color(0xFFFFEFEF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () =>
                                    Navigator.pop(sheetContext, reason),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFE83030)
                                          : Colors.black12,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFFE83030)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFFE83030),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (picked == null || !context.mounted) return;
            setDialogState(() {
              selectedReason = picked;
              reasonError = null;
            });
          }

          Future<void> submitReport() async {
            setDialogState(() {
              reasonError = selectedReason.isEmpty
                  ? 'Pilih alasan laporan produk.'
                  : null;
              descriptionError = description.trim().isEmpty
                  ? 'Deskripsi laporan wajib diisi.'
                  : null;
            });
            if (reasonError != null || descriptionError != null) return;

            setDialogState(() => isSubmitting = true);
            try {
              await _reportService.createProductReport(
                productId: _product!.id,
                type: selectedReason,
                description: description.trim(),
                reportedUserId:
                    _product!.sellerId == 0 ? null : _product!.sellerId,
                reportedUsername: _product!.sellerName,
              );
              if (!context.mounted) return;
              Navigator.pop(dialogContext);
              _showReportSuccessDialog();
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                  backgroundColor: Colors.red,
                ),
              );
              setDialogState(() => isSubmitting = false);
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Laporkan Produk',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pilih jenis laporan dan jelaskan detailnya.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alasan Laporan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildReportReasonField(
                    selectedReason: selectedReason,
                    hint: 'Pilih alasan laporan...',
                    enabled: !isSubmitting,
                    errorText: reasonError,
                    onTap: pickReportReason,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Detail Laporan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    enabled: !isSubmitting,
                    minLines: 4,
                    maxLines: 5,
                    onChanged: (value) {
                      description = value;
                      if (descriptionError != null) {
                        setDialogState(() => descriptionError = null);
                      }
                    },
                    decoration: _reportInputDecoration(
                      selectedReason == 'Lainnya'
                          ? 'Jelaskan alasan custom Anda...'
                          : 'Tuliskan detail masalah produk di sini...',
                      errorText: descriptionError,
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            actions: [
              OutlinedButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE83030),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isSubmitting ? 'Mengirim...' : 'Kirim Laporan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Laporan Berhasil Dikirim',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Laporan produk Anda telah diterima dan akan ditinjau oleh admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE83030),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      title: _product?.title ?? 'Detail Produk',
      body: SafeArea(
        child: _isLoading
            ? const JualinLogoLoader(size: 64)
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _fetchProductDetails();
                            },
                            child: const Text('Coba lagi'),
                          )
                        ],
                      ),
                    ),
                  )
                : _product == null
                    ? const Center(child: Text('Data produk tidak ditemukan.'))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: AspectRatio(
                                  aspectRatio: 1.12,
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: _product!.imagePath.isNotEmpty
                                        ? Image.network(
                                            _product!.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Center(
                                              child: Icon(Icons.image,
                                                  size: 72,
                                                  color: Colors.grey[400]),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(Icons.image,
                                                size: 72,
                                                color: Colors.grey[400]),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Price
                                  Text(
                                    formatCurrency(_product!.price),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE83030),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Title
                                  Text(
                                    _product!.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Badges
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _buildBadge(_product!.categoryName,
                                          Colors.grey[200]!, Colors.black87),
                                      _buildBadge(
                                          _product!.condition,
                                          Colors.orange.withValues(alpha: 0.1),
                                          Colors.orange[800]!),
                                      if (_product!.isNegotiable)
                                        _buildBadge(
                                            'Bisa Nego',
                                            Colors.blue.withValues(alpha: 0.1),
                                            Colors.blue[800]!),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Divider(height: 1),
                                  const SizedBox(height: 14),
                                  // Seller Info
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Color(0xFFF5F5F5),
                                        radius: 20,
                                        child: Icon(Icons.person,
                                            color: Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(_product!.sellerName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const Text('Penjual',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(height: 1),
                                  const SizedBox(height: 14),
                                  // Description
                                  const Text('Deskripsi Produk',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _product!.description.isEmpty
                                        ? 'Tidak ada deskripsi.'
                                        : _product!.description,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Stok: ${_product!.stock}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: _handleReportProduct,
                                    icon: const Icon(Icons.flag_outlined,
                                        size: 18),
                                    label: const Text('Laporkan Produk'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFE83030),
                                      side: const BorderSide(
                                          color: Color(0xFFE83030)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: _product == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: _isChatLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                  child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))),
                            )
                          : CustomButton(
                              text: 'Chat Penjual',
                              isSecondary: true,
                              onPressed: _handleChatPenjual,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Beli Sekarang',
                        onPressed: () async {
                          // Check if user is logged in using existing AuthService
                          final loggedIn = await requireLogin(context);

                          if (!context.mounted) return;
                          if (!loggedIn) return;

                          Navigator.pushNamed(
                            context,
                            '/checkout',
                            arguments: _product,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _reportInputDecoration(String hint, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE83030)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildReportReasonField({
    required String selectedReason,
    required String hint,
    required bool enabled,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: enabled ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError ? Colors.red : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedReason.isEmpty ? hint : selectedReason,
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedReason.isEmpty
                            ? Colors.black38
                            : Colors.black87,
                        fontWeight: selectedReason.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled ? const Color(0xFFE83030) : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
