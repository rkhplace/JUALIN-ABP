import 'package:flutter/foundation.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import 'api_client.dart';
import 'api_config.dart';

class ChatService {
  final ApiClient _client = ApiClient();

  // ── Chat Rooms ───────────────────────────────────────────────────────────

  /// Fetches all chat rooms the authenticated user is part of.
  ///
  /// API: GET /v1/chat/rooms
  /// Returns: { success, data: [...rooms] }
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      debugPrint(
          '[ChatService] getChatRooms → calling ${ApiConfig.baseUrl}${ApiConfig.chatRooms}');
      final response = await _client.get(ApiConfig.chatRooms);
      debugPrint(
          '[ChatService] getChatRooms ← response keys: ${response.keys.toList()}');

      // API returns: { success, data: [...rooms] }
      final rawList = response['data'];
      debugPrint(
          '[ChatService] getChatRooms data type: ${rawList.runtimeType}  content: $rawList');

      if (rawList is! List) {
        debugPrint(
            '[ChatService] getChatRooms: data is not a List, returning []');
        return [];
      }

      final rooms = rawList
          .map((json) => ChatRoom.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('[ChatService] getChatRooms: parsed ${rooms.length} rooms');
      return rooms;
    } on ApiException catch (e) {
      debugPrint(
          '[ChatService] getChatRooms ApiException: ${e.statusCode} ${e.message}');
      if (e.statusCode == 401) {
        throw Exception('Sesi habis. Silakan login ulang.');
      }
      throw Exception('Gagal memuat pesan: ${e.message}');
    } catch (e) {
      debugPrint('[ChatService] getChatRooms error: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // ── Messages in a Room ───────────────────────────────────────────────────

  /// Fetches all messages in [roomId], sorted oldest → newest.
  ///
  /// API: GET /v1/chat/rooms/{roomId}/messages
  /// Backend uses ->paginate() so ApiResponse wraps the paginator:
  ///   { success, data: { data: [...messages], links: {...}, meta: {...} } }
  Future<List<ChatMessage>> getMessages(int roomId) async {
    try {
      debugPrint(
          '[ChatService] getMessages(roomId=$roomId) → calling ${ApiConfig.chatMessages(roomId)}');
      final response = await _client.get(ApiConfig.chatMessages(roomId));
      debugPrint(
          '[ChatService] getMessages ← response keys: ${response.keys.toList()}');

      // Backend uses ->paginate(), so data is a paginator object.
      // ApiResponse::success wraps it as: { success, data: { data: [...], links: {...}, meta: {...} } }
      // We therefore need response['data']['data'] for the actual message list.
      final outer = response['data'];
      debugPrint('[ChatService] getMessages outer type: ${outer.runtimeType}');

      List<dynamic> rawList;
      if (outer is List) {
        // Non-paginated fallback (in case backend changes)
        rawList = outer;
      } else if (outer is Map && outer['data'] is List) {
        // Paginated: { data: [...], meta: {...}, links: {...} }
        rawList = outer['data'] as List;
      } else {
        debugPrint(
            '[ChatService] getMessages: unexpected data shape, returning []');
        return [];
      }

      debugPrint('[ChatService] getMessages: found ${rawList.length} messages');
      return rawList
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint(
          '[ChatService] getMessages ApiException: ${e.statusCode} ${e.message}');
      if (e.statusCode == 401) {
        throw Exception('Sesi habis. Silakan login ulang.');
      }
      if (e.statusCode == 404) throw Exception('Ruang chat tidak ditemukan.');
      throw Exception('Gagal memuat pesan: ${e.message}');
    } catch (e) {
      debugPrint('[ChatService] getMessages error: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // ── Send Message ─────────────────────────────────────────────────────────

  /// Sends a message in [roomId].
  ///
  /// API: POST /v1/chat/rooms/{roomId}/messages
  Future<ChatMessage?> sendMessage(int roomId, String text) async {
    try {
      debugPrint(
          '[ChatService] sendMessage(roomId=$roomId) text="${text.substring(0, text.length > 30 ? 30 : text.length)}"');
      final response = await _client.post(
        ApiConfig.chatMessages(roomId),
        body: {'message': text},
      );

      final data = response['data'];
      if (data == null) return null;

      // sendMessage returns a single message object (not paginated)
      if (data is Map<String, dynamic>) {
        return ChatMessage.fromJson(data);
      }
      debugPrint(
          '[ChatService] sendMessage: unexpected data type: ${data.runtimeType}');
      return null;
    } on ApiException catch (e) {
      debugPrint(
          '[ChatService] sendMessage ApiException: ${e.statusCode} ${e.message}');
      throw Exception('Gagal mengirim pesan: ${e.message}');
    } catch (e) {
      debugPrint('[ChatService] sendMessage error: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  Future<ChatMessage?> sendProductMessage(
    int roomId,
    ChatProduct product,
  ) async {
    try {
      debugPrint(
          '[ChatService] sendProductMessage(roomId=$roomId, productId=${product.id})');
      final response = await _client.post(
        ApiConfig.chatProductMessage(roomId),
        body: {'product_data': product.toJson()},
      );

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return ChatMessage.fromJson(data);
      }
      return null;
    } on ApiException catch (e) {
      debugPrint(
          '[ChatService] sendProductMessage ApiException: ${e.statusCode} ${e.message}');
      throw Exception('Gagal mengirim preview produk: ${e.message}');
    } catch (e) {
      debugPrint('[ChatService] sendProductMessage error: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // ── Start / Find Private Room ─────────────────────────────────────────────

  /// Finds or creates a private chat room between the buyer and [sellerId].
  ///
  /// API: POST /v1/chat/rooms/start
  /// Returns the room ID, or null on failure.
  Future<int?> startRoom(int sellerId, int productId) async {
    try {
      debugPrint(
          '[ChatService] startRoom(sellerId=$sellerId, productId=$productId)');
      final response = await _client.post(
        ApiConfig.chatRoomsStart,
        body: {
          'seller_id': sellerId,
          'product_id': productId,
        },
      );
      final data = response['data'];
      if (data is Map) {
        final rId = data['room_id'];
        if (rId is num) return rId.toInt();
        if (rId is String) return int.tryParse(rId);
      }
      return null;
    } on ApiException catch (e) {
      debugPrint(
          '[ChatService] startRoom ApiException: ${e.statusCode} ${e.message}');
      throw Exception('Gagal membuka chat: ${e.message}');
    } catch (e) {
      debugPrint('[ChatService] startRoom error: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // ── Get Current Authenticated User ID ─────────────────────────────────────

  /// Returns the currently authenticated user's ID by calling GET /me.
  ///
  /// IMPORTANT: /me returns a flat JSON user object directly (NOT wrapped in {data: ...}).
  /// The ApiClient._decode() wraps non-Map responses, but since /me IS a Map,
  /// it returns it as-is. So we read 'id' directly from response, not response['data']['id'].
  Future<int?> getMe() async {
    try {
      debugPrint(
          '[ChatService] getMe() → calling ${ApiConfig.baseUrl}${ApiConfig.me}');
      final response = await _client.get(ApiConfig.me);
      debugPrint(
          '[ChatService] getMe ← response keys: ${response.keys.toList()}');

      // /me returns the user directly: { id, username, email, role, ... }
      // ApiClient._decode() returns it as-is since it's already a Map<String, dynamic>.
      // Try response directly first (flat), then fall back to response['data'] wrapper.
      int? resolveId(dynamic raw) {
        if (raw is num) return raw.toInt();
        if (raw is String) return int.tryParse(raw);
        return null;
      }

      // Flat /me response
      if (response.containsKey('id')) {
        final id = resolveId(response['id']);
        debugPrint('[ChatService] getMe: resolved id from flat response: $id');
        return id;
      }

      // Wrapped in data (in case backend changes to standard format)
      if (response['data'] is Map) {
        final id = resolveId((response['data'] as Map)['id']);
        debugPrint('[ChatService] getMe: resolved id from data wrapper: $id');
        return id;
      }

      debugPrint('[ChatService] getMe: could not find id in response');
      return null;
    } catch (e) {
      debugPrint('[ChatService] getMe error: $e');
      return null;
    }
  }
}
