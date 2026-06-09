// services/ratchet_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';


class RatchetNotInitializedException implements Exception {
  final String message;
  RatchetNotInitializedException([this.message = 'Ratchet not initialized']);
  @override
  String toString() => 'RatchetNotInitializedException: $message';
}

class _State {
  List<int> sendCK;
  List<int> recvCK;
  int nSend;
  int nRecv;
  List<int> myDhPriv;
  List<int> myDhPub;
  List<int> peerDhPub;
  Map<int, String> recvBufferB64;
  int version;
  DateTime? myDhCreatedAt;
  DateTime? peerDhCreatedAt;

  _State(
    this.sendCK,
    this.recvCK,
    this.nSend,
    this.nRecv, {
    required this.myDhPriv,
    required this.myDhPub,
    required this.peerDhPub,
    Map<int, String>? recvBuffer,
    this.version = 1,
    this.myDhCreatedAt,
    this.peerDhCreatedAt,
  }) : recvBufferB64 = recvBuffer ?? {};

  Map<String, dynamic> toJson() => {
        'version': version,
        'sendCK': base64Encode(sendCK),
        'recvCK': base64Encode(recvCK),
        'nSend': nSend,
        'nRecv': nRecv,
        'myDhPriv': base64Encode(myDhPriv),
        'myDhPub': base64Encode(myDhPub),
        'peerDhPub': base64Encode(peerDhPub),
        'recvBuf': recvBufferB64.map((k, v) => MapEntry(k.toString(), v)),
        if (myDhCreatedAt != null) 'myDhCreatedAt': myDhCreatedAt!.toIso8601String(),
        if (peerDhCreatedAt != null) 'peerDhCreatedAt': peerDhCreatedAt!.toIso8601String(),
      };

  static _State fromJson(Map<String, dynamic> j) => _State(
        base64Decode(j['sendCK'] as String),
        base64Decode(j['recvCK'] as String),
        j['nSend'] as int,
        j['nRecv'] as int,
        myDhPriv: base64Decode(j['myDhPriv'] as String),
        myDhPub: base64Decode(j['myDhPub'] as String),
        peerDhPub: base64Decode(j['peerDhPub'] as String),
        recvBuffer: (j['recvBuf'] as Map?)?.map<int, String>(
              (k, v) => MapEntry(int.parse(k as String), v as String),
            ) ??
            {},
        version: (j['version'] as int?) ?? 1,
        myDhCreatedAt: j['myDhCreatedAt'] != null ? DateTime.parse(j['myDhCreatedAt']) : null,
        peerDhCreatedAt: j['peerDhCreatedAt'] != null ? DateTime.parse(j['peerDhCreatedAt']) : null,
      );
}

class RatchetService {
  static const _storage = FlutterSecureStorage();
  static const _ns = 'privoo.ratchet';
  static const _deviceSecretKey = 'privoo.device.secret.v1';
  static const _deviceSecretRotationKey = 'privoo.device.secret.rotation';
  static const _hkdfInfoRoot = 'privoo:hkdf:root';
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static const _kdfInfoSend = 'ck/send';
  static const _kdfInfoRecv = 'ck/recv';
  static const _mkInfo = 'mk';
  static const _rootInfo = 'root';

  static final Map<String, Lock> _locks = {};
  static final Map<String, Set<int>> _usedMessageKeys = {};
  static const int _maxUsedKeysPerChat = 1000;
  static const int _maxRecvBufferSize = 50;
  static const int _maxStepsToReach = 1000;
  static const int DH_KEY_ROTATION_DAYS = 7;

  static Lock _lockFor(String key) => _locks.putIfAbsent(key, () => Lock());
  static String _keyFor(String chatId, String userId) => '$_ns:$userId:$chatId';

  final _logger = Logger();

  static Future<List<int>> _getOrCreateDeviceSecret() async {
    final stored = await _storage.read(key: _deviceSecretKey);
    final lastRotationStr = await _storage.read(key: _deviceSecretRotationKey);
    
    DateTime? lastRotation;
    if (lastRotationStr != null) {
      lastRotation = DateTime.tryParse(lastRotationStr);
    }
    
    final shouldRotate = lastRotation == null || 
        DateTime.now().difference(lastRotation).inDays >= 30;
    
    if (shouldRotate) {
      final rnd = Random.secure();
      final newSecret = List<int>.generate(32, (_) => rnd.nextInt(256));
      await _storage.write(key: _deviceSecretKey, value: base64Encode(newSecret));
      await _storage.write(key: _deviceSecretRotationKey, value: DateTime.now().toIso8601String());
      Logger().i('🔄 تم تدوير device secret');
      return newSecret;
    }
    
    if (stored != null) {
      return base64Decode(stored);
    }
    
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _storage.write(key: _deviceSecretKey, value: base64Encode(bytes));
    await _storage.write(key: _deviceSecretRotationKey, value: DateTime.now().toIso8601String());
    return bytes;
  }

