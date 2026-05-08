/// A chat room returned by GET /v1/chat/rooms
class ChatRoom {
  final int id;
  final String roomType;
  final ChatUser? otherUser;
  final ChatPreviewMessage? latestMessage;
  final DateTime? updatedAt;

  ChatRoom({
    required this.id,
    required this.roomType,
    this.otherUser,
    this.latestMessage,
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
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
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
      profilePicture: json['profile_picture']?.toString(),
    );
  }
}

class ChatPreviewMessage {
  final String message;
  final DateTime? sentAt;
  final int senderId;
  final bool isRead;

  ChatPreviewMessage({
    required this.message,
    this.sentAt,
    required this.senderId,
    required this.isRead,
  });

  factory ChatPreviewMessage.fromJson(Map<String, dynamic> json) {
    return ChatPreviewMessage(
      message: json['message']?.toString() ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : null,
      senderId: json['sender_id'] ?? 0,
      isRead: json['is_read'] == true,
    );
  }
}
