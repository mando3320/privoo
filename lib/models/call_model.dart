import 'package:cloud_firestore/cloud_firestore.dart';

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
        callerId: json['callerId'] ?? '',
        receiverId: json['receiverId'] ?? '',
        startTime: _parseDate(json['startTime']),
        endTime: json['endTime'] != null ? _parseDate(json['endTime']) : null,
        isVideo: json['isVideo'] ?? true,
        protocolVersion: json['protocolVersion'] ?? 2,
        alg: json['alg'],
        offerTimestamp: json['offerTimestamp'],
        answerTimestamp: json['answerTimestamp'],
        ratchetN: json['ratchetN'],
        dhPub: json['dhPub'],
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'callerId': callerId,
        'receiverId': receiverId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isVideo': isVideo,
        'protocolVersion': protocolVersion,
        if (alg != null) 'alg': alg,
        if (offerTimestamp != null) 'offerTimestamp': offerTimestamp,
        if (answerTimestamp != null) 'answerTimestamp': answerTimestamp,
        if (ratchetN != null) 'ratchetN': ratchetN,
        if (dhPub != null) 'dhPub': dhPub,
        'isActive': isActive,
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

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