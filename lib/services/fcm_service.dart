import 'dart:convert';
import 'dart:typed_data'; // For Int64List
import 'package:flutter/material.dart'; // For Color
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// ==================== FCM SERVICE ====================
/// Service untuk handle Firebase Cloud Messaging
/// - Request permission
/// - Get FCM token
/// - Send token to backend
/// - Handle incoming notifications (foreground & background)
/// ====================================================

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM Service
  static Future<void> initialize() async {
    print('🔔 FCM Service: Initializing...');

    // 1. Request permission
    await _requestPermission();

    // 2. Initialize local notifications (for foreground)
    await _initializeLocalNotifications();

    // 3. Get FCM token and send to backend
    await _getFCMTokenAndSendToBackend();

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle notification tap (when app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Check if app was opened from notification (when terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 7. Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    print('✅ FCM Service: Initialized successfully!');
  }

  /// Request notification permission
  static Future<void> _requestPermission() async {
    print('📱 FCM: Requesting permission...');

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM: Permission granted!');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ FCM: Provisional permission granted');
    } else {
      print('❌ FCM: Permission denied');
    }
  }

  /// Initialize local notifications (for foreground)
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification_spp'); // SPP Ticket logo (splash_logo_4)

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create HIGH PRIORITY notification channel for Payments
    final AndroidNotificationChannel paymentChannel = AndroidNotificationChannel(
      'payment_notifications', // id
      '💰 Pembayaran SPP', // title
      description: 'Notifikasi pembayaran dan transaksi SPP',
      importance: Importance.max,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]), // Custom vibration
      playSound: true,
      enableLights: true,
      ledColor: const Color(0xFFFF9800), // Orange color (matching logo)
    );

    // Create channel for General Notifications
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_notifications',
      '📢 Notifikasi Umum',
      description: 'Pengumuman, acara, dan informasi sekolah',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final plugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await plugin?.createNotificationChannel(paymentChannel);
    await plugin?.createNotificationChannel(generalChannel);

    print('✅ FCM: Local notifications initialized with custom channels');
  }

  /// Get FCM token and send to backend
  static Future<void> _getFCMTokenAndSendToBackend() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        await _sendTokenToBackend(token);
      } else {
        print('⚠️ FCM: Token is null');
      }
    } catch (e) {
      print('❌ FCM: Error getting token: $e');
    }
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final authToken = await AuthService.getToken();
      if (authToken == null) {
        print('⚠️ FCM: User not logged in, skipping token send');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/fcm-token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM: Token sent to backend successfully!');
      } else {
        print('⚠️ FCM: Failed to send token: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ FCM: Error sending token to backend: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 FCM: Foreground message received!');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Show local notification (because FCM doesn't show notification when app is in foreground)
    _showLocalNotification(message);
  }

  /// Show local notification with modern styling
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    print('🎯 _showLocalNotification called');
    print('   Message ID: ${message.messageId}');
    print('   Notification: ${message.notification?.toMap()}');
    print('   Data: ${message.data}');
    
    // Determine notification type from data
    final String notifType = message.data['type'] ?? 'general';
    final String channelId = notifType.contains('payment') 
        ? 'payment_notifications' 
        : 'general_notifications';
    
    print('   Channel ID: $channelId');
    
      // Create BigTextStyle for expandable notification
      final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
        message.notification?.body ?? '',
        htmlFormatBigText: true,
        contentTitle: message.notification?.title ?? 'Notifikasi',
        htmlFormatContentTitle: true,
        // No summaryText or subtitle - ultra clean!
      );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'payment_notifications' ? '💰 Pembayaran SPP' : '📢 Notifikasi Umum',
      channelDescription: channelId == 'payment_notifications' 
          ? 'Notifikasi pembayaran dan transaksi SPP'
          : 'Pengumuman, acara, dan informasi sekolah',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      
      // CUSTOM STYLING - Clean & Simple with SPP Ticket Logo
      icon: '@drawable/ic_notification_spp', // Small icon (status bar) - splash_logo_4.png
      // No largeIcon - removes the circular icon on the right
      color: const Color(0xFFFF9800), // Notification accent color (orange - matching logo)
      colorized: false, // Don't colorize (keep logo visible)
      
      // BigTextStyle for expandable content
      styleInformation: bigTextStyle,
      
      // Action buttons (optional - uncomment if needed)
      // actions: <AndroidNotificationAction>[
      //   const AndroidNotificationAction(
      //     'view_action',
      //     'Lihat Detail',
      //     showsUserInterface: true,
      //     icon: DrawableResourceAndroidBitmap('@drawable/ic_view'),
      //   ),
      // ],
      
      // Additional settings
      ticker: message.notification?.title, // Ticker text
      autoCancel: true, // Auto dismiss when tapped
      ongoing: false, // Not persistent
      // timeoutAfter removed - notification stays until user dismisses
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'spp_notifications',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      print('📤 Attempting to show notification...');
      print('   ID: ${message.hashCode}');
      print('   Title: ${message.notification?.title ?? 'Notifikasi'}');
      print('   Body: ${message.notification?.body ?? ''}');
      
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Notifikasi',
        message.notification?.body ?? '',
        details,
        payload: jsonEncode(message.data),
      );
      
      print('✅ Notification displayed successfully!');
    } catch (e, stackTrace) {
      print('❌ ERROR showing notification: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 FCM: Notification tapped!');
    print('Data: ${message.data}');

    // TODO: Navigate to specific screen based on notification data
    // Example: if (message.data['type'] == 'payment_success') { navigate to history }
  }

  /// Handle local notification tap
  static void _onNotificationTap(NotificationResponse response) {
    print('🔔 FCM: Local notification tapped!');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      print('Data: $data');
      // TODO: Navigate based on data
    }
  }

  /// Handle token refresh
  static void _onTokenRefresh(String newToken) {
    print('🔄 FCM: Token refreshed!');
    print('New token: $newToken');
    _sendTokenToBackend(newToken);
  }

  /// Manually refresh FCM token (call after login)
  static Future<void> refreshToken() async {
    print('🔄 FCM: Manually refreshing token...');
    await _getFCMTokenAndSendToBackend();
  }
}

/// ==================== BACKGROUND MESSAGE HANDLER ====================
/// This must be a top-level function (not inside a class)
/// ====================================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 FCM: Background message received!');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

