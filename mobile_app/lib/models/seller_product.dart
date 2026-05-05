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
      id: json['id'] ?? 0,
      name: json['name'] ?? json['title'] ?? '',
      price: json['price'] != null ? int.tryParse(json['price'].toString()) ?? 0 : 0,
      stock: json['stock'] ?? 0,
      imagePath: json['image_path'] ?? json['image'] ?? '',
      views: json['views'] ?? 0,
      status: json['status'] ?? 'active',
    );
  }
}
