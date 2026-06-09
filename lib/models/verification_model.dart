// lib/models/verification_model.dart
class VerificationModel {
  final String id;
  final String userId;
  final String peerId;
  final String? fingerprint;
  final bool isVerified;
  final DateTime? createdAt;

  VerificationModel({
    required this.id,
    required this.userId,
    required this.peerId,
    this.fingerprint,
    required this.isVerified,
    this.createdAt,
  });

  factory VerificationModel.fromJson(Map<String, dynamic> json) {
    return VerificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      peerId: json['peerId'] ?? '',
      fingerprint: json['fingerprint'],
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'peerId': peerId,
    'fingerprint': fingerprint,
    'isVerified': isVerified,
    'createdAt': createdAt?.toIso8601String(),
  };
}
