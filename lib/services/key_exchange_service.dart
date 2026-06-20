// lib/services/key_exchange_service.dart
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KeyExchangeService {
  static const int _identityKeyVersion = 1;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _identityPrivateKeyPrefix = 'privoo_identity_priv_';
  static const String _signaturePrivateKeyPrefix = 'privoo_signature_priv_';

  Future<void> ensureIdentityAndSignatureKeys(String userId) async {
    final identityPrivKey = await _secureStorage.read(key: '$_identityPrivateKeyPrefix$userId');
    final signaturePrivKey = await _secureStorage.read(key: '$_signaturePrivateKeyPrefix$userId');
    
    if (identityPrivKey != null && signaturePrivKey != null) {
      return;
    }

    final identityKey = await X25519().newKeyPair();
    final signKey = await Ed25519().newKeyPair();

    final identityPub = await identityKey.extractPublicKey();
    final signPub = await signKey.extractPublicKey();

    await _secureStorage.write(
      key: '$_identityPrivateKeyPrefix$userId',
      value: base64Encode(await identityKey.extractPrivateKeyBytes()),
    );
    await _secureStorage.write(
      key: '$_signaturePrivateKeyPrefix$userId',
      value: base64Encode(await signKey.extractPrivateKeyBytes()),
    );

    await _supabase.from('keys').upsert({
      'user_id': userId,
      'type': 'identity',
      'public_key': base64Encode(identityPub.bytes),
      'version': _identityKeyVersion,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,type');

    await _supabase.from('keys').upsert({
      'user_id': userId,
      'type': 'signature',
      'public_key': base64Encode(signPub.bytes),
      'version': _identityKeyVersion,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,type');
  }

  Future<SimpleKeyPair> getIdentityKeyPair(String userId) async {
    final privKeyBase64 = await _secureStorage.read(key: '$_identityPrivateKeyPrefix$userId');
    if (privKeyBase64 == null) throw Exception('Identity private key not found');
    
    final privateKey = base64Decode(privKeyBase64);
    final pubKeyResponse = await _supabase
        .from('keys')
        .select('public_key')
        .eq('user_id', userId)
        .eq('type', 'identity')
        .maybeSingle();
    
    if (pubKeyResponse == null) throw Exception('Identity public key not found');
    final publicKey = base64Decode(pubKeyResponse['public_key']);
    
    return await X25519().newKeyPairFromSeed(privateKey, publicKey: publicKey);
  }

  Future<SimpleKeyPair> getSignatureKeyPair(String userId) async {
    final privKeyBase64 = await _secureStorage.read(key: '$_signaturePrivateKeyPrefix$userId');
    if (privKeyBase64 == null) throw Exception('Signature private key not found');
    
    final privateKey = base64Decode(privKeyBase64);
    return await Ed25519().newKeyPairFromSeed(privateKey);
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

  Future<SessionResult> establishSession({
    required String chatId,
    required String myUserId,
    required String peerUserId,
  }) async {
    final myKeys = await getIdentityKeyPair(myUserId);
    final myPrivate = await myKeys.extractPrivateKeyBytes();

    final peerPubBytes = await fetchPeerIdentityPublicKey(peerUserId);
    final peerPub = await X25519().newKeyPairFromSeed(myPrivate, publicKey: peerPubBytes);

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
    final peerPub = await X25519().newKeyPairFromSeed(myPrivate, publicKey: peerPubBytes);

    final ephemeralKey = await X25519().newKeyPair();
    final ephemeralPub = await ephemeralKey.extractPublicKey();
    
    final sharedSecret = await _x25519SharedSecret(myPrivate, peerPub);
    final ephemeralSecret = await _x25519SharedSecret(await ephemeralKey.extractPrivateKeyBytes(), peerPub);
    
    final combinedSecret = [...sharedSecret, ...ephemeralSecret];
    final msgKey = await _deriveMessageKey(combinedSecret, chatId, 'msg_key');

    return SessionResult(
      myPrivateKey: myPrivate,
      peerPublicKey: peerPubBytes,
      sharedSecret: combinedSecret,
      msgKey: msgKey,
      chatMasterKey: combinedSecret,
    );
  }

  Future<List<int>> _x25519SharedSecret(
    List<int> myPrivate,
    SimplePublicKey peerPublic,
  ) async {
    final keyPair = await X25519().newKeyPairFromSeed(myPrivate);
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

  Future<void> deleteAllKeys(String userId) async {
    await _secureStorage.delete(key: '$_identityPrivateKeyPrefix$userId');
    await _secureStorage.delete(key: '$_signaturePrivateKeyPrefix$userId');
    
    await _supabase
        .from('keys')
        .delete()
        .eq('user_id', userId);
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