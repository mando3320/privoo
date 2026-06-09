// core/helpers.dart
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import '../services/key_exchange_service.dart';
import '../services/ratchet_service.dart';

class Helpers {
  Helpers._();

  // ---------- General ----------
  static List<int> generateNonce({int length = 16}) {
    final rand = Random.secure();
    return List<int>.generate(length, (_) => rand.nextInt(256));
  }

  static String bytesToBase64(List<int> bytes) => base64Encode(bytes);
  static List<int> base64ToBytes(String b64) => base64Decode(b64);
  static int currentTimestamp() => DateTime.now().millisecondsSinceEpoch;

  static bool isFresh(int msgTimestamp, {int maxDriftMs = 30000}) {
    final now = currentTimestamp();
    return (now - msgTimestamp).abs() <= maxDriftMs;
  }

  static List<int> buildAad({
    required String contextId,
    required String senderId,
    required String receiverId,
    required String kind,
    required int version,
    required int timestamp,
    int? msgN,
    List<int>? dhPub,
    String transport = 'default',
    String extra = '',
  }) {
    final str = StringBuffer()
      ..write('context:$contextId;sender:$senderId;recv:$receiverId;')
      ..write('kind:$kind;v:$version;ts:$timestamp;');
    if (msgN != null) str.write('msgN:$msgN;');
    if (dhPub != null) str.write('dh:${bytesToBase64(dhPub)};');
    if (transport.isNotEmpty) str.write('transport:$transport;');
    if (extra.isNotEmpty) str.write(extra);
    return utf8.encode(str.toString());
  }

  // ---------- Ratchet / KeyExchange ----------
  static Future<List<int>> deriveSessionKey({
    required String chatId,
    required String myUserId,
    required String peerUserId,
    SimpleKeyPair? myEphemeral,
  }) async {
    // ✅ استخدم الدالة الصحيحة من KeyExchangeService
    final keyService = KeyExchangeService();
    final session = await keyService.establishSession(
      chatId: chatId,
      myUserId: myUserId,
      peerUserId: peerUserId,
    );
    return session.chatMasterKey;
  }

  static Future<({List<int> mk, int n, List<int> myDhPub})> nextMessageKey({
    required String chatId,
    required String myUserId,
  }) async {
    // ✅ النوع الصحيح من RatchetService
    return await RatchetService.nextSendingKey(
      chatId: chatId,
      myUserId: myUserId,
    );
  }

  static Future<List<int>> keyForReceived({
    required String chatId,
    required String myUserId,
    required int ratchetN,
    List<int>? senderDhPub,
  }) async {
    return await RatchetService.keyForReceived(
      chatId: chatId,
      myUserId: myUserId,
      ratchetN: ratchetN,
      senderDhPub: senderDhPub,
    );
  }
}