// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/chat_member_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ إضافة

class UserModel {
  final String id;
  final String authId;
  final String? name;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? about;
  final bool isActive;
  final bool isPro;
  final bool isLifetime;
  final bool isAdmin;
  final String? role;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.authId,
    this.name,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.about,
    this.isActive = true,
    this.isPro = false,
    this.isLifetime = false,
    this.isAdmin = false,
    this.role = 'user',
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    authId: json['auth_id'] ?? '',
    name: json['name'],
    phoneNumber: json['phone_number'],
    email: json['email'],
    avatarUrl: json['avatar_url'],
    about: json['about'],
    isActive: json['is_active'] ?? true,
    isPro: json['is_pro'] ?? false,
    isLifetime: json['is_lifetime'] ?? false,
    isAdmin: json['is_admin'] ?? false,
    role: json['role'] ?? 'user',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
    isOnline: json['is_online'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'auth_id': authId,
    if (name != null) 'name': name,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (email != null) 'email': email,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (about != null) 'about': about,
    'is_active': isActive,
    'is_pro': isPro,
    'is_lifetime': isLifetime,
    'is_admin': isAdmin,
    if (role != null) 'role': role,
    'created_at': createdAt.toIso8601String(),
    if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
    'is_online': isOnline,
  };
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;
  final _uuid = const Uuid();
  bool _initialized = false;

  SupabaseClient get client => _client;

  static String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get _supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // ✅ إعدادات Refresh Token
  static const int _tokenRefreshThreshold = 300; // 5 دقائق
  static const String _keyAccessToken = 'supabase_access_token';
  static const String _keyRefreshToken = 'supabase_refresh_token';
  static const String _keyTokenExpiry = 'supabase_token_expiry';
  
  // ✅ متغيرات تخزين التوكنات
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  DateTime? _cachedTokenExpiry;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    
    // ✅ استعادة التوكنات المخزنة
    await _restoreTokens();
    
    // ✅ التحقق من صلاحية التوكن عند بدء التشغيل
    if (_cachedAccessToken != null) {
      await _autoRefreshIfNeeded();
    }
    