  static Future<List<int>> _computeStateMac(String payloadJson) async {
    final deviceSecret = await _getOrCreateDeviceSecret();
    final h = crypto.Hmac(crypto.sha256, deviceSecret);
    return h.convert(utf8.encode(payloadJson)).bytes;
  }

  static bool _isValidDhPub(List<int> pub) => pub.length == 32;

  static Future<List<int>> _hkdfExpand({
    required List<int> seed,
    required String info,
    List<int>? salt,
  }) async {
    final key = SecretKey(seed);
    final derived = await _hkdf.deriveKey(
      secretKey: key,
      info: utf8.encode(info),
    );
    return await derived.extractBytes();
  }

  static Future<void> _save(String chatId, String myUserId, _State st) async {
    final key = _keyFor(chatId, myUserId);
    final jsonStr = jsonEncode(st.toJson());
    final mac = await _computeStateMac(jsonStr);
    final wrapper = jsonEncode({'v': st.version, 'state': jsonStr, 'mac': base64Encode(mac)});
    await _storage.write(key: key, value: wrapper);
  }

  static Future<_State?> _load(String chatId, String myUserId) async {
    final key = _keyFor(chatId, myUserId);
    final v = await _storage.read(key: key);
    if (v == null) return null;
    try {
      final wrapper = jsonDecode(v) as Map<String, dynamic>;
      final jsonStr = wrapper['state'] as String;
      final macB64 = wrapper['mac'] as String;
      final expected = await _computeStateMac(jsonStr);
      if (!const ListEquality().equals(expected, base64Decode(macB64))) {
        Logger().e('❌ فشل تحقق سلامة Ratchet State');
        return null;
      }
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _State.fromJson(jsonMap);
    } catch (e) {
      Logger().e('❌ فشل تحميل Ratchet State: $e');
      return null;
    }
  }

  static Future<void> initRatchet({
    required String chatId,
    required String myUserId,
    required String peerUserId,
    required List<int> sessionKey32,
    List<int>? initialPeerDhPub,
  }) async {
    final keyName = _keyFor(chatId, myUserId);
    final exists = await _storage.read(key: keyName);
    if (exists != null) {
      Logger().d('🔒 Ratchet State موجود مسبقًا');
      return;
    }

    final meFirst = myUserId.compareTo(peerUserId) < 0;

    final ckA = await _hkdfExpand(seed: sessionKey32, info: _kdfInfoSend, salt: utf8.encode(_hkdfInfoRoot));
    final ckB = await _hkdfExpand(seed: sessionKey32, info: _kdfInfoRecv, salt: utf8.encode(_hkdfInfoRoot));

    final sendCK = meFirst ? ckA : ckB;
    final recvCK = meFirst ? ckB : ckA;

    final myDhPair = await _x25519.newKeyPair();
    final myPub = await myDhPair.extractPublicKey();
    final myPrivBytes = await myDhPair.extractPrivateKeyBytes();

    final peerPubBytes = (initialPeerDhPub != null && _isValidDhPub(initialPeerDhPub))
        ? initialPeerDhPub
        : List<int>.empty(growable: true);

    final st = _State(
      sendCK,
      recvCK,
      0,
      0,
      myDhPriv: myPrivBytes,
      myDhPub: myPub.bytes,
      peerDhPub: peerPubBytes,
      myDhCreatedAt: DateTime.now(),
    );

    await _save(chatId, myUserId, st);
    Logger().i('✅ تم تهيئة Ratchet State للمحادثة $chatId');
  }

  static Future<bool> _isDhKeyValid(_State st, bool isMyKey) async {
    final createdAt = isMyKey ? st.myDhCreatedAt : st.peerDhCreatedAt;
    if (createdAt == null) return true;
    final daysOld = DateTime.now().difference(createdAt).inDays;
    return daysOld < DH_KEY_ROTATION_DAYS;
  }

