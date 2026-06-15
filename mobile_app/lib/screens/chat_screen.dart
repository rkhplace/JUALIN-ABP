import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ui/app_chrome.dart';
import '../widgets/ui/login_required_dialog.dart';
import '../widgets/ui/frosted_app_bar.dart';
import '../widgets/ui/logo_loader.dart';
import '../widgets/ui/user_avatar.dart';
import '../services/chat_service.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../utils/formatters.dart';
import '../utils/image_url_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat Rooms List Screen
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String fallbackRoute;

  const ChatScreen({super.key, this.fallbackRoute = '/main'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  List<ChatRoom> _rooms = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _errorMessage;
  int? _currentUserId;
  String _searchQuery = '';
  String _roomFilter = 'newest';

  List<ChatRoom> get _filteredRooms {
    final query = _searchQuery.trim().toLowerCase();

    final rooms = _rooms.where((room) {
      final matchesFilter =
          _roomFilter == 'unread' ? _isUnreadRoom(room) : true;
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final name = room.otherUser?.username.toLowerCase() ?? '';
      final preview = room.latestMessage?.message.toLowerCase() ?? '';
      final product = room.product?.name.toLowerCase() ?? '';
      final seller = room.product?.sellerName?.toLowerCase() ?? '';
      return name.contains(query) ||
          preview.contains(query) ||
          product.contains(query) ||
          seller.contains(query);
    }).toList();

    rooms.sort((a, b) {
      final aTime = _roomSortTime(a);
      final bTime = _roomSortTime(b);
      if (_roomFilter == 'oldest') {
        return aTime.compareTo(bTime);
      }
      return bTime.compareTo(aTime);
    });

    return rooms;
  }

  bool _isUnreadRoom(ChatRoom room) {
    final latest = room.latestMessage;
    return latest != null &&
        !latest.isRead &&
        latest.senderId != _currentUserId;
  }

  DateTime _roomSortTime(ChatRoom room) {
    return room.updatedAt ??
        room.latestMessage?.sentAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
      return;
    }

// read stored user id first, fallback to API
    _currentUserId = prefs.getInt('user_id');
    if (_currentUserId == null) {
      final id = await _chatService.getMe();
      if (id != null) {
        _currentUserId = id;
        await prefs.setInt('user_id', id);
      }
    }

    setState(() => _isLoggedIn = true);

    try {
      final rooms = await _chatService.getChatRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(widget.fallbackRoute);
  }

  @override
  Widget build(BuildContext context) {
    return AppChrome(
      showTopBar: false,
      showNavbar: false,
      showSearch: false,
      showLogo: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChatHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE83030), Color(0xFFF64A4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE83030).withValues(alpha: 0.34),
              blurRadius: 32,
              spreadRadius: -9,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -30,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.13),
                    width: 2,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: _handleBack,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pesan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _rooms.isEmpty
                            ? 'Belum ada percakapan aktif.'
                            : '${_rooms.length} percakapan aktif',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const JualinLogoLoader(size: 64);

    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Masuk untuk melihat pesan',
                style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE83030),
                  foregroundColor: Colors.white),
              onPressed: () async {
                final shouldLogin = await showLoginRequiredDialog(
                  context,
                  message: 'Silakan login terlebih dahulu untuk membuka chat.',
                );
                if (!mounted || !shouldLogin) return;
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Masuk Sekarang'),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage!,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: _loadRooms,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi')),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada pesan',
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            SizedBox(height: 8),
            Text('Mulai percakapan dengan penjual.',
                style: TextStyle(color: Colors.black38, fontSize: 13)),
          ],
        ),
      );
    }

    final rooms = _filteredRooms;

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        itemCount: rooms.length + 1,
        separatorBuilder: (_, __) => const SizedBox.shrink(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _buildChatSearchBar(),
                _buildChatFilterBar(),
                if (rooms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 72),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.black26),
                        SizedBox(height: 10),
                        Text(
                          'Percakapan tidak ditemukan',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Coba gunakan kata kunci lain.',
                          style: TextStyle(color: Colors.black38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }

          return _buildRoomTile(rooms[index - 1]);
        },
      ),
    );
  }

  Widget _buildChatFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChatFilterChip(
              value: 'newest',
              label: 'Terbaru',
              icon: Icons.schedule_outlined,
            ),
            _buildChatFilterChip(
              value: 'oldest',
              label: 'Terlama',
              icon: Icons.history_outlined,
            ),
            _buildChatFilterChip(
              value: 'unread',
              label: 'Belum Dibaca',
              icon: Icons.mark_chat_unread_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatFilterChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isActive = _roomFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _roomFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE83030) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFE83030)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? const Color(0xFFE83030) : Colors.black)
                    .withValues(alpha: isActive ? 0.18 : 0.035),
                blurRadius: isActive ? 16 : 10,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? Colors.white : const Color(0xFFE83030),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 24,
            spreadRadius: -9,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari percakapan...',
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFE83030)),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE83030), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTile(ChatRoom room) {
    final other = room.otherUser;
    final latest = room.latestMessage;
    final name = other?.username ?? 'Ruang Pesan #${room.id}';
    final avatarUrl = ImageUrlHelper.resolve(other?.profilePicture);
    final preview = latest == null
        ? 'Mulai percakapan...'
        : latest.type == 'image'
            ? 'Mengirim foto'
            : latest.message;
    final time = room.updatedAt != null
        ? '${room.updatedAt!.day}/${room.updatedAt!.month}'
        : '';
    final unread =
        latest != null && !latest.isRead && latest.senderId != _currentUserId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: room.id,
              roomName: name,
              roomAvatarUrl: avatarUrl,
              product: room.product,
            ),
          ),
        ).then((_) => _loadRooms());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 26,
              spreadRadius: -10,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(name: name, imageUrl: avatarUrl, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                unread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread ? Colors.black87 : Colors.black54,
                            fontSize: 13,
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE83030),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Chat Room Message Thread Screen
// ─────────────────────────────────────────────────────────────────────────────