    print('✅ Supabase initialized with refresh token support');
  }

  // ============================================================
  // 🔐 Refresh Token System
  // ============================================================

  // ✅ استعادة التوكنات من التخزين المحلي
  Future<void> _restoreTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedAccessToken = prefs.getString(_keyAccessToken);
      _cachedRefreshToken = prefs.getString(_keyRefreshToken);
      
      final expiryStr = prefs.getString(_keyTokenExpiry);
      if (expiryStr != null) {
        _cachedTokenExpiry = DateTime.parse(expiryStr);
      }
      
      print('📂 تم استعادة التوكنات من التخزين المحلي');
    } catch (e) {
      print('⚠️ فشل استعادة التوكنات: $e');
    }
  }

  // ✅ حفظ التوكنات في التخزين المحلي
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
      await prefs.setString(_keyTokenExpiry, expiry.toIso8601String());
      
      _cachedAccessToken = accessToken;
      _cachedRefreshToken = refreshToken;
      _cachedTokenExpiry = expiry;
      
      print('💾 تم حفظ التوكنات بنجاح');
    } catch (e) {
      print('⚠️ فشل حفظ التوكنات: $e');
    }
  }

  // ✅ مسح التوكنات (عند تسجيل الخروج)
  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyTokenExpiry);
      
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      _cachedTokenExpiry = null;
      
      print('🗑️ تم مسح التوكنات');
    } catch (e) {
      print('⚠️ فشل مسح التوكنات: $e');
    }
  }

  // ✅ التحقق من صلاحية التوكن وتجديده تلقائياً
  Future<bool> isSessionValid() async {
    try {
      // التحقق من وجود جلسة
      final session = _client.auth.currentSession;
      if (session == null) {
        // محاولة استعادة الجلسة من التوكنات المخزنة
        if (_cachedAccessToken != null && _cachedRefreshToken != null) {
          try {
            await _client.auth.setSession(
              accessToken: _cachedAccessToken!,
              refreshToken: _cachedRefreshToken!,
            );
            print('🔄 تم استعادة الجلسة من التوكنات المخزنة');
            return true;
          } catch (e) {
            print('⚠️ فشل استعادة الجلسة: $e');
            return false;
          }
        }
        return false;
      }
      
      final expiresAt = session.expiresAt;
      if (expiresAt == null) return true;
      
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = expiresAt - now;
      
      // ✅ إذا بقي أقل من 5 دقائق، جدده
      if (remaining < _tokenRefreshThreshold) {
        print('🔄 التوكن على وشك الانتهاء (${remaining}s)، جاري التجديد...');
        await refreshSession();
        return true;
      }
      
      print('✅ التوكن صالح (${remaining}s متبقية)');
      return true;
    } catch (e) {
      print('❌ فشل التحقق من صلاحية التوكن: $e');
      return false;
    }
  }

  // ✅ تجديد التوكن
  Future<void> refreshSession() async {
    try {
      final currentSession = _client.auth.currentSession;
      if (currentSession == null) {
        // محاولة استخدام التوكن المخزن للتجديد
        if (_cachedRefreshToken != null) {
          print('🔄 جاري تجديد التوكن باستخدام التوكن المخزن...');
          final newSession = await _client.auth.refreshSession(
            refreshToken: _cachedRefreshToken!,
          );
          if (newSession != null) {
            await _saveTokens(
              accessToken: newSession.accessToken,
              refreshToken: newSession.refreshToken,
              expiry: DateTime.fromMillisecondsSinceEpoch(
                newSession.expiresAt! * 1000,
              ),
            );
            print('✅ تم تجديد التوكن بنجاح (من التخزين)');
          }
          return;
        }
        print('⚠️ لا توجد جلسة نشطة لتجديدها');
        return;
      }
      
      // تجديد من الجلسة الحالية
      final newSession = await _client.auth.refreshSession();
      if (newSession != null) {
        await _saveTokens(
          accessToken: newSession.accessToken,
          refreshToken: newSession.refreshToken,
          expiry: DateTime.fromMillisecondsSinceEpoch(
            newSession.expiresAt! * 1000,
          ),
        );
        print('🔄 تم تجديد التوكن بنجاح');
      }
    } catch (e) {
      print('❌ فشل تجديد التوكن: $e');
      
      // ✅ محاولة التجديد باستخدام التوكن المخزن كحل بديل
      if (_cachedRefreshToken != null) {
        try {
          print('🔄 محاولة التجديد باستخدام التوكن المخزن (حل بديل)...');
          final newSession = await _client.auth.refreshSession(
            refreshToken: _cachedRefreshToken!,
          );
          if (newSession != null) {
            await _saveTokens(
              accessToken: newSession.accessToken,
              refreshToken: newSession.refreshToken,
              expiry: DateTime.fromMillisecondsSinceEpoch(
                newSession.expiresAt! * 1000,
              ),
            );
            print('✅ تم تجديد التوكن بنجاح (حل بديل)');
            return;
          }
        } catch (e2) {
          print('❌ فشل التجديد بالحل البديل: $e2');
        }
      }
      rethrow;
    }
  }

  // ✅ تجديد تلقائي عند الحاجة
  Future<void> _autoRefreshIfNeeded() async {
    try {
      if (_cachedTokenExpiry == null) return;
      
      final now = DateTime.now();
      final remaining = _cachedTokenExpiry!.difference(now).inSeconds;
      
      if (remaining < _tokenRefreshThreshold) {
        print('🔄 تجديد تلقائي للتوكن (باقي ${remaining}s)...');
        await refreshSession();
      }
    } catch (e) {
      print('⚠️ فشل التجديد التلقائي: $e');
    }
  }

  // ✅ التحقق من التوكن قبل كل طلب
  Future<void> ensureValidSession() async {
    final isValid = await isSessionValid();
    if (!isValid) {
      // ✅ محاولة التجديد مرة أخيرة
      try {
        await refreshSession();
        final recheck = await isSessionValid();
        if (!recheck) {
          throw Exception('Session expired and refresh failed');
        }
      } catch (e) {
        throw Exception('Session expired: $e');
      }
    }
  }

  // ✅ تسجيل الخروج مع مسح التوكنات
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _clearTokens();
      print('✅ تم تسجيل الخروج ومسح التوكنات');
    } catch (e) {
      print('❌ فشل تسجيل الخروج: $e');
      rethrow;
    }
  }

  // ✅ الحصول على التوكن الحالي
  String? get sessionToken => _cachedAccessToken ?? _client.auth.currentSession?.accessToken;

  // ✅ الحصول على توكن التحديث
  String? get refreshToken => _cachedRefreshToken ?? _client.auth.currentSession?.refreshToken;

  // ✅ التحقق من صلاحية التوكن
  bool get isTokenValid {
    if (_cachedTokenExpiry == null) return false;
    final now = DateTime.now();
    return _cachedTokenExpiry!.isAfter(now);
  }

  // ✅ الحصول على الوقت المتبقي للتوكن
  Duration? get tokenTimeRemaining {
    if (_cachedTokenExpiry == null) return null;
    final now = DateTime.now();
    return _cachedTokenExpiry!.difference(now);
  }

  // ============================================================
  // 👤 Auth (معدل لدعم Refresh Token)
  // ============================================================

  Future<void> signInWithOTP(String phoneNumber) async {
    await _client.auth.signInWithOtp(phone: phoneNumber);
  }

  Future<AuthResponse> verifyOTP(String phoneNumber, String code) async {
    final response = await _client.auth.verifyOTP(
      phone: phoneNumber,
      token: code,
      type: OtpType.sms,
    );
    
    // ✅ حفظ التوكنات بعد التحقق
    if (response.session != null) {
      await _saveTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
        expiry: DateTime.fromMillisecondsSinceEpoch(
          response.session!.expiresAt! * 1000,
        ),
      );
    }
    
    return response;
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email, 
      password: password,
    );
    
    // ✅ حفظ التوكنات بعد تسجيل الدخول
    if (response.session != null) {
      await _saveTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
        expiry: DateTime.fromMillisecondsSinceEpoch(
          response.session!.expiresAt! * 1000,
        ),
      );
    }
    
    return response;
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email, 
      password: password,
    );
    
    // ✅ حفظ التوكنات بعد التسجيل
    if (response.session != null) {
      await _saveTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
        expiry: DateTime.fromMillisecondsSinceEpoch(
          response.session!.expiresAt! * 1000,
        ),
      );
    }
    
    return response;
  }

  User? get currentUser => _client.auth.currentUser;

  // ============================================================
  // 👤 Users (معدل مع ensureValidSession)
  // ============================================================

  Future<UserModel?> getUser(String authId) async {
    try {
      await ensureValidSession();
      final response = await _client.from('users').select().eq('auth_id', authId).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ getUser error: $e');
      return null;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      await ensureValidSession();
      final response = await _client.from('users').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ getUserById error: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
      await ensureValidSession();
      final response = await _client.from('users').select().eq('phone_number', phoneNumber).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ getUserByPhone error: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      await ensureValidSession();
      final response = await _client.from('users').select();
      return List<Map<String, dynamic>>.from(response)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getAllUsers error: $e');
      return [];
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await ensureValidSession();
      await _client.from('users').insert(user.toJson());
      print('✅ User created: ${user.id}');
    } catch (e) {
      print('❌ createUser error: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String authId, Map<String, dynamic> data) async {
    try {
      await ensureValidSession();
      print('📤 updateUser called with authId: $authId');
      print('📤 data: $data');
      await _client.from('users').update(data).eq('auth_id', authId);
      print('✅ updateUser success');
    } catch (e) {
      print('❌ updateUser error: $e');
      rethrow;
    }
  }

  Future<void> updateUserById(String id, Map<String, dynamic> data) async {
    try {
      await ensureValidSession();
      print('📤 updateUserById called with id: $id');
      print('📤 data: $data');
      await _client.from('users').update(data).eq('id', id);
      print('✅ updateUserById success');
    } catch (e) {
      print('❌ updateUserById error: $e');
      rethrow;
    }
  }

  Future<void> updateUserLastSeen(String authId) async {
    try {
      await ensureValidSession();
      await _client.from('users').update({
        'last_seen': DateTime.now().toIso8601String(),
        'is_online': true,
      }).eq('auth_id', authId);
    } catch (e) {
      print('❌ updateUserLastSeen error: $e');
    }
  }

  Future<void> setUserOffline(String authId) async {
    try {
      await ensureValidSession();
      await _client.from('users').update({
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('auth_id', authId);
    } catch (e) {
      print('❌ setUserOffline error: $e');
    }
  }

  // ============================================================
  // 💬 Chats (معدل مع ensureValidSession)
  // ============================================================

  Future<String> createChat(List<String> members) async {
    try {
      await ensureValidSession();
      print('📤 createChat called with members: $members');
      
      final chatId = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final Map<String, int> unreadCount = {};
      for (var m in members) {
        unreadCount[m] = 0;
      }
      
      print('📤 Creating chat with ID: $chatId');
      
      await _client.from('chats').insert({
        'id': chatId,
        'created_at': now,
        'updated_at': now,
        'last_message': '',
        'last_message_time': now,
        'unread_count': unreadCount,
        'members': members,
        'is_group': false,
      });
      
      print('✅ Chat created successfully');
      
      for (final member in members) {
        print('📤 Adding member: $member to chat: $chatId');
        await _client.from('chat_members').insert({
          'chat_id': chatId,
          'user_id': member,
          'joined_at': now,
          'role': 'member',
        });
      }
      
      print('✅ All members added successfully');
      return chatId;
    } catch (e) {
      print('❌ createChat error: $e');
      rethrow;
    }
  }

  Future<List<ChatModel>> getUserChats(String authId) async {
    try {
      await ensureValidSession();
      final memberResponse = await _client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', authId);
      
      final chatIds = List<Map<String, dynamic>>.from(memberResponse)
          .map((e) => e['chat_id'] as String)
          .toList();
      
      if (chatIds.isEmpty) return [];
      
      final response = await _client
          .from('chats')
          .select()
          .inFilter('id', chatIds)
          .order('last_message_time', ascending: false);
      
      final List<ChatModel> result = [];
      for (var json in response) {
        final members = await _getChatMembers(json['id'] as String);
        result.add(ChatModel.fromJson({
          ...json,
          'members': members,
        }));
      }
      return result;
    } catch (e) {
      print('❌ getUserChats error: $e');
      return [];
    }
  }

  Future<List<String>> _getChatMembers(String chatId) async {
    try {
      await ensureValidSession();
      final response = await _client
          .from('chat_members')
          .select('user_id')
          .eq('chat_id', chatId);
      
      return List<Map<String, dynamic>>.from(response)
          .map((e) => e['user_id'] as String)
          .toList();
    } catch (e) {
      print('❌ _getChatMembers error: $e');
      return [];
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      await ensureValidSession();
      final response = await _client.from('chats').select().eq('id', chatId).maybeSingle();
      if (response == null) return null;
      
      final members = await _getChatMembers(chatId);
      
      return ChatModel.fromJson({
        ...response,
        'members': members,
      });
    } catch (e) {
      print('❌ getChat error: $e');
      return null;
    }
  }

  Future<void> updateChatLastMessage(String chatId, String message, DateTime time) async {
    try {
      await ensureValidSession();
      await _client.from('chats').update({
        'last_message': message,
        'last_message_time': time.toIso8601String(),
        'updated_at': time.toIso8601String(),
      }).eq('id', chatId);
    } catch (e) {
      print('❌ updateChatLastMessage error: $e');
    }
  }

  Future<void> incrementUnreadCount(String chatId, String userId) async {
    try {
      await ensureValidSession();
      final chat = await getChat(chatId);
      if (chat == null) return;
      
      final newCount = (chat.unreadCount[userId] ?? 0) + 1;
      final newUnread = Map<String, int>.from(chat.unreadCount);
      newUnread[userId] = newCount;
      
      await _client.from('chats').update({
        'unread_count': newUnread,
      }).eq('id', chatId);
    } catch (e) {
      print('❌ incrementUnreadCount error: $e');
    }
  }

  Future<void> resetUnreadCount(String chatId, String userId) async {
    try {
      await ensureValidSession();
      final chat = await getChat(chatId);
      if (chat == null) return;
      
      final newUnread = Map<String, int>.from(chat.unreadCount);
      newUnread[userId] = 0;
      
      await _client.from('chats').update({
        'unread_count': newUnread,
      }).eq('id', chatId);
    } catch (e) {
      print('❌ resetUnreadCount error: $e');
    }
  }

  // ============================================================
  // 📨 Messages (معدل مع ensureValidSession)
  // ============================================================

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String type = 'text',
  }) async {
    try {
      await ensureValidSession();
      print('📤 sendMessage called');
      print('📤 chatId: $chatId');
      print('📤 senderId: $senderId');
      print('📤 content: $content');
      
      final messageId = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: '',
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        type: _parseMessageType(type),
      );
      
      final response = await _client
          .from('messages')
          .insert({
            ...message.toMap(),
            'chat_id': chatId,
            'created_at': now,
          })
          .select()
          .single();
      
      print('✅ Message saved: ${response['id']}');
      
      await updateChatLastMessage(chatId, content, DateTime.now());
      
      final members = await _getChatMembers(chatId);
      for (final member in members) {
        if (member != senderId) {
          await incrementUnreadCount(chatId, member);
        }
      }
      
      return MessageModel.fromJson(response);
    } catch (e) {
      print('❌ sendMessage error: $e');
      rethrow;
    }
  }

  Future<List<MessageModel>> getMessages(String chatId, {int limit = 50}) async {
    try {
      await ensureValidSession();
      final response = await _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response)
          .map((json) => MessageModel.fromJson(json))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('❌ getMessages error: $e');
      return [];
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await ensureValidSession();
      await _client.from('messages').delete().eq('id', messageId);
    } catch (e) {
      print('❌ deleteMessage error: $e');
    }
  }

  Future<void> deleteMessagesForChat(String chatId) async {
    try {
      await ensureValidSession();
      await _client.from('messages').delete().eq('chat_id', chatId);
    } catch (e) {
      print('❌ deleteMessagesForChat error: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await ensureValidSession();
      final message = await _client.from('messages').select().eq('id', messageId).maybeSingle();
      if (message == null) return;
      
      final readBy = Map<String, bool>.from(message['read_by'] ?? {});
      readBy[userId] = true;
      
      await _client.from('messages').update({
        'read_by': readBy,
      }).eq('id', messageId);
    } catch (e) {
      print('❌ markMessageAsRead error: $e');
    }
  }

  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    try {
      await ensureValidSession();
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId);
    } catch (e) {
      print('❌ markAllMessagesAsRead error: $e');
    }
  }

  // ============================================================
  // 📡 Realtime Subscriptions
  // ============================================================

  Stream<List<MessageModel>> subscribeToMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((data) {
          return List<Map<String, dynamic>>.from(data)
              .map((json) => MessageModel.fromJson(json))
              .toList();
        });
  }

  Stream<ChatModel?> subscribeToChat(String chatId) {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((data) {
          if (data.isEmpty) return null;
          return ChatModel.fromJson(data.first);
        });
  }

  Stream<UserModel?> subscribeToUserStatus(String authId) {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('auth_id', authId)
        .map((data) {
          if (data.isEmpty) return null;
          return UserModel.fromJson(data.first);
        });
  }

  // ============================================================
  // 🗑️ Delete Account
  // ============================================================

  Future<void> deleteUserAccount(String userId) async {
    try {
      await ensureValidSession();
      // حذف الرسائل
      await deleteMessagesForChat(userId);
      
      // حذف من chat_members
      await _client.from('chat_members').delete().eq('user_id', userId);
      
      // حذف من users
      await _client.from('users').delete().eq('id', userId);
      
      // ✅ مسح التوكنات
      await _clearTokens();
      
      print('✅ User account deleted: $userId');
    } catch (e) {
      print('❌ deleteUserAccount error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 🛠️ Helper Methods
  // ============================================================

  MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'gif':
        return MessageType.gif;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}