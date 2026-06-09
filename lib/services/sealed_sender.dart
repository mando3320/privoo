// lib/services/sealed_sender.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

class SealedSenderService {
  static const String _workerUrl = 'https://privoo-sealed-sender.saberb45.workers.dev/';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ✅ المهمة 9: تشفير AES-GCM بدلاً من XOR
  Future<String> _encryptAESGCM(String plaintext, String key) async {
    final keyBytes = utf8.encode(key);
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(keyBytes);
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    
    final combined = [...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes];
    return base64Encode(combined);
  }
  
  Future<String> _decryptAESGCM(String encryptedBase64, String key) async {
    final combined = base64Decode(encryptedBase64);
    final nonce = combined.sublist(0, 12);
    final cipherText = combined.sublist(12, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));
    
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(utf8.encode(key));
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    
    final decrypted = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decrypted);
  }
  
  /// إرسال رسالة مخفية (الخادم لا يرى senderId)
  Future<void> sendSealedMessage({
    required String chatId,
    required String message,
    required String recipientId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    // ✅ استخدام AES-GCM بدلاً من XOR
    final encryptedContent = await _encryptAESGCM(message, recipientId);
    
    // حساب hash للتوقيع
    final messageHash = await _hashMessage(encryptedContent);
    
    // طلب توقيع من Cloudflare Worker
    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messageHash': messageHash,
        'recipientId': recipientId,
        'userId': userId,
      }),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to get blind signature: ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    
    // تخزين في Firestore (بدون senderId!)
    await _firestore.collection('sealed_messages').doc(chatId).set({
      'encryptedContent': encryptedContent,
      'recipientId': recipientId,
      'blindSignature': data['blindSignature'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'chatId': chatId,
    });
    
    print('✅ Sealed message sent to $recipientId');
  }
  
  /// استلام الرسائل المخفية للمستخدم
  Stream<Map<String, dynamic>> receiveSealedMessages(String recipientId) {
    return _firestore
        .collection('sealed_messages')
        .where('recipientId', isEqualTo: recipientId)
        .snapshots()
        .asyncMap((snapshot) async {
          final messages = <String, dynamic>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final decrypted = await _decryptAESGCM(data['encryptedContent'], recipientId);
            messages[doc.id] = {
              'content': decrypted,
              'timestamp': data['timestamp'],
              'chatId': data['chatId'],
            };
          }
          return messages;
        });
  }
  
  /// حذف رسالة مخفية
  Future<void> deleteSealedMessage(String messageId) async {
    await _firestore.collection('sealed_messages').doc(messageId).delete();
  }
  
  Future<String> _hashMessage(String message) async {
    final bytes = utf8.encode(message);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }
}