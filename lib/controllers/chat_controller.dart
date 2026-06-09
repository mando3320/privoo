// controllers/chat_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'app_controller.dart';
import '../models/message_model.dart';
import '../services/api/chat_service.dart';
import '../services/encryption_service.dart';
import '../services/ai/ai_service.dart';
import '../services/ratchet_service.dart';
import '../services/key_exchange_service.dart';
import '../services/sealed_sender.dart';
import '../services/export_chat_service.dart';
import '../services/advanced_search_service.dart';
import '../services/audit_log_service.dart';
import '../services/hive_storage_service.dart';
import '../services/typing_service.dart';

final encryptionServiceProvider = Provider<EncryptionService>((ref) => EncryptionService());

final chatControllerProvider = ChangeNotifierProvider<ChatController>((ref) => ChatController(ref: ref));

class ChatController extends ChangeNotifier {
  final Ref _ref;
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final KeyExchangeService _keyExchange = KeyExchangeService();
  final AuditLogService _auditLog = AuditLogService();
  final TypingService _typingService = TypingService();

  final TextEditingController inputController = TextEditingController();
  List<String> suggestions = [];

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  StreamSubscription<Position>? _liveLocationSub;
  bool _isLiveLocationActive = false;
  String? _currentLiveLocationChatId;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _callsSubscription;
  StreamSubscription? _backupSubscription;

  MessageModel? _replyingTo;
  MessageModel? _pinnedMessage;

  final SealedSenderService _sealedSender = SealedSenderService();
  bool _useSealedSender = true;

  // ============================================================
  // 🔬 المقاومة الكمومية (Quantum Resistance)
  // ============================================================
  
  bool _useQuantumResistance = true;
  bool _isQuantumSession = false;
  String _quantumFingerprint = '';

  MessageModel? get replyingTo => _replyingTo;
  MessageModel? get pinnedMessage => _pinnedMessage;
  bool get useSealedSender => _useSealedSender;
  bool get useQuantumResistance => _useQuantumResistance;
  bool get isQuantumSession => _isQuantumSession;
  String get quantumFingerprint => _quantumFingerprint;

