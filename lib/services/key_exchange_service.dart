// lib/services/key_exchange_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KeyExchangeService {
  static const int _identityKeyVersion = 1;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// توليد مفتاح هوية X25519 للمستخدم (مرة واحدة)
  Future<void> ensureIdentityAndSignatureKeys(String userId) async {
    final response = await _supabase
        .from('keys')
        .select()
        .eq('user_id', userId)
        .eq('type', 'identity')
        .maybeSingle();

    if (response != null) return;

    final identityKey = await _generateX25519KeyPair();
    final signKey = await _generateEd25519KeyPair();

    await _supabase.from('keys').insert({
      'user_id': userId,
      'type': 'identity',
      'public_key': base64Encode(await identityKey.extractPublicKey()),
      'private_key': base64Encode(await identityKey.extractPrivateKeyBytes()),
      'version': _identityKeyVersion,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _supabase.from('keys').insert({
      'user_id': userId,
      'type': 'signature',
      'public_key': base64Encode(await signKey.extractPublicKey()),
      'private_key': base64Encode(await signKey.extractPrivateKeyBytes()),
      'version': _identityKeyVersion,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<SimpleKeyPair> getIdentityKeyPair(String userId) async {
    final response = await _supabase
        .from('keys')
        .select()
        .eq('user_id', userId)
        .eq('type', 'identity')
        .maybeSingle();

    if (response == null) throw Exception('Identity key not found');

    final privateKey = base64Decode(response['private_key']);
    return await _importPrivateKey(privateKey, KeyPairType.x25519);
  }

  Future<SimpleKeyPair> getSignatureKeyPair(String userId) async {
    final response = await _supabase
        .from('keys')
        .select()
        .eq('user_id', userId)
        .eq('type', 'signature')
        .maybeSingle();

    if (response == null) throw Exception('Signature key not found');

    final privateKey = base64Decode(response['private_key']);
    return await _importPrivateKey(privateKey, KeyPairType.ed25519);
  }

  Future<List<int>> fetchPeerIdentityPublicKey(String peerId) async {
    final response = await _supabase
        .from('keys')
        .select()
        .eq('user_id', peerId)
        .eq('type', 'identity')
        .maybeSingle();

    if (response == null) throw Exception('Peer identity key not found');
    return base64Decode(response['public_key']);
  }

  Future<List<int>> fetchPeerSignaturePublicKey(String peerId) async {
    final response = await _supabase
        .from('keys')
        .select()
        .eq('user_id', peerId)
        .eq('type', 'signature')
        .maybeSingle();

    if (response == null) throw Exception('Peer signature key not found');
    return base64Decode(response['public_key']);
  }

  /// إنشاء جلسة بين مستخدمين
  Future<SessionResult> establishSession({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  }) async {
    final myKeys = await getIdentityKeyPair(myUserId);
    final myPrivate = await myKeys.extractPrivateKeyBytes();

    final peerPubBytes = await fetchPeerIdentityPublicKey(peerUserId);
    final peerPub = await _importPublicKey(peerPubBytes, KeyPairType.x25519);

    final sharedSecret = await _x25519SharedSecret(myPrivate, peerPub);
    final msgKey = await _deriveMessageKey(sharedSecret, chatId, 'msg_key');

    return SessionResult(
      myPrivateKey: myPrivate,
      peerPublicKey: peerPubBytes,
      sharedSecret: sharedSecret,
      msgKey: msgKey,
      chatMasterKey: sharedSecret,
    );
  }

  Future<SessionResult> establishSessionWithEphemeral({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  }) async {
    final myKeys = await getIdentityKeyPair(myUserId);
    final myPrivate = await myKeys.extractPrivateKeyBytes();

    final peerPubBytes = await fetchPeerIdentityPublicKey(peerUserId);
    final peerPub = await _importPublicKey(peerPubBytes, KeyPairType.x25519);

    final sharedSecret = await _x25519SharedSecret(myPrivate, peerPub);
    const ephemeral = false;
    // This variable is only used in a future extension, but unused now

    final msgKey = await _deriveMessageKey(sharedSecret, chatId, 'msg_key');

    return SessionResult(
      myPrivateKey: myPrivate,
      peerPublicKey: peerPubBytes,
      sharedSecret: sharedSecret,
      msgKey: msgKey,
      chatMasterKey: sharedSecret,
    );
  }

  Future<List<int>> _x25519SharedSecret(
    List<int> myPrivate,
    SimplePublicKey peerPublic,
  ) async {
    final keyPair = await X25519.X25519KeyPair.fromPrivateKeyBytes(myPrivate);
    final sharedSecret = await keyPair.sharedSecret(peerPublic);
    return sharedSecret.bytes;
  }

  Future<List<int>> _deriveMessageKey(
    List<int> sharedSecret,
    String chatId,
    String purpose,
  ) async {
    final info = utf8.encode('privoo:$chatId:$purpose');
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecret),
      info: info,
    );
    return await derived.extractBytes();
  }

  static Future<String> pubFingerprint(List<int> pubBytes, {int bytes = 16}) async {
    final hash = await Sha256().hash(pubBytes);
    final fingerprint = hash.bytes.take(bytes).toList();
    return fingerprint.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }

  // ==================== مساعدين ====================

  Future<SimpleKeyPair> _generateX25519KeyPair() async {
    return await X25519.X25519KeyPair.generateRandom();
  }

  Future<SimpleKeyPair> _generateEd25519KeyPair() async {
    return await Ed25519.Ed25519KeyPair.generateRandom();
  }

  Future<SimpleKeyPair> _importPrivateKey(
    List<int> bytes,
    KeyPairType type,
  ) async {
    if (type == KeyPairType.x25519) {
      return await X25519.X25519KeyPair.fromPrivateKeyBytes(bytes);
    } else {
      return await Ed25519.Ed25519KeyPair.fromPrivateKeyBytes(bytes);
    }
  }

  Future<SimplePublicKey> _importPublicKey(
    List<int> bytes,
    KeyPairType type,
  ) async {
    if (type == KeyPairType.x25519) {
      return await X25519.X25519KeyPair.fromPublicKeyBytes(bytes);
    } else {
      return await Ed25519.Ed25519KeyPair.fromPublicKeyBytes(bytes);
    }
  }
}

enum KeyPairType { x25519, ed25519 }

class SessionResult {
  final List<int> myPrivateKey;
  final List<int> peerPublicKey;
  final List<int> sharedSecret;
  final List<int> msgKey;
  final List<int> chatMasterKey;

  SessionResult({
    required this.myPrivateKey,
    required this.peerPublicKey,
    required this.sharedSecret,
    required this.msgKey,
    required this.chatMasterKey,
  });
}