class ChatRoomScreen extends StatefulWidget {
  final int roomId;
  final String roomName;
  final String? roomAvatarUrl;
  final ChatProduct? product;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    this.roomAvatarUrl,
    this.product,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSendingImage = false;
  bool _isFetchingMessages = false;
  String? _errorMessage;
  int? _currentUserId; // real authenticated user ID for bubble alignment
  late String _roomAvatarUrl;
  Timer? _messagePoller;

  @override
  void initState() {
    super.initState();
    _roomAvatarUrl = ImageUrlHelper.resolve(widget.roomAvatarUrl);
    _init();
  }

  @override
  void dispose() {
    _messagePoller?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // ── Step 1: Try reading the stored user_id from SharedPreferences ─────────
    // This is written by AuthService.login() — so it should already be there.
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('user_id');

    if (storedId != null) {
      debugPrint(
          '[Chat] Loaded currentUserId from SharedPreferences: $storedId');
      if (mounted) setState(() => _currentUserId = storedId);
    } else {
      // ── Step 2: Fallback — call GET /me to retrieve the authenticated user ─
      debugPrint('[Chat] user_id not in SharedPreferences — calling GET /me');
      try {
        final response = await _chatService.getMe();
        final id = response;
        if (id != null && mounted) {
          debugPrint('[Chat] Loaded currentUserId from /me: $id');
          // Also persist so the next screen load is instant
          await prefs.setInt('user_id', id);
          setState(() => _currentUserId = id);
        }
      } catch (e) {
        debugPrint('[Chat] Could not resolve currentUserId: $e');
      }
    }

    await _loadMessages();
    _startMessagePolling();
  }

