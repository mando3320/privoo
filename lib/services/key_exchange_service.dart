// services/key_exchange_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../main.dart';
import 'quantum_resistant_service.dart';

class KeyExchangeService {
  final _db = FirebaseFirestore.instance;
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final x25519 = X25519();
  static final ed25519 = Ed25519();
  static final hkdf32 = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static String _identPrivKey(String userId) => 'identPriv:$userId';
  static String _identPubKey(String userId) => 'identPub:$userId';
  static String _signPrivKey(String userId) => 'signPriv:$userId';
  static String _signPubKey(String userId) => 'signPub:$userId';
  static String _signedPrekeyPriv(String userId) => 'spkPriv:$userId';
  static String _signedPrekeyPub(String userId) => 'spkPub:$userId';
  static String _oneTimePrefix(String userId) => 'otp:$userId:';

  static final Map<String, List<DateTime>> _prekeyRequests = {};
  static const int _maxRequestsPerMinute = 10;
  static final Map<String, Set<String>> _usedNonces = {};
  static final Map<String, String> _confirmationMacs = {};

  Future<void> ensureIdentityAndSignatureKeys(String userId) async {
    final identPrivB64 = await _secure.read(key: _identPrivKey(userId));
    final identPubB64 = await _secure.read(key: _identPubKey(userId));
    final signPrivB64 = await _secure.read(key: _signPrivKey(userId));
    final signPubB64 = await _secure.read(key: _signPubKey(userId));

    SimpleKeyPair identPair;
    SimplePublicKey identPub;
    if (identPrivB64 != null && identPubB64 != null) {
      identPair = SimpleKeyPairData(
        base64Decode(identPrivB64),
        publicKey: SimplePublicKey(base64Decode(identPubB64),
            type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
      identPub = await identPair.extractPublicKey();
      logger.d('🔑 تم تحميل مفتاح الهوية الحالي: $userId');
    } else {
      identPair = await x25519.newKeyPair();
      identPub = await identPair.extractPublicKey();
      final privBytes = await identPair.extractPrivateKeyBytes();
      await _secure.write(
          key: _identPrivKey(userId), value: base64Encode(privBytes));
      await _secure.write(
          key: _identPubKey(userId), value: base64Encode(identPub.bytes));
      logger.i('🔑 توليد وحفظ مفتاح هوية X25519 جديد: $userId');
    }

    SimpleKeyPair signPair;
    SimplePublicKey signPub;
    if (signPrivB64 != null && signPubB64 != null) {
      signPair = SimpleKeyPairData(
        base64Decode(signPrivB64),
        publicKey: SimplePublicKey(base64Decode(signPubB64),
            type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
      signPub = await signPair.extractPublicKey();
      logger.d('✍️ تم تحميل مفتاح التوقيع الحالي: $userId');
    } else {
      signPair = await ed25519.newKeyPair();
      signPub = await signPair.extractPublicKey();
      final signPrivBytes = await signPair.extractPrivateKeyBytes();
      await _secure.write(
          key: _signPrivKey(userId), value: base64Encode(signPrivBytes));
      await _secure.write(
          key: _signPubKey(userId), value: base64Encode(signPub.bytes));
      logger.i('✍️ توليد وحفظ مفتاح توقيع Ed25519 جديد: $userId');
    }

    await _db.collection('keys').doc(userId).set({
      'identityPublic': base64Encode(identPub.bytes),
      'signPublic': base64Encode(signPub.bytes),
      'fingerprintV2': await _pubFingerprint(identPub.bytes, bytes: 16),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    logger.i('📣 نشر مفاتيح الهوية والتوقيع للمستخدم: $userId');
  }

  Future<SimpleKeyPair> getIdentityKeyPair(String userId) async {
    final privB64 = await _secure.read(key: _identPrivKey(userId));
    final pubB64 = await _secure.read(key: _identPubKey(userId));
    if (privB64 == null || pubB64 == null) {
      throw StateError('Identity keys not initialized for $userId');
    }
    return SimpleKeyPairData(
      base64Decode(privB64),
      publicKey:
          SimplePublicKey(base64Decode(pubB64), type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
  }

  Future<SimplePublicKey> fetchPeerIdentityPublicKey(String peerId) async {
    final doc = await _db.collection('keys').doc(peerId).get();
    if (!doc.exists) throw Exception('No identity key found for $peerId');
    final data = doc.data()!;
    final pub = base64Decode(data['identityPublic'] as String);
    return SimplePublicKey(pub, type: KeyPairType.x25519);
  }

  Future<void> publishSignedPreKey(String userId) async {
    await ensureIdentityAndSignatureKeys(userId);

    final spkPair = await x25519.newKeyPair();
    final spkPub = await spkPair.extractPublicKey();
    final spkPrivBytes = await spkPair.extractPrivateKeyBytes();

    await _secure.write(
        key: _signedPrekeyPriv(userId), value: base64Encode(spkPrivBytes));
    await _secure.write(
        key: _signedPrekeyPub(userId), value: base64Encode(spkPub.bytes));

    final signPrivB64 = await _secure.read(key: _signPrivKey(userId));
    final signPubB64 = await _secure.read(key: _signPubKey(userId));
    final signPub =
        SimplePublicKey(base64Decode(signPubB64!), type: KeyPairType.ed25519);
    final signPriv = SimpleKeyPairData(
      base64Decode(signPrivB64!),
      publicKey: signPub,
      type: KeyPairType.ed25519,
    );
    final signature = await ed25519.sign(spkPub.bytes, keyPair: signPriv);

    await _db.collection('keys').doc(userId).set({
      'signedPrekey': {
        'pub': base64Encode(spkPub.bytes),
        'sig': base64Encode(signature.bytes),
        'alg': 'X25519/Ed25519',
        'createdAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    logger.i('🔏 نشر Signed PreKey للمستخدم: $userId');
  }

  Future<void> publishOneTimePreKeys(String userId, {int count = 20}) async {
    await ensureIdentityAndSignatureKeys(userId);

    final batch = _db.batch();
    final otps = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      final kp = await x25519.newKeyPair();
      final pub = await kp.extractPublicKey();
      final privBytes = await kp.extractPrivateKeyBytes();

      await _secure.write(
          key: '${_oneTimePrefix(userId)}$i', value: base64Encode(privBytes));

      otps.add({
        'index': i,
        'pub': base64Encode(pub.bytes),
        'used': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final docRef = _db.collection('keys').doc(userId);
    batch.update(docRef, {'oneTimePrekeys': FieldValue.arrayUnion(otps)});
    await batch.commit();
    logger.i('🗝️ نشر ${otps.length} One-Time PreKeys للمستخدم: $userId');
  }

  Future<void> _checkRateLimit(String userId) async {
    final now = DateTime.now();
    _prekeyRequests.putIfAbsent(userId, () => []);
    _prekeyRequests[userId]!
        .removeWhere((t) => now.difference(t).inSeconds > 60);

    if (_prekeyRequests[userId]!.length >= _maxRequestsPerMinute) {
      logger.w('⚠️ Rate limit exceeded for user $userId');
      throw Exception('Rate limit exceeded. Too many prekey requests.');
    }
    _prekeyRequests[userId]!.add(now);
  }

  Future<
      ({
        SimplePublicKey identityPub,
        SimplePublicKey signedPrekeyPub,
        List<int> signedPrekeySig,
        Map<String, dynamic>? oneTimePrekey
      })> fetchPeerPrekeys(String peerId) async {
    await _checkRateLimit(peerId);

    final doc = await _db.collection('keys').doc(peerId).get();
    if (!doc.exists) throw Exception('No keys doc for peer $peerId');

    final data = doc.data()!;
    final identityPub = SimplePublicKey(
        base64Decode(data['identityPublic'] as String),
        type: KeyPairType.x25519);
    final spk = data['signedPrekey'] as Map<String, dynamic>;

    final createdAt = spk['createdAt'] as Timestamp?;
    if (createdAt != null &&
        DateTime.now().difference(createdAt.toDate()).inDays > 30) {
      logger.w('⚠️ Signed prekey expired for user $peerId');
      throw Exception('Signed prekey expired. Please request new prekeys.');
    }

    final spkPub = SimplePublicKey(base64Decode(spk['pub'] as String),
        type: KeyPairType.x25519);
    final spkSig = base64Decode(spk['sig'] as String);

    final signPubB64 = data['signPublic'] as String;
    final signPub =
        SimplePublicKey(base64Decode(signPubB64), type: KeyPairType.ed25519);

    // ✅ التصحيح: verify تأخذ معاملين (message, signature)
    final signature = Signature(spkSig, publicKey: signPub);
    final isValid = await ed25519.verify(spkPub.bytes, signature: signature);
    if (!isValid) {
      throw Exception('Signed prekey signature invalid for $peerId');
    }

    final otps =
        (data['oneTimePrekeys'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final otp = otps.firstWhere((e) => (e['used'] == false), orElse: () => {});
    return (
      identityPub: identityPub,
      signedPrekeyPub: spkPub,
      signedPrekeySig: spkSig,
      oneTimePrekey: otp.isEmpty ? null : otp
    );
  }

  Future<void> markPeerOneTimePrekeyUsed(String peerId, int index) async {
    final docRef = _db.collection('keys').doc(peerId);

    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = doc.data()!;
      final otps =
          List<Map<String, dynamic>>.from(data['oneTimePrekeys'] ?? []);

      bool found = false;
      for (int i = 0; i < otps.length; i++) {
        if (otps[i]['index'] == index && otps[i]['used'] == false) {
          otps[i]['used'] = true;
          otps[i]['usedAt'] = FieldValue.serverTimestamp();
          otps[i]['usedBy'] = peerId;
          found = true;
          break;
        }
      }

      if (found) {
        transaction.update(docRef, {'oneTimePrekeys': otps});
        logger.d('✅ تم استهلاك one-time prekey $index للمستخدم $peerId');
      } else {
        logger.w(
            '⚠️ One-time prekey $index already used or not found for $peerId');
      }
    });
  }

  Future<SimpleKeyPair> generateEphemeralKey() async {
    return await x25519.newKeyPair();
  }

  Future<String> _generateNonce() async {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Encode(bytes);
  }

  Future<void> _checkReplay(String userId, String nonce) async {
    _usedNonces.putIfAbsent(userId, () => {});
    if (_usedNonces[userId]!.contains(nonce)) {
      logger.w('⚠️ Replay attack detected for user $userId');
      throw Exception('Replay attack detected');
    }
    _usedNonces[userId]!.add(nonce);

    if (_usedNonces[userId]!.length > 1000) {
      _usedNonces[userId]!.clear();
    }
  }

  static const String _confirmationInfo = 'privoo:confirmation';

  Future<String> _generateConfirmationMac(
      List<int> masterSecret, String context) async {
    final key = await hkdf32.deriveKey(
      secretKey: SecretKey(masterSecret),
      info: utf8.encode(_confirmationInfo),
    );
    final keyBytes = await key.extractBytes();
    final h = Hmac.sha256();
    final mac = await h.calculateMac(utf8.encode(context),
        secretKey: SecretKey(keyBytes));
    return base64Encode(mac.bytes);
  }

  Future<bool> verifySessionConfirmation(
      String chatId, String expectedMac) async {
    final doc = await _db.collection('chats').doc(chatId).get();
    final storedMac = doc.data()?['confirmationMac'];

    if (storedMac == null) {
      logger.w('⚠️ No confirmation MAC found for chat $chatId');
      return false;
    }

    final isValid = storedMac == expectedMac;
    if (isValid) {
      logger.i('✅ Key confirmation successful for chat $chatId');
      await _db.collection('chats').doc(chatId).update({'confirmed': true});
    } else {
      logger.w('⚠️ Key confirmation FAILED for chat $chatId');
    }

    return isValid;
  }

  Future<
      ({
        List<int> chatMasterKey,
        List<int> msgKey,
        List<int> callKey,
        List<int> backupKey,
        String confirmationMac,
      })> establishSessionWithEphemeral({
    required String chatId,
    required String myUserId,
    required String peerUserId,
    SimpleKeyPair? ephemeralKey,
  }) async {
    final nonce = await _generateNonce();
    await _db.collection('keys').doc(myUserId).set({
      'sessionNonce': nonce,
      'sessionNonceCreatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _checkReplay(myUserId, nonce);

    final myEphemeral = ephemeralKey ?? await generateEphemeralKey();
    final myEphemeralPub = await myEphemeral.extractPublicKey();

    await _db.collection('keys').doc(myUserId).set({
      'ephemeralPub': base64Encode(myEphemeralPub.bytes),
      'ephemeralCreatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final myIdent = await getIdentityKeyPair(myUserId);
    final mySpkPrivB64 = await _secure.read(key: _signedPrekeyPriv(myUserId));
    SimpleKeyPair? mySpk;
    if (mySpkPrivB64 != null) {
      final mySpkPubB64 = await _secure.read(key: _signedPrekeyPub(myUserId));
      final mySpkPub =
          SimplePublicKey(base64Decode(mySpkPubB64!), type: KeyPairType.x25519);
      mySpk = SimpleKeyPairData(
        base64Decode(mySpkPrivB64),
        publicKey: mySpkPub,
        type: KeyPairType.x25519,
      );
    } else {
      await publishSignedPreKey(myUserId);
      final reload = await _secure.read(key: _signedPrekeyPriv(myUserId));
      final reloadPubB64 = await _secure.read(key: _signedPrekeyPub(myUserId));
      final reloadPub = SimplePublicKey(base64Decode(reloadPubB64!),
          type: KeyPairType.x25519);
      mySpk = SimpleKeyPairData(
        base64Decode(reload!),
        publicKey: reloadPub,
        type: KeyPairType.x25519,
      );
    }

    final peer = await fetchPeerPrekeys(peerUserId);
    final peerIdent = peer.identityPub;
    final peerSpk = peer.signedPrekeyPub;

    final dh1 = await x25519.sharedSecretKey(
        keyPair: myIdent, remotePublicKey: peerSpk);
    final dh2 = await x25519.sharedSecretKey(
        keyPair: myEphemeral, remotePublicKey: peerIdent);
    final dh3 = await x25519.sharedSecretKey(
        keyPair: myEphemeral, remotePublicKey: peerSpk);

    final secrets = <List<int>>[
      await dh1.extractBytes(),
      await dh2.extractBytes(),
      await dh3.extractBytes(),
    ];

    if (peer.oneTimePrekey != null) {
      final otpPub = SimplePublicKey(
        base64Decode(peer.oneTimePrekey!['pub'] as String),
        type: KeyPairType.x25519,
      );
      final dh4 = await x25519.sharedSecretKey(
          keyPair: myIdent, remotePublicKey: otpPub);
      secrets.add(await dh4.extractBytes());
      await markPeerOneTimePrekeyUsed(
          peerUserId, peer.oneTimePrekey!['index'] as int);
    }

    final masterSecret = secrets.expand((e) => e).toList();

    final random = Random.secure();
    final salt = List<int>.generate(32, (_) => random.nextInt(256));

    final masterKey = await hkdf32.deriveKey(
      secretKey: SecretKey(masterSecret),
      nonce: salt,
      info: utf8.encode('privoo:x3dh:$chatId:ephemeral'),
    );
    final chatMasterKey = await masterKey.extractBytes();

    final msgKey = await _deriveSubKey(chatMasterKey, 'privoo:msg:$chatId');
    final callKey = await _deriveSubKey(chatMasterKey, 'privoo:call:$chatId');
    final backupKey =
        await _deriveSubKey(chatMasterKey, 'privoo:backup:$chatId');

    final confirmationContext = '$chatId:$myUserId:$peerUserId';
    final confirmationMac =
        await _generateConfirmationMac(masterSecret, confirmationContext);

    await _db.collection('chats').doc(chatId).set({
      'participants': [myUserId, peerUserId]..sort(),
      'x3dhSalt': base64Encode(salt),
      'ephemeralPub': base64Encode(myEphemeralPub.bytes),
      'confirmationMac': confirmationMac,
      'confirmed': false,
      'createdBy': myUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'protocolVersion': 3,
    }, SetOptions(merge: true));

    logger.i('✅ Session established with key confirmation for chat $chatId');
    return (
      chatMasterKey: chatMasterKey,
      msgKey: msgKey,
      callKey: callKey,
      backupKey: backupKey,
      confirmationMac: confirmationMac
    );
  }

  Future<
      ({
        List<int> chatMasterKey,
        List<int> msgKey,
        List<int> callKey,
        List<int> backupKey,
        String confirmationMac,
      })> establishSession({
    required String chatId,
    required String myUserId,
    required String peerUserId,
    bool useOneTimePeer = true,
  }) async {
    return await establishSessionWithEphemeral(
      chatId: chatId,
      myUserId: myUserId,
      peerUserId: peerUserId,
    );
  }

  // ============================================================
  // 🔬 المقاومة الكمومية (Quantum Resistance)
  // ============================================================

  Future<
      ({
        List<int> chatMasterKey,
        List<int> msgKey,
        List<int> callKey,
        List<int> backupKey,
        String confirmationMac,
        String quantumFingerprint,
        bool isQuantumReady,
      })> establishQuantumSession({
    required String chatId,
    required String myUserId,
    required String peerUserId,
    required bool useQuantum,
  }) async {
    final classicSession = await establishSession(
      chatId: chatId,
      myUserId: myUserId,
      peerUserId: peerUserId,
    );

    if (!useQuantum) {
      return (
        chatMasterKey: classicSession.chatMasterKey,
        msgKey: classicSession.msgKey,
        callKey: classicSession.callKey,
        backupKey: classicSession.backupKey,
        confirmationMac: classicSession.confirmationMac,
        quantumFingerprint: '',
        isQuantumReady: false,
      );
    }

    try {
      final peerQuantumPub =
          await QuantumResistantService.getPeerKyberPublicKey(peerUserId);

      final result = await QuantumResistantService.encapsulate(peerQuantumPub);
      final ciphertext = result.ciphertext;
      final quantumSecret = result.sharedSecret;

      await QuantumResistantService.storeQuantumCiphertext(
          chatId, myUserId, ciphertext);

      final hybridKey = await QuantumResistantService.hybridKeyExchange(
        classicSharedSecret: classicSession.chatMasterKey,
        quantumSharedSecret: quantumSecret,
      );

      final msgKey = await _deriveSubKey(hybridKey, 'privoo:msg:$chatId');
      final callKey = await _deriveSubKey(hybridKey, 'privoo:call:$chatId');
      final backupKey = await _deriveSubKey(hybridKey, 'privoo:backup:$chatId');

      final doc = await _db.collection('quantum_keys').doc(peerUserId).get();
      final quantumFingerprint =
          doc.data()?['kyberFingerprint'] as String? ?? '';

      await _db.collection('chats').doc(chatId).update({
        'isQuantumReady': true,
        'quantumFingerprint': quantumFingerprint,
        'quantumVersion': 'ML-KEM-768',
      });

      logger.i('🔐 تم إنشاء جلسة كمومية هجينة للمحادثة $chatId');

      return (
        chatMasterKey: hybridKey,
        msgKey: msgKey,
        callKey: callKey,
        backupKey: backupKey,
        confirmationMac: classicSession.confirmationMac,
        quantumFingerprint: quantumFingerprint,
        isQuantumReady: true,
      );
    } catch (e) {
      logger.w('⚠️ فشل إنشاء الجلسة الكمومية: $e، العودة للجلسة الكلاسيكية');
      return (
        chatMasterKey: classicSession.chatMasterKey,
        msgKey: classicSession.msgKey,
        callKey: classicSession.callKey,
        backupKey: classicSession.backupKey,
        confirmationMac: classicSession.confirmationMac,
        quantumFingerprint: '',
        isQuantumReady: false,
      );
    }
  }

  static Future<List<int>> _deriveSubKey(List<int> master, String info) async {
    final secretKey = SecretKey(master);
    final derived = await hkdf32.deriveKey(
      secretKey: secretKey,
      nonce: List<int>.filled(16, 0),
      info: utf8.encode(info),
    );
    return await derived.extractBytes();
  }

  Future<void> deleteLocalIdentity(String userId) async {
    await _secure.delete(key: _identPrivKey(userId));
    await _secure.delete(key: _identPubKey(userId));
    await _secure.delete(key: _signPrivKey(userId));
    await _secure.delete(key: _signPubKey(userId));
    await _secure.delete(key: _signedPrekeyPriv(userId));
    await _secure.delete(key: _signedPrekeyPub(userId));
    for (int i = 0; i < 200; i++) {
      await _secure.delete(key: '${_oneTimePrefix(userId)}$i');
    }
    _prekeyRequests.remove(userId);
    _usedNonces.remove(userId);
    _confirmationMacs.remove(userId);
    logger.w('🗑️ حذف هوية ومفاتيح التوقيع وprekeys المحلية للمستخدم: $userId');
  }

  static Future<String> _pubFingerprint(List<int> pub, {int bytes = 16}) async {
    final digest = await Sha256().hash(pub);
    final fp = digest.bytes.sublist(0, bytes);
    return fp
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  static Future<String> pubFingerprint(List<int> pub, {int bytes = 16}) async {
    return await _pubFingerprint(pub, bytes: bytes);
  }

  static void clearCaches() {
    _prekeyRequests.clear();
    _usedNonces.clear();
    _confirmationMacs.clear();
    Logger().i('🧹 تم تنظيف Rate limiting و Nonce و Confirmation caches');
  }
}
