// models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 أنواع الرسائل المدعومة في التطبيق
enum MessageType { text, image, gif, video, voice, audio, file }

/// 🔹 مدة اختفاء الرسالة
enum DisappearDuration {
  off(0, 'لا تختفي'),
  seconds5(5, 'بعد 5 ثواني'),
  seconds30(30, 'بعد 30 ثانية'),
  minute1(60, 'بعد دقيقة'),
  hour1(3600, 'بعد ساعة'),
  day1(86400, 'بعد يوم');

  final int seconds;
  final String label;

  const DisappearDuration(this.seconds, this.label);

  static DisappearDuration fromSeconds(int seconds) {
    return DisappearDuration.values.firstWhere(
      (d) => d.seconds == seconds,
      orElse: () => off,
    );
  }
}

/// قائمة الردود التفاعلية المتاحة
const List<String> availableReactions = ['❤️', '👍', '😂', '😮', '😢', '😡'];

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final int? fileSize;
  final bool isProRequired;
  final int ratchetN;
  final int protocolVersion;
  final String? alg;
  final String? dhPub;

  // ✅ الميزات المتقدمة
  final int? disappearAfterSeconds;
  final DateTime? disappearAt;
  final bool isPinned;
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToContent;
  final List<String>? mentions;
  final String? groupId;
  final Map<String, int>? reactions;
  final int? pollId;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.fileSize,
    this.isProRequired = false,
    this.ratchetN = 0,
    this.protocolVersion = 1,
    this.alg,
    this.dhPub,
    this.disappearAfterSeconds,
    this.disappearAt,
    this.isPinned = false,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToContent,
    this.mentions,
    this.groupId,
    this.reactions,
    this.pollId,
  });

  /// هل هذه رسالة فردية؟
  bool get isPrivate => groupId == null;

  /// هل هذه رسالة جماعية؟
  bool get isGroup => groupId != null;

  factory MessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['recipientId'] ?? data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: _tsToDate(data['timestamp']),
      isRead: data['isRead'] ?? false,
      type: _parseType(data['messageType'] ?? data['type']),
      fileSize: data['fileSize'] is int ? data['fileSize'] as int : null,
      isProRequired: data['isProRequired'] ?? false,
      ratchetN: _toIntSafe(data['ratchetN']),
      protocolVersion: _toIntSafe(data['protocolVersion']) == 0 ? 1 : _toIntSafe(data['protocolVersion']),
      alg: data['alg'] as String? ?? 'AES-GCM-256',
      dhPub: data['dhPub'] as String?,
      disappearAfterSeconds: data['disappearAfterSeconds'] as int?,
      disappearAt: data['disappearAt'] != null ? _parseDate(data['disappearAt']) : null,
      isPinned: data['isPinned'] ?? false,
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToSenderId: data['replyToSenderId'] as String?,
      replyToContent: data['replyToContent'] as String?,
      mentions: (data['mentions'] as List<dynamic>?)?.cast<String>(),
      groupId: data['groupId'] as String?,
      reactions: (data['reactions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ),
      pollId: data['pollId'] as int?,
    );
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['recipientId'] ?? data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: _tsToDate(data['timestamp']),
      isRead: data['isRead'] ?? false,
      type: _parseType(data['messageType'] ?? data['type']),
      fileSize: data['fileSize'] is int ? data['fileSize'] as int : null,
      isProRequired: data['isProRequired'] ?? false,
      ratchetN: _toIntSafe(data['ratchetN']),
      protocolVersion: _toIntSafe(data['protocolVersion']) == 0 ? 1 : _toIntSafe(data['protocolVersion']),
      alg: data['alg'] as String? ?? 'AES-GCM-256',
      dhPub: data['dhPub'] as String?,
      disappearAfterSeconds: data['disappearAfterSeconds'] as int?,
      disappearAt: data['disappearAt'] != null ? _parseDate(data['disappearAt']) : null,
      isPinned: data['isPinned'] ?? false,
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToSenderId: data['replyToSenderId'] as String?,
      replyToContent: data['replyToContent'] as String?,
      mentions: (data['mentions'] as List<dynamic>?)?.cast<String>(),
      groupId: data['groupId'] as String?,
      reactions: (data['reactions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ),
      pollId: data['pollId'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch),
      'isRead': isRead,
      'messageType': type.name,
      'fileSize': fileSize,
      'isProRequired': isProRequired,
      'ratchetN': ratchetN,
      'protocolVersion': protocolVersion,
      if (alg != null) 'alg': alg,
      if (dhPub != null) 'dhPub': dhPub,
      if (disappearAfterSeconds != null) 'disappearAfterSeconds': disappearAfterSeconds,
      if (disappearAt != null) 'disappearAt': disappearAt!.toIso8601String(),
      'isPinned': isPinned,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      if (replyToContent != null) 'replyToContent': replyToContent,
      if (mentions != null && mentions!.isNotEmpty) 'mentions': mentions,
      if (groupId != null) 'groupId': groupId,
      if (reactions != null && reactions!.isNotEmpty) 'reactions': reactions,
      if (pollId != null) 'pollId': pollId,
    };
  }

  Map<String, dynamic> toJson() => {'id': id, ...toMap()};

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel.fromMap(json['id'] ?? '', json);
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    int? fileSize,
    bool? isProRequired,
    int? ratchetN,
    int? protocolVersion,
    String? alg,
    String? dhPub,
    int? disappearAfterSeconds,
    DateTime? disappearAt,
    bool? isPinned,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToContent,
    List<String>? mentions,
    String? groupId,
    Map<String, int>? reactions,
    int? pollId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      fileSize: fileSize ?? this.fileSize,
      isProRequired: isProRequired ?? this.isProRequired,
      ratchetN: ratchetN ?? this.ratchetN,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      alg: alg ?? this.alg,
      dhPub: dhPub ?? this.dhPub,
      disappearAfterSeconds: disappearAfterSeconds ?? this.disappearAfterSeconds,
      disappearAt: disappearAt ?? this.disappearAt,
      isPinned: isPinned ?? this.isPinned,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToContent: replyToContent ?? this.replyToContent,
      mentions: mentions ?? this.mentions,
      groupId: groupId ?? this.groupId,
      reactions: reactions ?? this.reactions,
      pollId: pollId ?? this.pollId,
    );
  }

  static DateTime _tsToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is DateTime) return v;
    return DateTime.now();
  }

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is DateTime) return v;
    return DateTime.now();
  }

  static MessageType _parseType(dynamic v) {
    if (v is MessageType) return v;
    if (v is String) {
      final name = v.toLowerCase();
      for (final t in MessageType.values) {
        if (t.name == name) return t;
      }
    }
    return MessageType.text;
  }

  static int _toIntSafe(dynamic v) {
    if (v is int) return v;
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
    return 0;
  }
}