  void _startMessagePolling() {
    _messagePoller?.cancel();
    _messagePoller = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(showLoader: false);
    });
  }

  Future<void> _loadMessages({bool showLoader = true}) async {
    if (_isFetchingMessages) return;
    _isFetchingMessages = true;

    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final messages = await _chatService.getMessages(widget.roomId);
      if (mounted) {
        final hasNewMessages = _hasNewMessages(messages);
        final shouldScroll = showLoader || (_isNearBottom() && hasNewMessages);
        setState(() {
          _messages = messages;
          _roomAvatarUrl = _resolveRoomAvatarUrl(messages);
          _isLoading = false;
          _errorMessage = null;
        });
        if (shouldScroll) _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        if (showLoader) {
          setState(() {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
            _isLoading = false;
          });
        } else {
          debugPrint('[Chat] background message refresh failed: $e');
        }
      }
    } finally {
      _isFetchingMessages = false;
    }
  }

  bool _hasNewMessages(List<ChatMessage> nextMessages) {
    if (nextMessages.length != _messages.length) return true;
    if (nextMessages.isEmpty && _messages.isEmpty) return false;
    return nextMessages.last.id != _messages.last.id;
  }

  String _resolveRoomAvatarUrl(List<ChatMessage> messages) {
    if (_roomAvatarUrl.isNotEmpty) return _roomAvatarUrl;

    for (final message in messages) {
      if (_currentUserId != null && message.senderId == _currentUserId) {
        continue;
      }

      final avatarUrl = ImageUrlHelper.resolve(message.sender?.profilePicture);
      if (avatarUrl.isNotEmpty) return avatarUrl;
    }

    return '';
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < 120;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      final sent = await _chatService.sendMessage(widget.roomId, text);
      if (sent != null && mounted) {
        setState(() {
          _messages.add(sent);
          _isSending = false;
        });
        _scrollToBottom();
      } else if (mounted) {
        setState(() => _isSending = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isSending || _isSendingImage) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kirim Foto',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bagikan kondisi barang, kelengkapan, atau bukti pengiriman.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Kamera',
                      onTap: () => Navigator.pop(
                        sheetContext,
                        'camera',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildImageSourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeri',
                      onTap: () => Navigator.pop(
                        sheetContext,
                        'gallery',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedImages = <XFile>[];
      if (source == 'gallery') {
        pickedImages.addAll(
          await _imagePicker.pickMultiImage(
            imageQuality: 82,
            maxWidth: 1600,
          ),
        );
      } else {
        final picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 82,
          maxWidth: 1600,
        );
        if (picked != null) pickedImages.add(picked);
      }

      if (pickedImages.isEmpty) return;

      if (mounted) setState(() => _isSendingImage = true);

      for (final picked in pickedImages) {
        final sent = await _chatService.sendImageMessage(
          widget.roomId,
          File(picked.path),
        );

        if (!mounted) return;
        if (sent != null) {
          setState(() => _messages.add(sent));
          _scrollToBottom();
        }
      }

      if (mounted) setState(() => _isSendingImage = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      showAppBar: false,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildRoomHeader(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildRoomHeader() {
    final avatarUrl = ImageUrlHelper.resolve(_roomAvatarUrl);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE83030), Color(0xFFF64A4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE83030).withValues(alpha: 0.36),
                blurRadius: 34,
                spreadRadius: -9,
                offset: const Offset(0, 19),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -26,
                top: -34,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.13),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildRoomHeaderButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  UserAvatar(
                    name: widget.roomName,
                    imageUrl: avatarUrl,
                    radius: 23,
                    showBorder: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roomName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isFetchingMessages
                              ? 'Menyegarkan pesan...'
                              : 'Percakapan aktif',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildRoomHeaderButton(
                    icon: Icons.refresh,
                    onTap: () => _loadMessages(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _productImageFallback() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[100],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) return const JualinLogoLoader(size: 64);

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            TextButton.icon(
                onPressed: () => _loadMessages(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi')),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text('Tidak ada pesan.\nKirim pesan pertama!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black38)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        // Use the real authenticated user ID — never a heuristic.
        final isMe = _currentUserId != null && msg.senderId == _currentUserId;
        return _buildBubble(msg, isMe);
      },
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe) {
    if (msg.isProductPreview) {
      return _buildProductBubble(msg, isMe);
    }
    if (msg.isImage) {
      return _buildImageBubble(msg, isMe);
    }

    // ─── Debug: verify alignment logic ───────────────────────────────────────
    debugPrint(
        '[Chat] senderId: ${msg.senderId}  |  currentUserId: $_currentUserId  |  isMe: $isMe');
    // ─────────────────────────────────────────────────────────────────────────

    final time = msg.sentAt != null
        ? '${msg.sentAt!.hour.toString().padLeft(2, '0')}:${msg.sentAt!.minute.toString().padLeft(2, '0')}'
        : '';
    final senderAvatarUrl = ImageUrlHelper.resolve(msg.sender?.profilePicture);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              name: msg.sender?.username ?? '?',
              imageUrl: senderAvatarUrl,
              radius: 14,
              showBorder: false,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.70),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE83030) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: isMe
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.11),
                          blurRadius: 24,
                          spreadRadius: -10,
                          offset: const Offset(0, 14),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && msg.sender != null)
                    Text(msg.sender!.username,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE83030))),
                  Text(msg.message,
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(time,
                      style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(ChatMessage msg, bool isMe) {
    final imageUrl = ImageUrlHelper.resolve(msg.message);
    final senderAvatarUrl = ImageUrlHelper.resolve(msg.sender?.profilePicture);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              name: msg.sender?.username ?? '?',
              imageUrl: senderAvatarUrl,
              radius: 14,
              showBorder: false,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE83030) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 18),
                ),
                border: Border.all(
                  color:
                      isMe ? const Color(0xFFE83030) : const Color(0xFFFFD6D6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: -8,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBubble(ChatMessage msg, bool isMe) {
    final product = msg.product!;
    final imageUrl = ImageUrlHelper.resolve(product.image);
    final senderAvatarUrl = ImageUrlHelper.resolve(msg.sender?.profilePicture);
    final time = msg.sentAt != null
        ? '${msg.sentAt!.hour.toString().padLeft(2, '0')}:${msg.sentAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              name: msg.sender?.username ?? '?',
              imageUrl: senderAvatarUrl,
              radius: 14,
              showBorder: false,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: product.id > 0
                  ? () => Navigator.pushNamed(
                        context,
                        '/product_detail',
                        arguments: product.id,
                      )
                  : null,
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 6),
                    bottomRight: Radius.circular(isMe ? 6 : 18),
                  ),
                  border: Border.all(color: const Color(0xFFFFD6D6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: -8,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE83030).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Preview Produk',
                            style: TextStyle(
                              color: Color(0xFFE83030),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _productImageFallback(),
                                )
                              : _productImageFallback(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(product.price),
                                style: const TextStyle(
                                  color: Color(0xFFE83030),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if ((product.sellerName ?? '').isNotEmpty)
                                Text(
                                  product.sellerName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFE83030),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFEF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE83030).withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFE83030), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE83030),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isBusy = _isSending || _isSendingImage;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -8),
            blurRadius: 22,
            spreadRadius: -14,
          )
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: isBusy ? null : _pickAndSendImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isSendingImage
                      ? const Color(0xFFE83030).withValues(alpha: 0.12)
                      : const Color(0xFFFFEFEF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE83030).withValues(alpha: 0.18),
                  ),
                ),
                child: _isSendingImage
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE83030),
                        ),
                      )
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFFE83030),
                        size: 21,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 92),
                child: TextField(
                  controller: _msgController,
                  enabled: !isBusy,
                  minLines: 1,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            isBusy
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                : GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE83030),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
