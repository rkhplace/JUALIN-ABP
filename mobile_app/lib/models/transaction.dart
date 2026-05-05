/// Represents a single transaction (which serves as a conversation thread
/// since the API has no dedicated chat endpoint).
class Transaction {
  final int id;
  final String status;
  final double totalAmount;
  final String? authCode;
  final DateTime createdAt;
  final TransactionParty? customer;
  final TransactionParty? seller;
  final List<TransactionItem> items;

  Transaction({
    required this.id,
    required this.status,
    required this.totalAmount,
    this.authCode,
    required this.createdAt,
    this.customer,
    this.seller,
    this.items = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      status: json['status']?.toString() ?? 'pending',
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString()) ?? 0
          : 0,
      authCode: json['auth_code']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customer: json['customer'] != null
          ? TransactionParty.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? TransactionParty.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      items: json['items'] is List
          ? (json['items'] as List)
              .map((i) => TransactionItem.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class TransactionParty {
  final int id;
  final String username;
  final String? profilePicture;

  TransactionParty({
    required this.id,
    required this.username,
    this.profilePicture,
  });

  factory TransactionParty.fromJson(Map<String, dynamic> json) {
    return TransactionParty(
      id: json['id'] ?? 0,
      username: json['username']?.toString() ??
          json['name']?.toString() ??
          'Pengguna',
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}

class TransactionItem {
  final int productId;
  final String productName;
  final int quantity;
  final double subtotal;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return TransactionItem(
      productId: json['product_id'] ?? 0,
      productName: product is Map
          ? (product['name']?.toString() ?? 'Produk')
          : 'Produk',
      quantity: json['quantity'] ?? 1,
      subtotal: json['subtotal'] != null
          ? double.tryParse(json['subtotal'].toString()) ?? 0
          : 0,
    );
  }
}
