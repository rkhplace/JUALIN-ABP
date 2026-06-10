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
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
