import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/chat_screen.dart';
import 'api_client.dart';
import 'api_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _client = ApiClient();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  bool _firebaseReady = false;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final options = _androidFirebaseOptions();
      if (Firebase.apps.isEmpty) {
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          await Firebase.initializeApp();
        }
      }
      _firebaseReady = true;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initializeLocalNotifications();
      await _requestPermissions();
      await registerDeviceToken();
      _listenForMessages();
    } catch (e) {
      debugPrint('[PushNotificationService] init failed: $e');
    }
  }

  Future<void> registerDeviceToken() async {
    if (!_firebaseReady ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _client.post(
        ApiConfig.notificationDeviceTokens,
        body: {
          'token': token,
          'platform': 'android',
        },
      );
    } catch (e) {
      debugPrint('[PushNotificationService] register token failed: $e');
    }
  }

  Future<void> unregisterDeviceToken() async {
    if (!_firebaseReady ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _client.delete(
        ApiConfig.notificationDeviceTokens,
        body: {'token': token},
      );
    } catch (e) {
      debugPrint('[PushNotificationService] unregister token failed: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _openFromPayload(Uri.splitQueryString(payload));
      },
    );
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _listenForMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleRemoteMessage(message);
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      registerDeviceToken();
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Jualin';
    final body = message.notification?.body ?? '';

    const androidDetails = AndroidNotificationDetails(
      'jualin_notifications',
      'Jualin Notifications',
      channelDescription: 'Notifikasi akun, chat, pembayaran, dan pesanan',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: Uri(queryParameters: message.data).query,
    );
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _openFromPayload(message.data);
  }

  void _openFromPayload(Map<String, dynamic> rawData) {
    final data = rawData.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    final targetType = data['target_type'];
    final targetId = int.tryParse(data['target_id'] ?? '');

    if (targetType == 'chat_room' && targetId != null && targetId > 0) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: targetId,
            roomName: 'Chat',
          ),
        ),
      );
      return;
    }

    switch (targetType ?? data['type']) {
      case 'seller_order':
        navigator.pushNamed('/seller_orders');
        break;
      case 'order':
      case 'payment':
        navigator.pushNamed('/purchase_history');
        break;
      case 'wallet':
        navigator.pushNamed('/wallet');
        break;
      default:
        navigator.pushNamed('/main');
    }
  }

  FirebaseOptions? _androidFirebaseOptions() {
    const apiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
    const messagingSenderId =
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

    if ([apiKey, appId, messagingSenderId, projectId]
        .any((value) => value.isEmpty)) {
      return null;
    }

    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    );
  }
}
