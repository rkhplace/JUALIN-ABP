import 'chat_room.dart';

/// A single chat message returned by GET /v1/chat/rooms/{roomId}/messages
class ChatMessage {
  final int id;
  final int chatRoomId;
  final int senderId;
  final String message;
  final String type;
  final ChatProduct? product;
  final DateTime? sentAt;
  final bool isRead;
  final ChatSender? sender;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.message,
    this.type = 'text',
    this.product,
    this.sentAt,
    required this.isRead,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      chatRoomId: json['chat_room_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      product: _parseProduct(json['product_data'] ?? json['product']),
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : null,
      isRead: json['is_read'] == true,
      sender: json['sender'] != null
          ? ChatSender.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isProductPreview => type == 'product' && product != null;
  bool get isImage => type == 'image' && message.isNotEmpty;

  static ChatProduct? _parseProduct(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ChatProduct.fromJson(value);
    }
    if (value is Map) {
      return ChatProduct.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }
}

class ChatSender {
  final int id;
  final String username;
  final String? profilePicture;

  ChatSender({required this.id, required this.username, this.profilePicture});

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    return ChatSender(
      id: json['id'] ?? 0,
      username: json['username']?.toString() ?? 'Pengguna',
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}
