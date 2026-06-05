class SellerProduct {
  final int id;
  final String name;
  final int price;
  final int stock;
  final String imagePath;
  final int views;
  final String status;

  SellerProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imagePath = '',
    this.views = 0,
    this.status = 'active',
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    return SellerProduct(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      price: _parseInt(json['price']),
      stock: _parseInt(json['stock_quantity'] ?? json['stock']),
      imagePath: _parseImagePath(json['image_path'] ?? json['image']),
      views: _parseInt(json['views']),
      status: json['status']?.toString() ?? 'active',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _parseImagePath(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.first?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }
}
