import 'package:flutter/material.dart';
import '../widgets/ui/custom_button.dart';
import '../widgets/ui/custom_input.dart';
import '../services/seller_service.dart';

// Shared form used by both New and Edit screens
class SellerProductFormScreen extends StatefulWidget {
  final bool isEdit;

  const SellerProductFormScreen({super.key, required this.isEdit});

  @override
  State<SellerProductFormScreen> createState() =>
      _SellerProductFormScreenState();
}

class _SellerProductFormScreenState extends State<SellerProductFormScreen> {
  final SellerService _sellerService = SellerService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final price = _priceController.text.trim();
    final stock = _stockController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || price.isEmpty) {
      setState(() => _errorMessage = 'Nama produk dan harga wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _sellerService.createProduct({
        'name': name,
        'category': category.isNotEmpty ? category : 'Umum',
        'price': price,
        'stock_quantity': stock.isNotEmpty ? stock : '0',
        'description': description,
        'condition': 'Bekas',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Placeholder
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.black12, style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate,
                        size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Upload Foto Produk',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomInput(
                label: 'Nama Produk',
                hintText: 'Contoh: iPhone 12 Pro Max 256GB',
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Kategori',
                hintText: 'Contoh: Elektronik',
                controller: _categoryController,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Harga (Rp)',
                hintText: '0',
                keyboardType: TextInputType.number,
                controller: _priceController,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Stok',
                hintText: '0',
                keyboardType: TextInputType.number,
                controller: _stockController,
              ),
              const SizedBox(height: 16),
              CustomInput(
                label: 'Deskripsi',
                hintText: 'Tulis deskripsi produk secara detail',
                controller: _descriptionController,
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Simpan Produk',
                      onPressed: _handleSave,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Named route wrappers
class SellerProductNewScreen extends StatelessWidget {
  const SellerProductNewScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const SellerProductFormScreen(isEdit: false);
}
