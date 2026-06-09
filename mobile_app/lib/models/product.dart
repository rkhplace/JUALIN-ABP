import '../utils/image_url_helper.dart';

class Product {
  final int id;
  final String title;
  final String categoryName;
  final int price;
  final String description;
  final String sellerName;
  final int sellerId;
  final int stock;
  final String imagePath;
  final String condition;
  final bool isNegotiable;

  Product({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.price,
    required this.description,
    required this.sellerName,
    this.sellerId = 0,
    required this.stock,
    this.imagePath = '',
    this.condition = 'Bekas',
    this.isNegotiable = false,
  });

  /// Maps the ProductResponse shape returned by the Laravel API:
  /// {
  ///   "id", "name", "description", "price", "stock_quantity",
  ///   "image", "category" (string), "condition", "status",
  ///   "seller": { "id", "username", "profile_picture", "city" }
  /// }
  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] != null
        ? (json['category'] is Map
            ? (json['category']['name']?.toString() ?? 'Umum')
            : json['category'].toString())
        : 'Umum';

    String sellerName = 'Penjual';
    int sellerId = _parseInt(json['seller_id']);
    if (json['seller'] != null && json['seller'] is Map) {
      final seller = json['seller'] as Map;
      sellerName = seller['username']?.toString() ??
          seller['name']?.toString() ??
          'Penjual';
      sellerId = sellerId == 0 ? _parseInt(seller['id']) : sellerId;
    }

    final imagePath =
        ImageUrlHelper.resolve(json['image'] ?? json['image_path']);

    return Product(
      id: _parseInt(json['id']),
      title: json['name']?.toString() ?? json['title']?.toString() ?? '',
      categoryName: category,
      price: _parseInt(json['price']),
      description: json['description']?.toString() ?? '',
      sellerName: sellerName,
      sellerId: sellerId,
      stock: _parseInt(json['stock_quantity'] ?? json['stock']),
      imagePath: imagePath,
      condition: json['condition']?.toString() ?? 'Bekas',
      isNegotiable: _parseBool(json['is_negotiable']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': title,
        'category': categoryName,
        'price': price,
        'description': description,
        'stock_quantity': stock,
        'image': imagePath,
        'condition': condition,
        'is_negotiable': isNegotiable,
      };
}
