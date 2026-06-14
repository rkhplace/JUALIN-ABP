import '../utils/image_url_helper.dart';

/// A chat room returned by GET /v1/chat/rooms
class ChatRoom {
  final int id;
  final String roomType;
  final ChatUser? otherUser;
  final ChatPreviewMessage? latestMessage;
  final ChatProduct? product;
  final DateTime? updatedAt;

  ChatRoom({
    required this.id,
    required this.roomType,
    this.otherUser,
    this.latestMessage,
    this.product,
    this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? 0,
      roomType: json['room_type']?.toString() ?? 'private',
      otherUser: json['other_user'] != null
          ? ChatUser.fromJson(json['other_user'] as Map<String, dynamic>)
          : null,
      latestMessage: json['latest_message'] != null
          ? ChatPreviewMessage.fromJson(
              json['latest_message'] as Map<String, dynamic>)
          : null,
      product: json['product'] is Map<String, dynamic>
          ? ChatProduct.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class ChatProduct {
  final int id;
  final String name;
  final num price;
  final dynamic image;
  final int? sellerId;
  final String? sellerName;

  ChatProduct({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.sellerId,
    this.sellerName,
  });

  factory ChatProduct.fromJson(Map<String, dynamic> json) {
    return ChatProduct(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Produk',
      price: json['price'] is num
          ? json['price'] as num
          : num.tryParse(json['price']?.toString() ?? '') ?? 0,
      image: json['image'],
      sellerId: json['seller_id'] is num
          ? (json['seller_id'] as num).toInt()
          : int.tryParse(json['seller_id']?.toString() ?? ''),
      sellerName: json['seller_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
        if (sellerId != null) 'seller_id': sellerId,
        if ((sellerName ?? '').isNotEmpty) 'seller_name': sellerName,
      };
}

class ChatUser {
  final int id;
  final String username;
  final String? profilePicture;

  ChatUser({required this.id, required this.username, this.profilePicture});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      username: json['username']?.toString() ?? 'Pengguna',
      profilePicture: ImageUrlHelper.resolve(
        json['profile_picture'] ?? json['avatar_url'] ?? json['avatar'],
      ),
    );
  }
}

class ChatPreviewMessage {
  final String message;
  final String type;
  final DateTime? sentAt;
  final int senderId;
  final bool isRead;

  ChatPreviewMessage({
    required this.message,
    this.type = 'text',
    this.sentAt,
    required this.senderId,
    required this.isRead,
  });

  factory ChatPreviewMessage.fromJson(Map<String, dynamic> json) {
    return ChatPreviewMessage(
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : null,
      senderId: json['sender_id'] ?? 0,
      isRead: json['is_read'] == true,
    );
  }
}
