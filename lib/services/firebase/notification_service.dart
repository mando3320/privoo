// services/supabase/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import '../../views/incoming_call_screen.dart';
import '../../controllers/call_controller.dart';
import '../key_exchange_service.dart';
import '../supabase_service.dart';

final _logger = Logger();

// ✅ معالج الخلفية للإشعارات
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse details) {
  _logger.i('Background notification tapped: ${details.payload}');
}

class NotificationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  BuildContext? _lastContext;

  StreamSubscription? _onMessageSubscription;
  StreamSubscription? _onMessageOpenedAppSubscription;
  StreamSubscription? _realtimeSubscription;

  Future<void> initNotifications(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _lastContext = context;

    _logger.i("🔔 تهيئة نظام الإشعارات...");

    // ✅ تهيئة قنوات الإشعارات
    const callChannelId = 'privoo_call_channel';
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      callChannelId,
      'مكالمات واردة',
      description: 'الإشعارات الخاصة بالمكالمات والصوت المخصص',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('privoo_call'),
      playSound: true,
    );

    const generalChannelId = 'privoo_general_channel';
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      generalChannelId,
      'إشعارات عامة',
      description: 'الإشعارات العامة من Privoo',
      importance: Importance.high,
      priority: Priority.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(callChannel);
    await androidPlugin?.createNotificationChannel(generalChannel);

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ✅ تهيئة Local Notifications
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && _lastContext != null) {
          _handleMessage(_lastContext!, jsonDecode(details.payload!));
        }
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );

    // ✅ استماع للإشعارات الواردة عبر Supabase Realtime
    final currentUser = SupabaseService().currentUser;
    if (currentUser != null) {
      _logger.i("👤 مستخدم مسجل: ${currentUser.id}");
      _subscribeToNotifications(currentUser.id);
    }

    _logger.i("✅ تم تهيئة نظام الإشعارات بنجاح");
  }

  /// ✅ الاشتراك في إشعارات المستخدم عبر Supabase Realtime
  void _subscribeToNotifications(String userId) {
    _realtimeSubscription?.cancel();
    
    _logger.i("📡 الاشتراك في إشعارات المستخدم: $userId");
    
    _realtimeSubscription = _supabase
        .channel('notifications:$userId')
        .onBroadcast(event: 'notification', callback: (payload) {
          final data = payload.payload as Map<String, dynamic>?;
          if (data != null) {
            _logger.d("📨 إشعار وارد: ${data['type']}");
            _handleRealtimeNotification(data);
          }
        })
        .onBroadcast(event: 'call', callback: (payload) {
          final data = payload.payload as Map<String, dynamic>?;
          if (data != null) {
            _logger.d("📞 مكالمة واردة: ${data['type']}");
            _handleIncomingCall(data);
          }
        })
        .subscribe();
  }

  /// ✅ معالجة الإشعارات من Realtime
  void _handleRealtimeNotification(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final title = data['title'] ?? 'Privoo';
    final body = data['body'] ?? 'لديك إشعار جديد';

    if (type == 'incoming_call') {
      _handleIncomingCall(data);
    } else {
      _showLocalNotification(
        title: title,
        body: body,
        payload: data,
      );
    }
  }

  /// ✅ معالجة المكالمات الواردة
  void _handleIncomingCall(Map<String, dynamic> data) {
    final context = _lastContext;
    if (context == null || !context.mounted) return;

    final callId = data['call_id'] ?? '';
    final callerId = data['caller_id'] ?? '';
    final receiverId = data['receiver_id'] ?? '';
    final callerName = data['caller_name'] ?? 'مستخدم';
    final isVideo = data['is_video'] == true;

    if (callId.isEmpty || callerId.isEmpty || receiverId.isEmpty) {
      _logger.w('⚠️ بيانات المكالمة غير مكتملة');
      return;
    }

    _logger.i("📞 مكالمة واردة من $callerName (ID: $callId)");

    // ✅ عرض إشعار المكالمة
    _showLocalNotification(
      title: '📞 مكالمة من $callerName',
      body: isVideo ? 'مكالمة فيديو واردة' : 'مكالمة صوتية واردة',
      payload: data,
      isCallNotification: true,
    );

    // ✅ عرض شاشة المكالمة الواردة
    _showIncomingCallScreen(context, data);
  }

  /// ✅ عرض إشعار محلي
  void _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    bool isCallNotification = false,
  }) {
    final channelId = isCallNotification 
        ? 'privoo_call_channel' 
        : 'privoo_general_channel';
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'privoo_general_channel',
      'إشعارات عامة',
      importance: Importance.high,
      priority: Priority.high,
    );

    final callAndroidDetails = isCallNotification
        ? const AndroidNotificationDetails(
            'privoo_call_channel',
            'مكالمات واردة',
            importance: Importance.max,
            priority: Priority.max,
            sound: RawResourceAndroidNotificationSound('privoo_call'),
            playSound: true,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
          )
        : androidDetails;

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails platformDetails = NotificationDetails(
      android: callAndroidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  /// ✅ عرض شاشة المكالمة الواردة
  void _showIncomingCallScreen(BuildContext context, Map<String, dynamic> data) {
    if (!context.mounted) return;

    final callId = data['call_id'] ?? data['callId'] ?? '';
    final callerId = data['caller_id'] ?? data['callerId'] ?? '';
    final receiverId = data['receiver_id'] ?? data['receiverId'] ?? '';
    final callerName = data['caller_name'] ?? data['callerName'] ?? 'مستخدم';
    final isVideo = data['is_video'] ?? data['isVideo'] ?? false;

    if (callId.isEmpty || callerId.isEmpty || receiverId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerName: callerName,
          callId: callId,
          isVideo: isVideo,
          onAccept: () async {
            Navigator.pop(context);
            
            try {
              // ✅ إنشاء جلسة مشفرة
              final keyService = KeyExchangeService();
              final keyBytes = await keyService.establishSession(
                chatId: callId,
                myUserId: receiverId,
                peerUserId: callerId,
              );

              // ✅ الانضمام إلى المكالمة
              final callController = CallController();
              await callController.joinCallAsCallee(
                callId: callId,
                sharedSecretBytes: keyBytes.chatMasterKey,
                isVideo: isVideo,
              );
              
              _logger.i("✅ تم قبول المكالمة $callId");
            } catch (e) {
              _logger.e('❌ فشل قبول المكالمة: $e');
            }
          },
          onReject: () async {
            Navigator.pop(context);
            
            try {
              // ✅ تحديث حالة المكالمة في Supabase
              await _supabase
                  .from('calls')
                  .update({
                    'active': false,
                    'status': 'rejected',
                    'ended_at': DateTime.now().toIso8601String(),
                  })
                  .eq('id', callId);
              
              _logger.i("❌ تم رفض المكالمة $callId");
            } catch (e) {
              _logger.e('❌ فشل رفض المكالمة: $e');
            }
          },
        ),
      ),
    );
  }

  /// ✅ معالجة الإشعار عند فتح التطبيق
  void _handleMessage(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    
    if (type == 'incoming_call') {
      _logger.i("📞 معالجة مكالمة واردة من الإشعار.");
      _showIncomingCallScreen(context, data);
    } else {
      // ✅ إشعار عادي - توجيه المستخدم
      _logger.i("📨 فتح إشعار: ${data['title']}");
    }
  }

  /// ✅ إرسال إشعار إلى مستخدم معين عبر Supabase Realtime
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final payload = {
        'title': title,
        'body': body,
        'type': 'notification',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      };

      await _supabase
          .channel('notifications:$userId')
          .sendBroadcast(
            event: 'notification',
            payload: payload,
          );

      _logger.i("📤 تم إرسال إشعار إلى المستخدم $userId");
    } catch (e) {
      _logger.e('❌ فشل إرسال الإشعار: $e');
    }
  }

  /// ✅ إرسال إشعار مكالمة إلى مستخدم معين
  Future<void> sendCallNotification({
    required String userId,
    required String callId,
    required String callerId,
    required String receiverId,
    required String callerName,
    required bool isVideo,
  }) async {
    try {
      final payload = {
        'type': 'incoming_call',
        'call_id': callId,
        'caller_id': callerId,
        'receiver_id': receiverId,
        'caller_name': callerName,
        'is_video': isVideo,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _supabase
          .channel('notifications:$userId')
          .sendBroadcast(
            event: 'call',
            payload: payload,
          );

      _logger.i("📤 تم إرسال إشعار مكالمة إلى المستخدم $userId");
    } catch (e) {
      _logger.e('❌ فشل إرسال إشعار المكالمة: $e');
    }
  }

  /// ✅ إرسال إشعار جماعي لجميع المستخدمين
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    List<String>? excludeUserIds,
  }) async {
    try {
      // ✅ جلب جميع المستخدمين
      final users = await _supabase
          .from('users')
          .select('uid');
      
      final userIds = (users as List)
          .map((u) => u['uid'] as String)
          .where((id) => !(excludeUserIds?.contains(id) ?? false))
          .toList();

      _logger.i("📤 إرسال إشعار جماعي إلى ${userIds.length} مستخدم");

      // ✅ إرسال الإشعار لكل مستخدم
      for (final userId in userIds) {
        await sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          data: data,
        );
      }

      _logger.i("✅ تم إرسال الإشعار الجماعي بنجاح");
    } catch (e) {
      _logger.e('❌ فشل إرسال الإشعار الجماعي: $e');
    }
  }

  /// ✅ تسجيل جهاز المستخدم للإشعارات
  Future<void> registerDeviceToken(String userId, String deviceToken) async {
    try {
      await _supabase
          .from('user_devices')
          .upsert({
            'user_id': userId,
            'device_token': deviceToken,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,device_token');

      _logger.i("✅ تم تسجيل جهاز المستخدم $userId");
    } catch (e) {
      _logger.e('❌ فشل تسجيل الجهاز: $e');
    }
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
    _logger.d('🧹 NotificationService: تم تنظيف جميع الـ Streams');
  }
}