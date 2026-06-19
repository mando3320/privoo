// models/call_model.dart
class CallModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isVideo;

  /// 🔐 إصدار البروتوكول المستخدم (v1/v2)
  final int protocolVersion;

  /// 🔐 الخوارزمية المستخدمة في التشفير (AES-GCM-256 أو ChaCha20-Poly1305)
  final String? alg;

  /// 🔹 طابع زمني للـ Offer (millisecondsSinceEpoch)
  final int? offerTimestamp;

  /// 🔹 طابع زمني للـ Answer (millisecondsSinceEpoch)
  final int? answerTimestamp;

  /// 🔹 آخر عداد Ratchet المستخدم في المكالمة
  final int? ratchetN;

  /// 🔹 المفتاح العام DH الخاص بالجلسة (Base64)
  final String? dhPub;

  /// 🔹 حالة المكالمة (نشطة/منتهية)
  final bool isActive;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.startTime,
    this.endTime,
    this.isVideo = true,
    this.protocolVersion = 2,
    this.alg,
    this.offerTimestamp,
    this.answerTimestamp,
    this.ratchetN,
    this.dhPub,
    this.isActive = true,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) => CallModel(
        callId: json['callId'] ?? '',
        callerId: json['caller_id'] ?? json['callerId'] ?? '',
        receiverId: json['receiver_id'] ?? json['receiverId'] ?? '',
        startTime: DateTime.tryParse(json['start_time'] ?? json['startTime'] ?? '') ?? DateTime.now(),
        endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']) : 
                 json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
        isVideo: json['is_video'] ?? json['isVideo'] ?? true,
        protocolVersion: json['protocol_version'] ?? json['protocolVersion'] ?? 2,
        alg: json['alg'],
        offerTimestamp: json['offer_timestamp'] ?? json['offerTimestamp'],
        answerTimestamp: json['answer_timestamp'] ?? json['answerTimestamp'],
        ratchetN: json['ratchet_n'] ?? json['ratchetN'],
        dhPub: json['dh_pub'] ?? json['dhPub'],
        isActive: json['active'] ?? json['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'caller_id': callerId,
        'receiver_id': receiverId,
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        'is_video': isVideo,
        'protocol_version': protocolVersion,
        if (alg != null) 'alg': alg,
        if (offerTimestamp != null) 'offer_timestamp': offerTimestamp,
        if (answerTimestamp != null) 'answer_timestamp': answerTimestamp,
        if (ratchetN != null) 'ratchet_n': ratchetN,
        if (dhPub != null) 'dh_pub': dhPub,
        'active': isActive,
      };

  /// نسخ مع تعديل الحقول (copyWith)
  CallModel copyWith({
    String? callId,
    String? callerId,
    String? receiverId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isVideo,
    int? protocolVersion,
    String? alg,
    int? offerTimestamp,
    int? answerTimestamp,
    int? ratchetN,
    String? dhPub,
    bool? isActive,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isVideo: isVideo ?? this.isVideo,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      alg: alg ?? this.alg,
      offerTimestamp: offerTimestamp ?? this.offerTimestamp,
      answerTimestamp: answerTimestamp ?? this.answerTimestamp,
      ratchetN: ratchetN ?? this.ratchetN,
      dhPub: dhPub ?? this.dhPub,
      isActive: isActive ?? this.isActive,
    );
  }
}