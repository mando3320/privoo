// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// ============================================================
// 📦 Models
// ============================================================

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
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
    isOnline: json['is_online'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'auth_id': authId,
    if (name != null) 'name': name,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (email != null) 'email': email,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (about != null) 'about': about,
    'is_active': isActive,
    'is_pro': isPro,
    'is_lifetime': isLifetime,
    'created_at': createdAt.toIso8601String(),
    if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
    'is_online': isOnline,
  };
}

class ChatModel {
  final String chatId;
  final List<String> members;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.chatId,
    required this.members,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
    chatId: json['chat_id'] ?? '',
    members: List<String>.from(json['members'] ?? []),
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    lastMessage: json['last_message'],
    lastMessageTime: json['last_message_time'] != null
        ? DateTime.parse(json['last_message_time'])
        : null,
    unreadCount: Map<String, int>.from(json['unread_count'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'chat_id': chatId,
    'members': members,
    'created_at': createdAt.toIso8601String(),
    if (lastMessage != null) 'last_message': lastMessage,
    if (lastMessageTime != null) 'last_message_time': lastMessageTime!.toIso8601String(),
    'unread_count': unreadCount,
  };
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final DateTime createdAt;
  final Map<String, bool> readBy;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.readBy = const {},
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id']?.toString() ?? '',
    chatId: json['chat_id'] ?? '',
    senderId: json['sender_auth_id'] ?? '',
    content: json['content'] ?? '',
    type: json['type'] ?? 'text',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    readBy: Map<String, bool>.from(json['read_by'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'chat_id': chatId,
    'sender_auth_id': senderId,
    'content': content,
    'type': type,
    'created_at': createdAt.toIso8601String(),
    'read_by': readBy,
  };

  bool isReadBy(String userId) => readBy[userId] ?? false;
}

// ============================================================
// 🚀 SupabaseService - Chat Members Version
// ============================================================

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late SupabaseClient _client;
  final _uuid = const Uuid();

  SupabaseClient get client => _client;

  // ⚠️ استبدل بالقيم من Supabase Dashboard
  static const String _supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String _supabaseAnonKey = 'YOUR_ANON_KEY';

  // ============================================================
  // 🔥 Initialization
  // ============================================================

  Future<void> init() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    print('✅ Supabase initialized');
  }

  // ============================================================
  // 👤 Auth
  // ============================================================

  Future<void> signInWithOTP(String phoneNumber) async {
    await _client.auth.signInWithOtp(phone: phoneNumber);
  }

