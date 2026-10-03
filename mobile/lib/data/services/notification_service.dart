import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Top-level handler for background/terminated FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when user taps a grocery request notification.
  void Function(String groceryRequestId)? onGroceryRequestTapped;

  /// Callback invoked when a foreground grocery notification arrives.
  void Function()? onGroceryRequestReceived;

  Future<void> initialize() async {
    // 1. Request permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 2. Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'grocery_requests',
      'Grocery Requests',
      description: 'Notifications for new grocery orders from customers',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initIOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Foreground message listener
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }

    // 6. Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });

    // 7. Register FCM token
    await registerToken();

    // 8. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) => registerToken(token: newToken));
  }

  Future<void> registerToken({String? token}) async {
    final fcmToken = token ?? await _fcm.getToken();
    if (fcmToken == null) {
      debugPrint('[FCM] No FCM token available to register');
      return;
    }

    final auth = AuthService();
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    final isMerchant = auth.currentUser != null &&
        (auth.currentUser!.role == 'merchant' ||
         auth.currentUser!.role == 'shopkeeper' ||
         auth.currentUser!.role == 'owner' ||
         auth.currentUser!.role == 'admin' ||
         auth.currentUser!.role == 'cashier' ||
         (auth.storeId != null && auth.storeId!.isNotEmpty));

    final effectiveRole = isMerchant ? 'merchant' : 'customer';
    final effectiveStoreId = auth.storeId ?? '';
    final effectiveUserId = auth.currentUser?.id ?? '';

    try {
      final success = await ApiService().registerDeviceToken(
        token: fcmToken,
        platform: platform,
        role: effectiveRole,
        storeId: effectiveStoreId,
        userId: effectiveUserId,
      );
      debugPrint('[FCM] Token registered ($effectiveRole, store: $effectiveStoreId): success=$success, token=${fcmToken.substring(0, 15)}...');
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification in foreground
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'grocery_requests',
          'Grocery Requests',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['grocery_request_id'],
    );

    // Notify listeners (for badge count update)
    onGroceryRequestReceived?.call();
  }

  void _onNotificationTapped(NotificationResponse response) {
    final groceryRequestId = response.payload;
    if (groceryRequestId != null && onGroceryRequestTapped != null) {
      onGroceryRequestTapped!(groceryRequestId);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final groceryRequestId = data['grocery_request_id'] as String?;
    if (groceryRequestId != null && onGroceryRequestTapped != null) {
      onGroceryRequestTapped!(groceryRequestId);
    }
  }
}
