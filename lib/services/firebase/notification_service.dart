// services/firebase/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import '../../views/incoming_call_screen.dart';
import '../../controllers/call_controller.dart';
import '../key_exchange_service.dart';

final _logger = Logger();

// ✅ معالج الخلفية للإشعارات
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse details) {
  _logger.i('Background notification tapped: ${details.payload}');
}

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  BuildContext? _lastContext;

  StreamSubscription? _onMessageSubscription;
  StreamSubscription? _onMessageOpenedAppSubscription;

  Future<void> initNotifications(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _lastContext = context;

    await _fcm.requestPermission();
    _logger.i("🔔 تم طلب أذونات الإشعارات بنجاح.");

    // ✅ منع Firebase من عرض الإشعارات في المقدمة (لتجنب التكرار)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false,   // ✅ لا تظهر إشعارات من Firebase
      badge: false,
      sound: false,
    );

    const callChannelId = 'privoo_call_channel';
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      callChannelId,
      'مكالمات واردة',
      description: 'الإشعارات الخاصة بالمكالمات والصوت المخصص',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('privoo_call'),
      playSound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(callChannel);

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ✅ تهيئة Local Notifications فقط (Firebase معطل للمقدمة)
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && _lastContext != null) {
          _handleMessage(_lastContext!, jsonDecode(details.payload!));
        }
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );

    final token = await _fcm.getToken();
    _logger.i("📱 FCM Token: $token");

    // ✅ استقبال الإشعارات في المقدمة (نعرضها يدوياً عبر Local Notifications)
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(_lastContext ?? context, message);
    });

    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(_lastContext ?? context, message.data);
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(_lastContext ?? context, initialMessage.data);
    }
  }

  void _handleForegroundMessage(BuildContext context, RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    
    _logger.d("📨 إشعار وارد: $type");
    
    if (type == 'incoming_call') {
      _showIncomingCallScreen(context, data);
    } else {
      // ✅ عرض إشعار عادي باستخدام Local Notifications (وليس Firebase)
      _showLocalNotification(message);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'Privoo';
    final body = message.notification?.body ?? 'لديك إشعار جديد';
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'privoo_general_channel',
      'إشعارات عامة',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessage(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    if (type == 'incoming_call') {
      _logger.i("📞 معالجة مكالمة واردة من الإشعار.");
      _showIncomingCallScreen(context, data);
    }
  }

  void _showIncomingCallScreen(BuildContext context, Map<String, dynamic> data) {
    if (!context.mounted) return;
    
    final myUserId = data['receiverId'] ?? ''; 
    final peerUserId = data['callerId'] ?? '';
    final chatId = data['callId'] ?? '';

    if (myUserId.isEmpty || peerUserId.isEmpty || chatId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerName: data['callerName'] ?? 'Unknown',
          callId: chatId,
          isVideo: data['isVideo'] == "true",
          onAccept: () async {
            Navigator.pop(context);
            final keyService = KeyExchangeService();
            final keyBytes = await keyService.establishSession(
              chatId: chatId,
              myUserId: myUserId,
              peerUserId: peerUserId,
            );
            final callController = CallController();
            await callController.joinCallAsCallee(
              callId: chatId,
              sharedSecretBytes: keyBytes.chatMasterKey,
            );
          },
          onReject: () async {
            Navigator.pop(context);
            await FirebaseFirestore.instance
                .collection("calls")
                .doc(data['callId'])
                .update({"status": "rejected"});
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    super.dispose();
    _logger.d('🧹 NotificationService: تم تنظيف جميع الـ Streams');
  }
}