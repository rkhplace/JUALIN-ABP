import '../utils/image_url_helper.dart';

class Product {
  final int id;
  final String title;
  final String categoryName;
  final int price;
  final String description;
  final String sellerName;
  final int sellerId;
  final String sellerProfilePicture;
  final int stock;
  final String imagePath;
  final List<String> imagePaths;
  final String condition;
  final bool isNegotiable;
  final bool sellerIsVerified;
  final String locationLabel;
  final int? locationRadiusKm;
  final double? latitude;
  final double? longitude;

  Product({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.price,
    required this.description,
    required this.sellerName,
    this.sellerId = 0,
    this.sellerProfilePicture = '',
    required this.stock,
    this.imagePath = '',
    this.imagePaths = const [],
    this.condition = 'Bekas',
    this.isNegotiable = false,
    this.sellerIsVerified = false,
    this.locationLabel = '',
    this.locationRadiusKm,
    this.latitude,
    this.longitude,
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
    String sellerProfilePicture = '';
    if (json['seller'] != null && json['seller'] is Map) {
      final seller = json['seller'] as Map;
      sellerName = seller['username']?.toString() ??
          seller['name']?.toString() ??
          'Penjual';
      sellerId = sellerId == 0 ? _parseInt(seller['id']) : sellerId;
      sellerProfilePicture = ImageUrlHelper.resolve(
        seller['profile_picture'] ?? seller['avatar_url'] ?? seller['avatar'],
      );
    }
    final sellerIsVerified = _parseBool(
      json['seller_verified'] ??
          json['is_seller_verified'] ??
          (json['seller'] is Map
              ? (json['seller'] as Map)['is_verified']
              : null),
    );

    final imagePaths =
        ImageUrlHelper.resolveAll(json['image'] ?? json['image_path']);
    final imagePath = imagePaths.isNotEmpty ? imagePaths.first : '';

    return Product(
      id: _parseInt(json['id']),
      title: json['name']?.toString() ?? json['title']?.toString() ?? '',
      categoryName: category,
      price: _parseInt(json['price']),
      description: json['description']?.toString() ?? '',
      sellerName: sellerName,
      sellerId: sellerId,
      sellerProfilePicture: sellerProfilePicture,
      stock: _parseInt(json['stock_quantity'] ?? json['stock']),
      imagePath: imagePath,
      imagePaths: imagePaths,
      condition: json['condition']?.toString() ?? 'Bekas',
      isNegotiable: _parseBool(json['is_negotiable']),
      sellerIsVerified: sellerIsVerified,
      locationLabel: json['location_label']?.toString() ?? '',
      locationRadiusKm: _parseNullableInt(json['location_radius_km']),
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
        'image': imagePaths.isNotEmpty ? imagePaths : imagePath,
        'seller_profile_picture': sellerProfilePicture,
        'condition': condition,
        'is_negotiable': isNegotiable,
        'seller_verified': sellerIsVerified,
        'location_label': locationLabel,
        'location_radius_km': locationRadiusKm,
        'latitude': latitude,
        'longitude': longitude,
      };
}
