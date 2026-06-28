import '../utils/image_url_helper.dart';

class SellerProduct {
  final int id;
  final String name;
  final int price;
  final int stock;
  final String imagePath;
  final String category;
  final String description;
  final String condition;
  final int views;
  final String status;
  final String locationLabel;
  final int? locationRadiusKm;
  final double? latitude;
  final double? longitude;

  SellerProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imagePath = '',
    this.category = '',
    this.description = '',
    this.condition = 'used',
    this.views = 0,
    this.status = 'active',
    this.locationLabel = '',
    this.locationRadiusKm,
    this.latitude,
    this.longitude,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    return SellerProduct(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      price: _parseInt(json['price']),
      stock: _parseInt(json['stock_quantity'] ?? json['stock']),
      imagePath: ImageUrlHelper.resolve(json['image_path'] ?? json['image']),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      condition: json['condition']?.toString() ?? 'used',
      views: _parseInt(json['views']),
      status: json['status']?.toString() ?? 'active',
      locationLabel: json['location_label']?.toString() ?? '',
      locationRadiusKm:
          _parseNullableInt(json['location_radius_km'] ?? json['radius_km']),
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
