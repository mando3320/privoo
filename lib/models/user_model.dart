class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isOnline;

  /// 🔐 بصمة المفتاح العام (fingerprint) لعرضها في واجهة التحقق
  final String? fingerprint;

  /// 🔐 المفتاح العام للهوية (X25519) - Base64
  final String? identityPublic;

  /// 🔐 المفتاح العام للتوقيع (Ed25519) - Base64
  final String? signPublic;

  /// 🔐 إصدار البروتوكول المستخدم (1 أو 2)
  final int protocolVersion;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.isOnline = false,
    this.fingerprint,
    this.identityPublic,
    this.signPublic,
    this.protocolVersion = 2,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        avatarUrl: json['avatarUrl'] ?? '',
        isOnline: json['isOnline'] ?? false,
        fingerprint: json['fingerprint'],
        identityPublic: json['identityPublic'],
        signPublic: json['signPublic'],
        protocolVersion: json['protocolVersion'] ?? 2,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'isOnline': isOnline,
        if (fingerprint != null) 'fingerprint': fingerprint,
        if (identityPublic != null) 'identityPublic': identityPublic,
        if (signPublic != null) 'signPublic': signPublic,
        'protocolVersion': protocolVersion,
      };

  /// نسخ مع تعديل الحقول (copyWith)
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isOnline,
    String? fingerprint,
    String? identityPublic,
    String? signPublic,
    int? protocolVersion,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      fingerprint: fingerprint ?? this.fingerprint,
      identityPublic: identityPublic ?? this.identityPublic,
      signPublic: signPublic ?? this.signPublic,
      protocolVersion: protocolVersion ?? this.protocolVersion,
    );
  }
}