  static Future<void> _rotateMyDhKey({
    required String chatId,
    required String myUserId,
    required _State st,
  }) async {
    if (st.myDhCreatedAt != null) {
      final daysOld = DateTime.now().difference(st.myDhCreatedAt!).inDays;
      if (daysOld < DH_KEY_ROTATION_DAYS) return;
    }
    
    Logger().i('🔄 تدوير مفتاح DH بعد $DH_KEY_ROTATION_DAYS أيام');
    
    final myNew = await _x25519.newKeyPair();
    final myNewPub = await myNew.extractPublicKey();
    final myNewPrivBytes = await myNew.extractPrivateKeyBytes();
    
    st.myDhPriv = myNewPrivBytes;
    st.myDhPub = myNewPub.bytes;
    st.myDhCreatedAt = DateTime.now();
    
    await _save(chatId, myUserId, st);
  }

  static Future<void> _dhRatchet({
    required String chatId,
    required String myUserId,
    required _State st,
    required List<int> newPeerDhPub,
  }) async {
    if (!_isValidDhPub(newPeerDhPub)) {
      throw ArgumentError('Invalid DH public key length');
    }

    final lock = _lockFor(_keyFor(chatId, myUserId));
    await lock.synchronized(() async {
      st.peerDhPub = newPeerDhPub;
      st.peerDhCreatedAt = DateTime.now();

      final myPair = SimpleKeyPairData(
        st.myDhPriv,
        publicKey: SimplePublicKey(st.myDhPub, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
      final peerPub = SimplePublicKey(newPeerDhPub, type: KeyPairType.x25519);
      final shared = await _x25519.sharedSecretKey(keyPair: myPair, remotePublicKey: peerPub);
      final sharedBytes = await shared.extractBytes();

      final newRoot = await _hkdfExpand(seed: sharedBytes, info: _rootInfo, salt: utf8.encode(_hkdfInfoRoot));

      st.sendCK = await _hkdfExpand(seed: newRoot, info: _kdfInfoSend);
      st.recvCK = await _hkdfExpand(seed: newRoot, info: _kdfInfoRecv);

      st.nSend = 0;
      st.nRecv = 0;
      st.recvBufferB64.clear();

      final myNew = await _x25519.newKeyPair();
      final myNewPub = await myNew.extractPublicKey();
      final myNewPrivBytes = await myNew.extractPrivateKeyBytes();
      st.myDhPriv = myNewPrivBytes;
      st.myDhPub = myNewPub.bytes;
      st.myDhCreatedAt = DateTime.now();

      await _save(chatId, myUserId, st);
      Logger().i('🔄 تم تنفيذ DH ratchet للمحادثة $chatId');
    });
  }

  static Future<({List<int> mk, int n, List<int> myDhPub})> nextSendingKey({
    required String chatId,
    required String myUserId,
  }) async {
    final lock = _lockFor(_keyFor(chatId, myUserId));
    return lock.synchronized(() async {
      final st = await _load(chatId, myUserId);
      if (st == null) {
        throw RatchetNotInitializedException();
      }

      await _rotateMyDhKey(chatId: chatId, myUserId: myUserId, st: st);

      final mk = await _hkdfExpand(seed: st.sendCK, info: _mkInfo);
      st.sendCK = await _hkdfExpand(seed: st.sendCK, info: _kdfInfoSend);

      final n = st.nSend;
      st.nSend += 1;

      await _save(chatId, myUserId, st);
      Logger().d('➡️ تم توليد مفتاح إرسال جديد (n: $n)');

      return (mk: mk, n: n, myDhPub: st.myDhPub);
    });
  }

  static Future<List<int>> keyForReceived({
    required String chatId,
    required String myUserId,
    required int ratchetN,
    List<int>? senderDhPub,
  }) async {
    final lock = _lockFor(_keyFor(chatId, myUserId));
    return lock.synchronized(() async {
      final st = await _load(chatId, myUserId);
      if (st == null) {
        throw RatchetNotInitializedException();
      }

      final usedKeySetKey = '$chatId:$myUserId';
      _usedMessageKeys.putIfAbsent(usedKeySetKey, () => {});
      
      if (_usedMessageKeys[usedKeySetKey]!.contains(ratchetN)) {
        Logger().w('⚠️ محاولة إعادة استخدام مفتاح مستخدم (n=$ratchetN) - هجوم Replay!');
        throw Exception('Replay attack detected');
      }

      if (st.peerDhPub.isNotEmpty) {
        final isPeerKeyValid = await _isDhKeyValid(st, false);
        if (!isPeerKeyValid) {
          Logger().w('⚠️ مفتاح DH للطرف الآخر انتهت صلاحيته (أكثر من $DH_KEY_ROTATION_DAYS يوم)');
          throw Exception('Peer DH key expired, please re-establish session');
        }
      }

      if (senderDhPub != null) {
        if (!_isValidDhPub(senderDhPub)) {
          throw ArgumentError('Invalid sender DH public key length');
        }
        final isNew = base64Encode(senderDhPub) != base64Encode(st.peerDhPub);
        if (isNew) {
          await _dhRatchet(chatId: chatId, myUserId: myUserId, st: st, newPeerDhPub: senderDhPub);
        }
      }

      final cached = st.recvBufferB64[ratchetN];
      if (cached != null) {
        final mk = base64Decode(cached);
        st.recvBufferB64.remove(ratchetN);
        await _save(chatId, myUserId, st);
        
        _usedMessageKeys[usedKeySetKey]!.add(ratchetN);
        if (_usedMessageKeys[usedKeySetKey]!.length > _maxUsedKeysPerChat) {
          _usedMessageKeys[usedKeySetKey]!.clear();
        }
        
        return mk;
      }

      if (ratchetN < st.nRecv) {
        Logger().w('⚠️ رسالة قديمة (n=$ratchetN)');
        throw Exception('Received old message');
      }

      int stepsTaken = 0;
      while (st.nRecv < ratchetN) {
        if (stepsTaken > _maxStepsToReach) {
          Logger().e('❌ تجاوز الحد الأقصى للخطوات - DoS attack detected');
          throw Exception('Too many steps to reach ratchetN, possible DoS');
        }
        
        final mkIntermediate = await _hkdfExpand(seed: st.recvCK, info: _mkInfo);
        st.recvBufferB64[st.nRecv] = base64Encode(mkIntermediate);

        st.recvCK = await _hkdfExpand(seed: st.recvCK, info: _kdfInfoRecv);
        st.nRecv += 1;
        stepsTaken++;
      }

      final mk = await _hkdfExpand(seed: st.recvCK, info: _mkInfo);
      st.recvCK = await _hkdfExpand(seed: st.recvCK, info: _kdfInfoRecv);
      st.nRecv += 1;

      if (st.recvBufferB64.length > _maxRecvBufferSize) {
        final keys = st.recvBufferB64.keys.toList()..sort();
        final removeCount = st.recvBufferB64.length - _maxRecvBufferSize;
        for (final k in keys.take(removeCount)) {
          st.recvBufferB64.remove(k);
        }
      }

      await _save(chatId, myUserId, st);

      _usedMessageKeys[usedKeySetKey]!.add(ratchetN);
      if (_usedMessageKeys[usedKeySetKey]!.length > _maxUsedKeysPerChat) {
        _usedMessageKeys[usedKeySetKey]!.clear();
      }

      Logger().d('⬅️ تم استخلاص مفتاح استقبال (n: $ratchetN) بعد $stepsTaken خطوة');
      return mk;
    });
  }

  static Future<void> reset({required String chatId, required String myUserId}) async {
    await _storage.delete(key: _keyFor(chatId, myUserId));
    final usedKeySetKey = '$chatId:$myUserId';
    _usedMessageKeys.remove(usedKeySetKey);
    Logger().w('🗑️ تم إعادة تعيين Ratchet State للمحادثة $chatId');
  }

  static Future<Map<String, dynamic>?> exportState({
    required String chatId,
    required String myUserId,
  }) async {
    final st = await _load(chatId, myUserId);
    return st?.toJson();
  }

  static Future<bool> importState({
    required String chatId,
    required String myUserId,
    required Map<String, dynamic> jsonState,
  }) async {
    try {
      final st = _State.fromJson(jsonState);
      if (!_isValidDhPub(st.myDhPub) || (st.peerDhPub.isNotEmpty && !_isValidDhPub(st.peerDhPub))) {
        Logger().e('فشل استيراد الحالة: مفاتيح DH غير صالحة');
        return false;
      }
      await _save(chatId, myUserId, st);
      Logger().i('✅ تم استيراد Ratchet State للمحادثة $chatId');
      return true;
    } catch (e) {
      Logger().e('❌ فشل استيراد Ratchet State: $e');
      return false;
    }
  }

  static void clearReplayProtection() {
    _usedMessageKeys.clear();
    Logger().i('🧹 تم تنظيف ذاكرة Replay Protection');
  }
}