  String get currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      logger.e('❌ محاولة استخدام currentUserId والمستخدم غير مسجل');
      return '';
    }
    return uid;
  }

  bool get _isProUser => _ref.read(appControllerProvider).isPro;
  bool get _isLifetimeUser => _ref.read(appControllerProvider).isLifetime;

  void setReplyingTo(MessageModel? message) {
    _replyingTo = message;
    notifyListeners();
  }

  void clearReplyingTo() {
    _replyingTo = null;
    notifyListeners();
  }

  Future<void> toggleSealedSender(bool value) async {
    _useSealedSender = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_sealed_sender', value);
    notifyListeners();
    logger.i('🔒 Sealed Sender: ${value ? "ON" : "OFF"}');
    
    await _auditLog.logEvent(
      eventType: AuditEventType.messageSent,
      details: 'Sealed Sender toggled: $value',
    );
  }

  Future<void> toggleQuantumResistance(bool value) async {
    _useQuantumResistance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_quantum_resistance', value);
    notifyListeners();
    logger.i('🔬 Quantum Resistance: ${value ? "ON" : "OFF"}');
  }

  Future<void> initQuantumSession(String chatId, String peerUserId) async {
    if (!_useQuantumResistance) return;
    
    try {
      final session = await _keyExchange.establishQuantumSession(
        chatId: chatId,
        myUserId: currentUserId,
        peerUserId: peerUserId,
        useQuantum: _useQuantumResistance,
      );
      
      _isQuantumSession = session.isQuantumReady;
      _quantumFingerprint = session.quantumFingerprint;
      notifyListeners();
      
      if (session.isQuantumReady) {
        logger.i('🔐 تم إنشاء جلسة كمومية للمحادثة $chatId');
      }
    } catch (e) {
      logger.w('⚠️ فشل إنشاء الجلسة الكمومية: $e');
    }
  }

  ChatController({required Ref ref}) : _ref = ref {
    _loadSealedSenderPreference();
    _loadQuantumResistancePreference();
  }

  Future<void> _loadSealedSenderPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useSealedSender = prefs.getBool('use_sealed_sender') ?? true;
    notifyListeners();
  }

  Future<void> _loadQuantumResistancePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _useQuantumResistance = prefs.getBool('use_quantum_resistance') ?? true;
    notifyListeners();
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    final peerUserId = _extractPeerUserId(chatId);
    return _chatService.getMessages(
      chatId: chatId,
      myUserId: currentUserId,
      peerUserId: peerUserId,
    );
  }

  String _extractPeerUserId(String chatId) {
    final ids = chatId.split('_');
    return ids.firstWhere((id) => id != currentUserId,
        orElse: () => ids.isEmpty ? '' : ids[0]);
  }

  Future<List<int>> _ensureSession(String chatId, String peerUserId) async {
    try {
      await RatchetService.nextSendingKey(chatId: chatId, myUserId: currentUserId);
      return [];
    } catch (e) {
      return await _chatService.initSession(
        chatId: chatId,
        myUserId: currentUserId,
        peerUserId: peerUserId,
      );
    }
  }

  Future<List<int>> _getCurrentSessionKey(String chatId) async {
    try {
      final ratchetData = await RatchetService.nextSendingKey(
        chatId: chatId,
        myUserId: currentUserId,
      );
      return ratchetData.mk;
    } catch (e) {
      return [];
    }
  }

  Future<void> _regularSend(String chatId, String receiverId, String plainText) async {
    await _ensureSession(chatId, receiverId);

    final replyToContent = _replyingTo?.content;
    final truncatedReply = replyToContent != null && replyToContent.length > 100
        ? '${replyToContent.substring(0, 100)}...'
        : replyToContent;

    final message = MessageModel(
      id: UniqueKey().toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      content: plainText,
      timestamp: DateTime.now(),
      type: MessageType.text,
      replyToMessageId: _replyingTo?.id,
      replyToSenderId: _replyingTo?.senderId,
      replyToContent: truncatedReply,
    );

    await _chatService.sendMessage(
      chatId: chatId,
      message: message,
      myUserId: currentUserId,
      peerUserId: receiverId,
    );
    
    await _auditLog.logEvent(
      eventType: AuditEventType.messageSent,
      details: 'Message sent to $receiverId',
    );
  }

  Future<void> sendTextMessage(String chatId, String receiverId) async {
    final plainText = inputController.text.trim();
    if (plainText.isEmpty) return;

    try {
      if (_useSealedSender) {
        try {
          await _sealedSender.sendSealedMessage(
            chatId: chatId,
            message: plainText,
            recipientId: receiverId,
          );
          logger.d('📨 Sealed message sent to $receiverId');
        } catch (e) {
          logger.e('❌ Sealed sender failed: $e');
          await _regularSend(chatId, receiverId, plainText);
        }
      } else {
        await _regularSend(chatId, receiverId, plainText);
      }

      inputController.clear();
      _replyingTo = null;
      notifyListeners();

      if (plainText.toLowerCase().contains("privoo")) {
        await _handleBotReply(chatId, receiverId, plainText);
      }
    } catch (e) {
      logger.e('❌ فشل إرسال الرسالة: $e');
    }
  }

  Future<void> _handleBotReply(String chatId, String receiverId, String plainText) async {
    final app = _ref.read(appControllerProvider);
    final aiService = AIService();

    if (!app.canSendMessage) {
      final warning = "تم الوصول إلى الحد اليومي. اشترك في Privoo Pro للاستمرار.";
      final botMessage = MessageModel(
        id: UniqueKey().toString(),
        senderId: "PrivooAI",
        receiverId: currentUserId,
        content: warning,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      await _chatService.sendMessage(
        chatId: chatId,
        message: botMessage,
        myUserId: currentUserId,
        peerUserId: receiverId,
      );
      return;
    }

    final botReply = await aiService.chat(
      user: currentUserId,
      message: plainText,
      isPro: app.isPro,
      isLifetime: app.isLifetime,
      messagesToday: app.messagesToday,
      withRAG: true,
    );

    if (!botReply.startsWith('[')) {
      await app.incrementMessageCount();
    }

    final botMessage = MessageModel(
      id: UniqueKey().toString(),
      senderId: "PrivooAI",
      receiverId: currentUserId,
      content: botReply,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    await _chatService.sendMessage(
      chatId: chatId,
      message: botMessage,
      myUserId: currentUserId,
      peerUserId: receiverId,
    );
  }

  Future<void> sendDisappearingMessage(
    String chatId,
    String receiverId,
    DisappearDuration duration,
  ) async {
    final plainText = inputController.text.trim();
    if (plainText.isEmpty) return;

    await _ensureSession(chatId, receiverId);

    final disappearAt = duration.seconds > 0
        ? DateTime.now().add(Duration(seconds: duration.seconds))
        : null;

    final message = MessageModel(
      id: UniqueKey().toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      content: plainText,
      timestamp: DateTime.now(),
      type: MessageType.text,
      disappearAfterSeconds: duration.seconds > 0 ? duration.seconds : null,
      disappearAt: disappearAt,
    );

    await _chatService.sendMessage(
      chatId: chatId,
      message: message,
      myUserId: currentUserId,
      peerUserId: receiverId,
    );

    inputController.clear();
    notifyListeners();
  }

  Future<void> togglePinMessage(String chatId, String messageId, bool isPinned) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': !isPinned});
    
    if (!isPinned) {
      _pinnedMessage = null;
    }
    notifyListeners();
  }

  Future<void> sendMentionMessage(
    String chatId,
    String receiverId,
    List<String> mentionedUserIds,
  ) async {
    final plainText = inputController.text.trim();
    if (plainText.isEmpty) return;

    await _ensureSession(chatId, receiverId);

    final message = MessageModel(
      id: UniqueKey().toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      content: plainText,
      timestamp: DateTime.now(),
      type: MessageType.text,
      mentions: mentionedUserIds,
    );

    await _chatService.sendMessage(
      chatId: chatId,
      message: message,
      myUserId: currentUserId,
      peerUserId: receiverId,
    );

    inputController.clear();
    notifyListeners();
  }

  Future<void> sendSmartReply(String reply, String chatId, String receiverId) async {
    inputController.text = reply;
    await sendTextMessage(chatId, receiverId);
  }

  Future<String> _uploadFileEncrypted(String localPath, String folder, String chatId) async {
    final file = File(localPath);
    final bytes = await file.readAsBytes();
    
    final sessionKey = await _getCurrentSessionKey(chatId);
    if (sessionKey.isEmpty) {
      throw Exception('No session key available');
    }
    
    final encryptedBytes = await EncryptionService.encryptBytes(bytes, sessionKey);
    
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/enc_${DateTime.now().millisecondsSinceEpoch}.bin');
    await tempFile.writeAsBytes(encryptedBytes);
    
    final fileName = "${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}.enc";
    final ref = _storage.ref().child("$folder/$currentUserId/$fileName");
    await ref.putFile(tempFile);
    final url = await ref.getDownloadURL();
    
    await tempFile.delete();
    
    return url;
  }

  Future<void> sendMediaMessage(
    String chatId,
    String receiverId,
    String localPath,
    String type,
  ) async {
    final file = File(localPath);
    final fileSize = await file.length();

    if (!_validateFileSize(fileSize)) return;

    await _ensureSession(chatId, receiverId);

    String folder = "files";
    MessageType messageType = MessageType.file;

    if (type == "image") {
      folder = "images";
      messageType = MessageType.image;
    } else if (type == "video") {
      folder = "videos";
      messageType = MessageType.video;
    } else if (type == "audio") {
      folder = "voices";
      messageType = MessageType.audio;
    } else if (type == "gif") {
      folder = "gifs";
      messageType = MessageType.gif;
    }

    final url = await _uploadFileEncrypted(localPath, folder, chatId);

    final message = MessageModel(
      id: UniqueKey().toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      content: url,
      timestamp: DateTime.now(),
      type: messageType,
    );

    await _chatService.sendMessage(
      chatId: chatId,
      message: message,
      myUserId: currentUserId,
      peerUserId: receiverId,
    );
  }

  Future<void> sendImageMessage(String chatId, String receiverId, String path, int size) =>
      sendMediaMessage(chatId, receiverId, path, "image");

  Future<void> sendVideoMessage(String chatId, String receiverId, String path, int size) =>
      sendMediaMessage(chatId, receiverId, path, "video");

  Future<void> sendAudioMessage(String chatId, String receiverId, String path, int size) =>
      sendMediaMessage(chatId, receiverId, path, "audio");

  Future<void> sendDocumentMessage(String chatId, String receiverId, String path, int size) =>
      sendMediaMessage(chatId, receiverId, path, "file");

  Future<void> sendGifMessage(String chatId, String receiverId, String url, int size) =>
      sendMediaMessage(chatId, receiverId, url, "gif");

  Future<void> sendContactMessage(
      String chatId, String receiverId, String contactName, [String? phone]) async {
    final payload = jsonEncode({'name': contactName, 'phone': phone});
    final message = MessageModel(
      id: UniqueKey().toString(),
      senderId: currentUserId,
      receiverId: receiverId,
      content: payload,
      timestamp: DateTime.now(),
      type: MessageType.file,
    );
    await _chatService.sendMessage(
      chatId: chatId,
      message: message,
      myUserId: currentUserId,
      peerUserId: receiverId,
    );
  }

  Future<void> exportCurrentChat(String chatId) async {
    try {
      final messages = await _getAllMessagesForChat(chatId);
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await ExportChatService.exportToJson(chatId, messagesJson);
      logger.i('📄 تم تصدير المحادثة $chatId بنجاح');
    } catch (e) {
      logger.e('❌ فشل تصدير المحادثة: $e');
      rethrow;
    }
  }
  
  Future<List<MessageModel>> _getAllMessagesForChat(String chatId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .get();
    
    return snapshot.docs
        .map((doc) => MessageModel.fromDoc(doc))
        .toList();
  }

  Future<List<MessageModel>> advancedSearch(String query) async {
    final searchService = AdvancedSearchService();
    return await searchService.searchMessages(
      userId: currentUserId,
      query: query,
    );
  }

  Future<void> sendLocationMessage(String chatId, String receiverId) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) {
          logger.w("❌ إذن الموقع مرفوض");
          return;
        }
      }

      await _ensureSession(chatId, receiverId);
      
      final pos = await Geolocator.getCurrentPosition();
      final sessionKey = await _getCurrentSessionKey(chatId);
      
      final encryptedLat = await EncryptionService.encrypt(
        plaintext: pos.latitude.toString(),
        keyBytes: sessionKey,
      );
      final encryptedLng = await EncryptionService.encrypt(
        plaintext: pos.longitude.toString(),
        keyBytes: sessionKey,
      );
      
      final payload = jsonEncode({
        'lat': encryptedLat,
        'lng': encryptedLng,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });

      final message = MessageModel(
        id: UniqueKey().toString(),
        senderId: currentUserId,
        receiverId: receiverId,
        content: payload,
        timestamp: DateTime.now(),
        type: MessageType.file,
      );

      await _chatService.sendMessage(
        chatId: chatId,
        message: message,
        myUserId: currentUserId,
        peerUserId: receiverId,
      );
    } catch (e) {
      logger.e("❌ فشل إرسال الموقع: $e");
    }
  }

  Future<void> startLiveLocation(String chatId) async {
    if (_isLiveLocationActive) return;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) {
          logger.w("❌ إذن الموقع مرفوض");
          return;
        }
      }

      await _ensureSession(chatId, _extractPeerUserId(chatId));
      _currentLiveLocationChatId = chatId;
      _isLiveLocationActive = true;
      
      final docId = "${chatId}_$currentUserId";
      final ref = _firestore.collection('live_locations').doc(docId);

      await ref.set({
        'chatId': chatId,
        'userId': currentUserId,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _liveLocationSub = Geolocator.getPositionStream().listen((pos) async {
        if (!_isLiveLocationActive) return;
        
        final sessionKey = await _getCurrentSessionKey(chatId);
        final encryptedLat = await EncryptionService.encrypt(
          plaintext: pos.latitude.toString(),
          keyBytes: sessionKey,
        );
        final encryptedLng = await EncryptionService.encrypt(
          plaintext: pos.longitude.toString(),
          keyBytes: sessionKey,
        );
        
        await ref.set({
          'lat': encryptedLat,
          'lng': encryptedLng,
          'accuracy': pos.accuracy,
          'speed': pos.speed,
          'ts': DateTime.now().millisecondsSinceEpoch,
          'active': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      logger.d("✅ بدأ إرسال الموقع الحي المشفر");
    } catch (e) {
      logger.e("❌ خطأ بدء LiveLocation: $e");
      _isLiveLocationActive = false;
    }
  }

  Future<void> stopLiveLocation(String chatId) async {
    if (!_isLiveLocationActive) return;
    try {
      _isLiveLocationActive = false;
      _currentLiveLocationChatId = null;
      await _liveLocationSub?.cancel();
      _liveLocationSub = null;

      final docId = "${chatId}_$currentUserId";
      final ref = _firestore.collection('live_locations').doc(docId);
      await ref.update({
        'active': false,
        'stoppedAt': FieldValue.serverTimestamp(),
      });
      logger.d("⛔ تم إيقاف LiveLocation");
    } catch (e) {
      logger.e("❌ خطأ إيقاف LiveLocation: $e");
    }
  }

  Future<void> startVoiceRecording(String chatId, String receiverId) async {
    if (!_isRecording) {
      final canRecord = await _recorder.hasPermission();
      if (!canRecord) {
        logger.w("❌ إذن التسجيل مرفوض");
        return;
      }

      final tmpDir = await getTemporaryDirectory();
      final filePath = "${tmpDir.path}/privoo_voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );
      _isRecording = true;
      _currentRecordingPath = filePath;
      notifyListeners();
      logger.d("🔴 بدأ تسجيل الصوت: $filePath");
    } else {
      final pathRecorded = await _recorder.stop();
      _isRecording = false;
      notifyListeners();
      logger.d("⏹️ توقف التسجيل، الملف: $pathRecorded");

      if (pathRecorded != null) {
        final file = File(pathRecorded);
        final size = await file.length();
        if (!_validateFileSize(size)) {
          logger.w("❌ ملف الصوت كبير جدًا، لم يتم الإرسال");
          return;
        }
        await sendAudioMessage(chatId, receiverId, pathRecorded, size);
      }
    }
  }

  void analyzeInput(String input) async {
    final aiService = AIService();
    final app = _ref.read(appControllerProvider);
    final reply = await aiService.chat(
      user: currentUserId,
      message: input,
      isPro: app.isPro,
      isLifetime: app.isLifetime,
      messagesToday: app.messagesToday,
      withRAG: false,
    );
    if (reply.isNotEmpty && !reply.startsWith('[')) {
      suggestions.clear();
      suggestions.add(reply);
      notifyListeners();
    }
  }

  Future<void> backupChat(String chatId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    final messages = snapshot.docs.map((doc) => MessageModel.fromDoc(doc)).toList();

    if (!_isProUser) {
      logger.w("❌ النسخة الاحتياطية للمستخدم العادي غير متاحة");
      return;
    }

    await _firestore
        .collection('backups')
        .doc(currentUserId)
        .collection('chats')
        .doc(chatId)
        .set({
      'chatId': chatId,
      'messages': messages.map((m) => m.toMap()).toList(),
      'timestamp': DateTime.now(),
    });

    logger.d("✅ تم إنشاء نسخة احتياطية للمحادثة $chatId");
  }

  Future<List<MessageModel>> restoreChat(String chatId) async {
    final doc = await _firestore
        .collection('backups')
        .doc(currentUserId)
        .collection('chats')
        .doc(chatId)
        .get();

    if (!doc.exists) {
      logger.w("⚠️ لا يوجد نسخة احتياطية");
      return [];
    }

    final data = doc.data()!;
    final messages = (data['messages'] as List)
        .map((m) => MessageModel.fromMap(m['id'] ?? '', m))
        .toList();

    logger.d("✅ تم استرجاع المحادثة (${messages.length} رسالة)");
    return messages;
  }

  String getLanguage() => _ref.read(appControllerProvider).locale.languageCode;

  Future<void> startVoiceCall(String receiverId) async {
    logger.d("📞 بدء مكالمة صوتية (لم يُنفّذ بعد)");
    await _auditLog.logEvent(
      eventType: AuditEventType.callStarted,
      details: 'Voice call to $receiverId',
    );
  }

  Future<void> startVideoCall(String receiverId) async {
    logger.d("🎥 بدء مكالمة فيديو (لم يُنفّذ بعد)");
    await _auditLog.logEvent(
      eventType: AuditEventType.callStarted,
      details: 'Video call to $receiverId',
    );
  }

  bool _validateFileSize(int fileSize) {
    final limit = (_isProUser || _isLifetimeUser) 
        ? 2 * 1024 * 1024 * 1024
        : 10 * 1024 * 1024;
        
    if (fileSize > limit) {
      logger.w("❌ الملف أكبر من ${limit ~/ (1024 * 1024)}MB — يسمح فقط للمستخدمين Pro");
      return false;
    }
    return true;
  }

  Future<void> cacheMessageLocally(MessageModel message) async {
    try {
      // await HiveStorageService.saveMessage(message.id, message);
      logger.d('📦 تم حفظ الرسالة محلياً (معلق مؤقتاً)');
    } catch (e) {
      logger.e('❌ فشل حفظ الرسالة محلياً: $e');
    }
  }
  
  Future<MessageModel?> getCachedMessage(String messageId) async {
    try {
      // return await HiveStorageService.getMessage(messageId);
      logger.d('📦 استرجاع رسالة من الكاش (معلق مؤقتاً)');
      return null;
    } catch (e) {
      logger.e('❌ فشل استرجاع الرسالة من الكاش: $e');
      return null;
    }
  }

  // ✅ Typing Indicator Methods
  void onTypingStart(String chatId) {
    _typingService.startTyping(chatId);
  }

  void onTypingStop() {
    _typingService.stopTyping();
  }

  Stream<bool> getTypingStatus(String chatId, String otherUserId) {
    return _typingService.listenToTyping(chatId, otherUserId);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _callsSubscription?.cancel();
    _backupSubscription?.cancel();
    
    _liveLocationSub?.cancel();
    
    inputController.dispose();
    _recorder.dispose();
    
    super.dispose();
    logger.d('🧹 ChatController: تم تنظيف جميع الـ Streams والموارد');
  }
}

enum DisappearDuration {
  off(0, 'إيقاف'),
  seconds5(5, '5 ثواني'),
  seconds30(30, '30 ثانية'),
  minute1(60, 'دقيقة واحدة'),
  hour1(3600, 'ساعة واحدة'),
  day1(86400, 'يوم واحد');

  const DisappearDuration(this.seconds, this.label);
  final int seconds;
  final String label;
}