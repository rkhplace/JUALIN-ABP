import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/ui/custom_button.dart';
import '../widgets/ui/custom_input.dart';
import '../models/seller_product.dart';
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

  final ImagePicker _imagePicker = ImagePicker();
  SellerProduct? _editingProduct;
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool _didInitializeEditData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeEditData || !widget.isEdit) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SellerProduct) {
      _editingProduct = args;
      _nameController.text = args.name;
      _categoryController.text = '';
      _priceController.text = args.price.toString();
      _stockController.text = args.stock.toString();
    }
    _didInitializeEditData = true;
  }

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
      final payload = {
        'name': name,
        'category': category.isNotEmpty ? category : 'Umum',
        'price': price,
        'stock_quantity': stock.isNotEmpty ? stock : '0',
        'description': description,
        'condition': 'used',
        'status': 'active',
      };

      if (widget.isEdit && _editingProduct != null) {
        await _sellerService.updateProduct(
          _editingProduct!.id,
          payload,
          imageFile: _selectedImage,
        );
      } else {
        await _sellerService.createProduct(
          payload,
          imageFile: _selectedImage,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit
                ? 'Produk berhasil diperbarui!'
                : 'Produk berhasil ditambahkan!'),
          ),
        );
        Navigator.pop(context, true);
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() => _selectedImage = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = source == ImageSource.camera
            ? 'Gagal membuka kamera. Pastikan permission kamera aktif.'
            : 'Gagal memilih gambar.';
      });
    }
  }

  Future<void> _showImageOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      _pickImage(source);
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
              GestureDetector(
                onTap: _showImageOptions,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
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

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    }

    final existingImage = _editingProduct?.imagePath ?? '';
    if (existingImage.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          existingImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text('Upload Foto Produk', style: TextStyle(color: Colors.black54)),
      ],
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
