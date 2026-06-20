// lib/models/message_model.dart

enum MessageType { text, image, gif, video, voice, audio, file }

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
    this.protocolVersion = 2,
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

  bool get isPrivate => groupId == null;
  bool get isGroup => groupId != null;

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['sender_id'] ?? data['senderId'] ?? '',
      receiverId: data['recipient_id'] ?? data['receiver_id'] ?? data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: _parseDate(data['timestamp']),
      isRead: data['is_read'] ?? data['isRead'] ?? false,
      type: _parseType(data['message_type'] ?? data['type']),
      fileSize: data['file_size'] is int ? data['file_size'] as int : 
                data['fileSize'] is int ? data['fileSize'] as int : null,
      isProRequired: data['is_pro_required'] ?? data['isProRequired'] ?? false,
      ratchetN: _toIntSafe(data['ratchet_n'] ?? data['ratchetN']),
      protocolVersion: _toIntSafe(data['protocol_version'] ?? data['protocolVersion'], defaultValue: 2),
      alg: data['alg'] as String? ?? 'AES-GCM-256',
      dhPub: data['dh_pub'] as String? ?? data['dhPub'] as String?,
      disappearAfterSeconds: data['disappear_after_seconds'] as int? ?? data['disappearAfterSeconds'] as int?,
      disappearAt: data['disappear_at'] != null ? _parseDate(data['disappear_at']) : 
                   data['disappearAt'] != null ? _parseDate(data['disappearAt']) : null,
      isPinned: data['is_pinned'] ?? data['isPinned'] ?? false,
      replyToMessageId: data['reply_to_message_id'] as String? ?? data['replyToMessageId'] as String?,
      replyToSenderId: data['reply_to_sender_id'] as String? ?? data['replyToSenderId'] as String?,
      replyToContent: data['reply_to_content'] as String? ?? data['replyToContent'] as String?,
      mentions: (data['mentions'] as List<dynamic>?)?.cast<String>(),
      groupId: data['group_id'] as String? ?? data['groupId'] as String?,
      reactions: (data['reactions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, _toIntSafe(v)),
      ),
      pollId: data['poll_id'] as int? ?? data['pollId'] as int?,
    );
  }

  factory MessageModel.fromSupabase(Map<String, dynamic> data) {
    return MessageModel.fromMap(data['id'] ?? '', data);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'message_type': type.name,
      'file_size': fileSize,
      'is_pro_required': isProRequired,
      'ratchet_n': ratchetN,
      'protocol_version': protocolVersion,
      if (alg != null) 'alg': alg,
      if (dhPub != null) 'dh_pub': dhPub,
      if (disappearAfterSeconds != null) 'disappear_after_seconds': disappearAfterSeconds,
      if (disappearAt != null) 'disappear_at': disappearAt!.toIso8601String(),
      'is_pinned': isPinned,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (replyToSenderId != null) 'reply_to_sender_id': replyToSenderId,
      if (replyToContent != null) 'reply_to_content': replyToContent,
      if (mentions != null && mentions!.isNotEmpty) 'mentions': mentions,
      if (groupId != null) 'group_id': groupId,
      if (reactions != null && reactions!.isNotEmpty) 'reactions': reactions,
      if (pollId != null) 'poll_id': pollId,
    };
  }

  Map<String, dynamic> toJson() => toMap();

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

  static DateTime _parseDate(dynamic v) {
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

  static int _toIntSafe(dynamic v, {int defaultValue = 0}) {
    if (v is int) return v;
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
    if (v is double) return v.toInt();
    return defaultValue;
  }
}