import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/seller_product.dart';
import '../services/seller_service.dart';
import '../widgets/ui/frosted_app_bar.dart';

const List<String> _productCategories = [
  'Elektronik',
  'Fashion',
  'Hobi & Olahraga',
  'Rumah Tangga',
  'Aksesoris',
  'Otomotif',
  'Lainnya',
];

const Map<String, String> _productConditions = {
  'new': 'Baru',
  'used': 'Bekas',
};

const List<int> _locationRadiusOptions = [1, 3, 5, 10, 15, 25];
const LatLng _defaultOfferPoint = LatLng(-6.9175, 107.6191);

class _OfferLocationDraft {
  final String label;
  final int radiusKm;
  final double? latitude;
  final double? longitude;

  const _OfferLocationDraft({
    required this.label,
    required this.radiusKm,
    required this.latitude,
    required this.longitude,
  });
}

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
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  SellerProduct? _editingProduct;
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isFormattingStock = false;
  String? _errorMessage;
  bool _didInitializeEditData = false;
  String? _selectedCategory;
  String? _selectedCondition;
  bool _isFormattingPrice = false;
  int _locationRadiusKm = 10;
  double? _latitude;
  double? _longitude;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeEditData || !widget.isEdit) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SellerProduct) {
      _editingProduct = args;
      _nameController.text = args.name;
      _selectedCategory = _normalizeCategory(args.category);
      _selectedCondition = _productConditions.containsKey(args.condition)
          ? args.condition
          : 'used';
      _priceController.text = _formatPriceInput(args.price.toString());
      _stockController.text = _formatPriceInput(args.stock.toString());
      _descriptionController.text = args.description;
      _locationController.text = args.locationLabel;
      _locationRadiusKm = args.locationRadiusKm ?? 10;
      _latitude = args.latitude;
      _longitude = args.longitude;
    }
    _didInitializeEditData = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final stock = _stockController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final description = _descriptionController.text.trim();
    final locationLabel = _locationController.text.trim();
    final priceValue = int.tryParse(price);
    final stockValue = int.tryParse(stock);

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nama produk wajib diisi.');
      return;
    }
    if (priceValue == null || priceValue <= 0) {
      setState(
          () => _errorMessage = 'Harga wajib diisi dan harus angka valid.');
      return;
    }
    if (stockValue == null || stockValue < 0) {
      setState(
          () => _errorMessage = 'Stok wajib diisi dan tidak boleh negatif.');
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      setState(() => _errorMessage = 'Kategori produk wajib dipilih.');
      return;
    }
    if (_selectedCondition == null || _selectedCondition!.isEmpty) {
      setState(() => _errorMessage = 'Kondisi barang wajib dipilih.');
      return;
    }
    if (description.isEmpty) {
      setState(() => _errorMessage = 'Deskripsi produk wajib diisi.');
      return;
    }
    if (locationLabel.isEmpty) {
      setState(() => _errorMessage = 'Lokasi tawaran wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'name': name,
        'category': _selectedCategory!,
        'price': priceValue.toString(),
        'stock_quantity': stockValue.toString(),
        'description': description,
        'condition': _selectedCondition!,
        'status': 'active',
        'location_label': locationLabel,
        'location_radius_km': _locationRadiusKm.toString(),
        'radius_km': _locationRadiusKm.toString(),
      };
      if (_latitude != null) payload['latitude'] = _latitude!.toString();
      if (_longitude != null) payload['longitude'] = _longitude!.toString();

      if (widget.isEdit && _editingProduct != null) {
        await _sellerService.updateProduct(
          _editingProduct!.id,
          payload,
          imageFiles: _selectedImages,
        );
      } else {
        await _sellerService.createProduct(
          payload,
          imageFiles: _selectedImages,
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

  String? _normalizeCategory(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    for (final category in _productCategories) {
      if (category.toLowerCase() == text.toLowerCase()) return category;
    }
    return 'Lainnya';
  }

  String _formatPriceInput(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  String _formatCurrencyPreview(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Rp0';
    return 'Rp${_formatPriceInput(digits)}';
  }

  void _handlePriceChanged(String value) {
    if (_isFormattingPrice) return;
    final formatted = _formatPriceInput(value);
    _isFormattingPrice = true;
    _priceController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingPrice = false;
  }

  void _handleStockChanged(String value) {
    if (_isFormattingStock) return;
    final formatted = _formatPriceInput(value);
    _isFormattingStock = true;
    _stockController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingStock = false;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final picked = await _imagePicker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1600,
        );
        if (picked.isEmpty) return;
        setState(() {
          _selectedImages
            ..clear()
            ..addAll(picked.map((item) => File(item.path)));
        });
        return;
      }

      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() => _selectedImages.add(File(picked.path)));
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

  void _removeSelectedImage(int index) {
    if (index < 0 || index >= _selectedImages.length) return;
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _showLocationSheet() async {
    final mapController = MapController();
    Timer? citySearchDebounce;
    var draftRadius = _locationRadiusKm;
    var draftPoint = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : _defaultOfferPoint;
    var draftLabel = _locationController.text.trim().isEmpty
        ? ''
        : _locationController.text.trim();
    var draftError = '';

    final picked = await showModalBottomSheet<_OfferLocationDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> moveMapToCity(String value) async {
              final city = value.trim();
              if (city.length < 3) return;

              try {
                final point = await _resolveCityPoint(city);
                if (!context.mounted || point == null) return;
                setSheetState(() {
                  draftPoint = point;
                  draftError = '';
                });
                try {
                  mapController.move(point, _zoomForRadius(draftRadius).toDouble());
                } catch (_) {
                  // The map may still be attaching during the first keystrokes.
                }
              } catch (_) {
                if (!context.mounted) return;
                setSheetState(() {
                  draftError =
                      'Kota/area belum ditemukan. Geser peta atau coba nama lain.';
                });
              }
            }

            void applyLocation() {
              if (draftLabel.trim().isEmpty) {
                setSheetState(() {
                  draftError = 'Kota atau area wajib diisi.';
                });
                return;
              }

              if (!sheetContext.mounted) return;
              Navigator.pop(
                sheetContext,
                _OfferLocationDraft(
                  label: draftLabel.trim(),
                  radiusKm: draftRadius,
                  latitude: draftPoint.latitude,
                  longitude: draftPoint.longitude,
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: SingleChildScrollView(
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Ubah Lokasi',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap peta untuk memilih area produk. Pembeli hanya melihat radius, bukan alamat lengkap.',
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: draftLabel,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          draftLabel = value;
                          if (draftError.isNotEmpty) {
                            setSheetState(() => draftError = '');
                          }
                          citySearchDebounce?.cancel();
                          citySearchDebounce = Timer(
                            const Duration(milliseconds: 750),
                            () => moveMapToCity(value),
                          );
                        },
                        onFieldSubmitted: moveMapToCity,
                        decoration: InputDecoration(
                          labelText: 'Kota/Area',
                          hintText: 'Contoh: Bandung, Dago, Antapani',
                          prefixIcon: const Icon(
                            Icons.location_city_outlined,
                            color: Color(0xFFE83030),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE83030),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: draftRadius,
                        items: _locationRadiusOptions
                            .map(
                              (radius) => DropdownMenuItem<int>(
                                value: radius,
                                child: Text('$radius kilometer'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => draftRadius = value);
                          try {
                            mapController.move(
                              draftPoint,
                              _zoomForRadius(value).toDouble(),
                            );
                          } catch (_) {
                            // Keep radius selection usable while the map attaches.
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Radius',
                          prefixIcon: const Icon(
                            Icons.radar_outlined,
                            color: Color(0xFFE83030),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildMapPreview(
                        label: draftLabel,
                        radiusKm: draftRadius,
                        latitude: draftPoint.latitude,
                        longitude: draftPoint.longitude,
                        height: 220,
                        mapController: mapController,
                        onTap: (point) {
                          setSheetState(() {
                            draftPoint = point;
                            draftError = '';
                          });
                        },
                      ),
                      if (draftError.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          draftError,
                          style: const TextStyle(
                            color: Color(0xFFE83030),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: applyLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE83030),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    citySearchDebounce?.cancel();
    if (picked == null || !mounted) return;

    setState(() {
      _locationController.text = picked.label;
      _locationRadiusKm = picked.radiusKm;
      _latitude = picked.latitude;
      _longitude = picked.longitude;
      _errorMessage = null;
    });
  }

  Future<LatLng?> _resolveCityPoint(String city) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': city,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'id',
    });

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'JualinMobile/1.0 (student-demo)',
      },
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;

    final item = Map<String, dynamic>.from(decoded.first as Map);
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lng = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lng == null) return null;

    return LatLng(lat, lng);
  }

  int _zoomForRadius(int radiusKm) {
    if (radiusKm <= 1) return 14;
    if (radiusKm <= 3) return 13;
    if (radiusKm <= 5) return 12;
    if (radiusKm <= 10) return 11;
    if (radiusKm <= 15) return 10;
    return 9;
  }

  Widget _buildMapPreview({
    required String label,
    required int radiusKm,
    required double? latitude,
    required double? longitude,
    double height = 154,
    MapController? mapController,
    ValueChanged<LatLng>? onTap,
  }) {
    final point = latitude != null && longitude != null
        ? LatLng(latitude, longitude)
        : _defaultOfferPoint;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F4),
          border: Border.all(color: const Color(0xFFFFD4D4)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: point,
                initialZoom: _zoomForRadius(radiusKm).toDouble(),
                interactionOptions: InteractionOptions(
                  flags: onTap == null
                      ? InteractiveFlag.none
                      : InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom,
                ),
                onTap: onTap == null ? null : (_, tappedPoint) => onTap(tappedPoint),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.jualin.mobile_app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: point,
                      radius: radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: const Color(0xFFE83030).withValues(alpha: 0.16),
                      borderColor:
                          const Color(0xFFE83030).withValues(alpha: 0.46),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFE83030),
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFE83030),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label.isEmpty ? 'Lokasi belum dipilih' : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Radius $radiusKm km',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      showAppBar: false,
      bottomNavigationBar: _buildBottomAction(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadHeader(),
              const SizedBox(height: 16),
              _buildFormSection(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Foto Produk',
                subtitle: 'Tampilkan produk dengan foto yang terang dan jelas.',
                child: _buildImageUploadCard(),
              ),
              const SizedBox(height: 16),
              _buildFormSection(
                icon: Icons.inventory_2_outlined,
                title: 'Informasi Produk',
                subtitle: 'Buat data produk mudah dipahami pembeli.',
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Nama Produk',
                      hintText: 'Contoh: iPhone 12 Pro Max 256GB',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    _buildPickerField(
                      label: 'Kategori',
                      value: _selectedCategory,
                      hint: 'Pilih kategori',
                      options: {
                        for (final category in _productCategories)
                          category: category,
                      },
                      onChanged: (value) => setState(
                        () => _selectedCategory = value,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPickerField(
                      label: 'Kondisi Barang',
                      value: _selectedCondition,
                      hint: 'Pilih kondisi',
                      options: _productConditions,
                      onChanged: (value) => setState(
                        () => _selectedCondition = value,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormSection(
                icon: Icons.location_on_outlined,
                title: 'Lokasi Tawaran',
                subtitle: 'Tentukan area produk tanpa membagikan titik alamat persis.',
                child: _buildLocationCard(),
              ),
              const SizedBox(height: 16),
              _buildFormSection(
                icon: Icons.payments_outlined,
                title: 'Harga & Stok',
                subtitle: 'Harga otomatis diformat Rupiah saat diketik.',
                child: Column(
                  children: [
                    _buildPriceField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Stok',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      controller: _stockController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _handleStockChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildProductPreviewCard(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorBox(_errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: _buildHeaderCircle(118),
          ),
          Positioned(
            right: 34,
            bottom: -42,
            child: _buildHeaderCircle(92),
          ),
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.isEdit ? 'Edit Produk' : 'Unggah Produk',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: -10,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSave,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isLoading
                  ? 'Menyimpan...'
                  : widget.isEdit
                      ? 'Simpan Perubahan'
                      : 'Simpan Produk',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE83030),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFFE83030).withValues(alpha: 0.28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 24,
            spreadRadius: -10,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFE83030), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE83030), width: 1),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadCard() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImageOptions,
          child: Container(
            height: 214,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8F8), Color(0xFFFFEEEE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFC7C7)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE83030).withValues(alpha: 0.08),
                  blurRadius: 22,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(child: _buildImagePreview()),
                if (_selectedImages.isNotEmpty ||
                    (_editingProduct?.imagePath ?? '').isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE83030),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _selectedImages.length > 1
                            ? 'Cover 1/${_selectedImages.length}'
                            : 'Cover',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_outlined,
                            size: 14, color: Color(0xFFE83030)),
                        SizedBox(width: 5),
                        Text(
                          'Tap untuk pilih',
                          style: TextStyle(
                            color: Color(0xFFE83030),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _selectedImages[index],
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE83030),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: InkWell(
                        onTap: () => _removeSelectedImage(index),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 15,
                            color: Color(0xFFE83030),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _buildImageSourceButton(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: 'Kamera',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildImageSourceButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: 'Galeri Banyak',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.black38, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gunakan foto produk asli, tajam, dan tidak terlalu gelap.',
                  style: TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSourceButton({
    required VoidCallback onPressed,
    required Widget icon,
    required String label,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE83030),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFFFCACA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return AnimatedBuilder(
      animation: _locationController,
      builder: (context, _) {
        final label = _locationController.text.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _showLocationSheet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: label.isEmpty
                        ? Colors.black.withValues(alpha: 0.05)
                        : const Color(0xFFFFCACA),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFEF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        color: Color(0xFFE83030),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.isEmpty ? 'Pilih lokasi tawaran' : label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: label.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black87,
                              fontWeight: label.isEmpty
                                  ? FontWeight.w500
                                  : FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Radius $_locationRadiusKm km',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMapPreview(
              label: label,
              radiusKm: _locationRadiusKm,
              latitude: _latitude,
              longitude: _longitude,
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.privacy_tip_outlined,
                    color: Colors.black38, size: 15),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Pembeli melihat area radius, bukan alamat lengkap.',
                    style: TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Harga (Rp)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _handlePriceChanged,
          decoration: InputDecoration(
            prefixText: 'Rp',
            hintText: '0',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE83030), width: 1),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Tulis kondisi, kelengkapan, dan detail produk',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE83030), width: 1),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
      ],
    );
  }

  Widget _buildProductPreviewCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _nameController,
        _priceController,
        _stockController,
        _descriptionController,
        _locationController,
      ]),
      builder: (context, _) {
        final name = _nameController.text.trim();
        final stock = _stockController.text.trim();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7F7), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD7D7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE83030).withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview Produk',
                      style: TextStyle(
                        color: Color(0xFFE83030),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name.isEmpty ? 'Nama produk' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrencyPreview(_priceController.text),
                      style: const TextStyle(
                        color: Color(0xFFE83030),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedCategory ?? 'Tanpa kategori'} - Stok: ${stock.isEmpty ? '0' : stock}',
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPreviewBadge(
                          Icons.category_outlined,
                          _selectedCategory ?? 'Kategori',
                        ),
                        _buildPreviewBadge(
                          Icons.inventory_2_outlined,
                          '${stock.isEmpty ? '0' : stock} stok',
                        ),
                        _buildPreviewBadge(
                          Icons.place_outlined,
                          _locationController.text.trim().isEmpty
                              ? 'Lokasi'
                              : '$_locationRadiusKm km',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black38),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.black45, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String? value,
    required String hint,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    final displayValue = value == null ? null : options[value] ?? value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPickerSheet(
            title: label,
            value: value,
            options: options,
            onChanged: onChanged,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEFEF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    label == 'Kategori'
                        ? Icons.category_outlined
                        : Icons.verified_outlined,
                    size: 16,
                    color: const Color(0xFFE83030),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayValue ?? hint,
                    style: TextStyle(
                      color: displayValue == null
                          ? Colors.grey[400]
                          : Colors.black87,
                      fontSize: 14,
                      fontWeight: displayValue == null
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPickerSheet({
    required String title,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...options.entries.map(
                (entry) {
                  final selected = entry.key == value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: selected
                          ? const Color(0xFFFFEFEF)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context, entry.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (selected)
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

    if (picked != null) onChanged(picked);
  }

  Widget _buildImagePreview() {
    if (_selectedImages.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_selectedImages.first, fit: BoxFit.cover),
      );
    }

    final existingImage = _editingProduct?.imagePath ?? '';
    if (existingImage.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          existingImage,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          },
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
        Text('Unggah Foto Produk', style: TextStyle(color: Colors.black54)),
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