  Future<AuthResponse> verifyOTP(String phoneNumber, String code) async {
    return await _client.auth.verifyOTP(
      phone: phoneNumber,
      token: code,
      type: OtpType.sms,
    );
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  String? get sessionToken => _client.auth.currentSession?.accessToken;

  // ============================================================
  // 👤 Users
  // ============================================================

  Future<UserModel?> getUser(String authId) async {
    try {
      final response = await _client.from('users').select().eq('auth_id', authId).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ getUser error: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    try {
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
    await _client.from('users').insert(user.toJson());
  }

  Future<void> updateUser(String authId, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('auth_id', authId);
  }

  Future<void> updateUserLastSeen(String authId) async {
    await _client.from('users').update({
      'last_seen': DateTime.now().toIso8601String(),
      'is_online': true,
    }).eq('auth_id', authId);
  }

  Future<void> setUserOffline(String authId) async {
    await _client.from('users').update({
      'is_online': false,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('auth_id', authId);
  }

  // ============================================================
  // 💬 Chats (مع chat_members)
  // ============================================================

  /// ✅ إنشاء محادثة جديدة
  Future<String> createChat(List<String> members) async {
    final chatId = _uuid.v4();
    
    // ✅ إنشاء المحادثة
    await _client.from('chats').insert({
      'chat_id': chatId,
      'created_at': DateTime.now().toIso8601String(),
      'last_message': '',
      'last_message_time': DateTime.now().toIso8601String(),
      'unread_count': {for (var m in members) m: 0},
    });
    
    // ✅ إضافة الأعضاء في chat_members
    for (final member in members) {
      await _client.from('chat_members').insert({
        'chat_id': chatId,
        'user_id': member,
      });
    }
    
    return chatId;
  }

  /// ✅ جلب محادثات المستخدم (عن طريق chat_members)
  Future<List<ChatModel>> getUserChats(String authId) async {
    try {
      // ✅ جلب chat_ids من chat_members
      final memberResponse = await _client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', authId);
      
      final chatIds = List<Map<String, dynamic>>.from(memberResponse)
          .map((e) => e['chat_id'] as String)
          .toList();
      
      if (chatIds.isEmpty) return [];
      
      // ✅ جلب بيانات المحادثات
      final response = await _client
          .from('chats')
          .select()
          .inFilter('chat_id', chatIds)
          .order('last_message_time', ascending: false);
      
      return List<Map<String, dynamic>>.from(response)
          .map((json) => {
            ...json,
            'members': await _getChatMembers(json['chat_id'] as String),
          })
          .map((json) => ChatModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ getUserChats error: $e');
      return [];
    }
  }

  /// ✅ جلب أعضاء المحادثة
  Future<List<String>> _getChatMembers(String chatId) async {
    try {
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

  /// ✅ جلب محادثة محددة
  Future<ChatModel?> getChat(String chatId) async {
    try {
      final response = await _client.from('chats').select().eq('chat_id', chatId).maybeSingle();
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

  /// ✅ تحديث آخر رسالة
  Future<void> updateChatLastMessage(String chatId, String message, DateTime time) async {
    await _client.from('chats').update({
      'last_message': message,
      'last_message_time': time.toIso8601String(),
    }).eq('chat_id', chatId);
  }

  /// ✅ زيادة unread
  Future<void> incrementUnreadCount(String chatId, String userId) async {
    final chat = await getChat(chatId);
    if (chat == null) return;
    
    final newCount = (chat.unreadCount[userId] ?? 0) + 1;
    final newUnread = Map<String, int>.from(chat.unreadCount);
    newUnread[userId] = newCount;
    
    await _client.from('chats').update({
      'unread_count': newUnread,
    }).eq('chat_id', chatId);
  }

  /// ✅ إعادة تعيين unread
  Future<void> resetUnreadCount(String chatId, String userId) async {
    final chat = await getChat(chatId);
    if (chat == null) return;
    
    final newUnread = Map<String, int>.from(chat.unreadCount);
    newUnread[userId] = 0;
    
    await _client.from('chats').update({
      'unread_count': newUnread,
    }).eq('chat_id', chatId);
  }

  // ============================================================
  // 📨 Messages
  // ============================================================

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String type = 'text',
  }) async {
    final message = MessageModel(
      id: '',
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      createdAt: DateTime.now(),
      readBy: {senderId: true},
    );
    
    final response = await _client
        .from('messages')
        .insert(message.toJson())
        .select()
        .single();
    
    await updateChatLastMessage(chatId, content, DateTime.now());
    
    // ✅ زيادة unread للآخرين
    final members = await _getChatMembers(chatId);
    for (final member in members) {
      if (member != senderId) {
        await incrementUnreadCount(chatId, member);
      }
    }
    
    return MessageModel.fromJson(response);
  }

  Future<List<MessageModel>> getMessages(String chatId, {int limit = 50, String? cursor}) async {
    try {
      var query = _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }
      
      final response = await query;
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
    await _client.from('messages').delete().eq('id', messageId);
  }

  Future<void> markMessageAsRead(String messageId, String userId) async {
    final message = await _client.from('messages').select().eq('id', messageId).maybeSingle();
    if (message == null) return;
    
    final readBy = Map<String, bool>.from(message['read_by'] ?? {});
    readBy[userId] = true;
    
    await _client.from('messages').update({
      'read_by': readBy,
    }).eq('id', messageId);
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
        .limit(50)
        .map((data) {
          return List<Map<String, dynamic>>.from(data)
              .map((json) => MessageModel.fromJson(json))
              .toList()
              .reversed
              .toList();
        });
  }

  Stream<ChatModel?> subscribeToChat(String chatId) {
    return _client
        .from('chats')
        .stream(primaryKey: ['chat_id'])
        .eq('chat_id', chatId)
        .map((data) async {
          if (data.isEmpty) return null;
          final members = await _getChatMembers(chatId);
          return ChatModel.fromJson({
            ...data.first,
            'members': members,
          });
        });
  }

  Stream<List<ChatModel>> subscribeToUserChats(String authId) {
    return _client
        .from('chat_members')
        .stream(primaryKey: ['chat_id', 'user_id'])
        .eq('user_id', authId)
        .map((data) async {
          final chatIds = List<Map<String, dynamic>>.from(data)
              .map((e) => e['chat_id'] as String)
              .toList();
          
          if (chatIds.isEmpty) return [];
          
          final chats = await _client
              .from('chats')
              .select()
              .inFilter('chat_id', chatIds)
              .order('last_message_time', ascending: false);
          
          return List<Map<String, dynamic>>.from(chats)
              .map((json) => ChatModel.fromJson({
                ...json,
                'members': chatIds,
              }))
              .toList();
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

  Stream<Map<String, dynamic>> subscribeToTyping(String chatId) {
    return _client
        .channel('typing:$chatId')
        .onBroadcast(event: 'typing', callback: (payload) {})
        .subscribe()
        .asStream()
        .map((event) {
          if (event.payload == null) return <String, dynamic>{};
          return Map<String, dynamic>.from(event.payload as Map);
        });
  }

  Future<void> sendTypingIndicator(String chatId, String userId, bool isTyping) async {
    await _client
        .channel('typing:$chatId')
        .sendBroadcast(
          event: 'typing',
          payload: {'userId': userId, 'isTyping': isTyping, 'timestamp': DateTime.now().toIso8601String()},
        );
  }
}