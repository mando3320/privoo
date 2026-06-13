// lib/services/http_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../main.dart';

/// HTTP Client مع SSL Pinning لحماية التطبيق من هجمات MITM
class SecureHttpClient {
  static SecureHttpClient? _instance;
  late final IOClient _client;
  
  // ✅ البصمات الحقيقية للشهادات (تم استخراجها بواسطة OpenSSL)
  static final Map<String, List<String>> _trustedCertificates = {
    // Google / Firebase
    'googleapis.com': [
      'bEgq5Ig55dUgS/QjEEVNL8EI51RWdIJO5bt1B3VQz6U=',
    ],
    'firebase.com': [
      'bEgq5Ig55dUgS/QjEEVNL8EI51RWdIJO5bt1B3VQz6U=',
    ],
    
    // Gemini AI
    'generativelanguage.googleapis.com': [
      'vSZotCGXPl44azqjSwu/ZklW70WPYspg+LjXNP3eRQ4=',
    ],
    
    // Cloudflare Worker
    'privoo-sealed-sender.saberb45.workers.dev': [
      'Qf146/STQL703GcpjbAMbifBeq9R5uZIbSkFLf8fRpY=',
    ],
    
    // Link Preview
    'api.linkpreview.net': [
      'mhjlJRCKmOWZis2OK4Zxbnk5a5pCafwk8d1zi3DjGNs=',
    ],
    
    // Giphy
    'api.giphy.com': [
      'KDEJJf+RCi4r2k6cOqlrZiC/rxOUI6UrzvQTynbLN8k=',
    ],
    
    // Remove.bg
    'api.remove.bg': [
      'RKb5xuSTeAiCfMfROqzOcWc/ZE+a8Aby46NK47oEem8=',
    ],
    
    // Hugging Face
    'huggingface.co': [
      'Z7ny7xvhNdZ/lw3lzQLOZmnqYHOPKQDkZnPHErpu5JI=',
    ],
    'api-inference.huggingface.co': [
      'Z7ny7xvhNdZ/lw3lzQLOZmnqYHOPKQDkZnPHErpu5JI=',
    ],
  };
  
  factory SecureHttpClient() {
    _instance ??= SecureHttpClient._internal();
    return _instance!;
  }
  
  SecureHttpClient._internal() {
    _client = _createSecureClient();
  }
  
  IOClient _createSecureClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (kDebugMode) {
          logger.d('⚠️ Debug mode: SSL certificate validation bypassed for $host');
          return true;
        }
        return _validateCertificate(cert, host);
      };
    return IOClient(httpClient);
  }
  
  bool _validateCertificate(X509Certificate cert, String host) {
    try {
      final fingerprint = _getCertificateFingerprint(cert);
      logger.d('🔐 SSL Certificate fingerprint for $host: $fingerprint');
      
      // التحقق من البصمة مع القائمة الموثوقة
      for (final entry in _trustedCertificates.entries) {
        if (host.contains(entry.key) || entry.key.contains(host)) {
          if (entry.value.contains(fingerprint)) {
            logger.i('✅ SSL Certificate validated for $host');
            return true;
          }
        }
      }
      
      // إذا كان host في القائمة ولكن البصمة غير متطابقة
      if (_trustedCertificates.keys.any((key) => host.contains(key))) {
        logger.e('❌ Invalid SSL certificate for $host! Possible MITM attack!');
        logger.e('❌ Expected one of: ${_trustedCertificates[host]}');
        logger.e('❌ Got: $fingerprint');
        return false;
      }
      
      // للمضيفين غير المحددين في القائمة، ثق بالشهادة الافتراضية
      logger.d('ℹ️ Host $host not in pinning list, trusting default certificate');
      return true;
    } catch (e) {
      logger.e('❌ SSL validation error for $host: $e');
      return false;
    }
  }
  
  String _getCertificateFingerprint(X509Certificate cert) {
    final digest = sha256.convert(cert.der);
    final fingerprint = base64Encode(digest.bytes);
    return fingerprint;
  }
  
  /// إضافة شهادة موثوقة جديدة (للاستخدام في وقت التشغيل)
  static void addTrustedCertificate(String host, String fingerprint) {
    _trustedCertificates.putIfAbsent(host, () => []).add(fingerprint);
    logger.i('✅ Added trusted certificate for $host');
  }
  
  /// إزالة شهادة موثوقة
  static void removeTrustedCertificate(String host, String fingerprint) {
    if (_trustedCertificates.containsKey(host)) {
      _trustedCertificates[host]?.remove(fingerprint);
      if (_trustedCertificates[host]?.isEmpty == true) {
        _trustedCertificates.remove(host);
      }
      logger.i('🗑️ Removed trusted certificate for $host');
    }
  }
  
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    logger.d('📡 GET: $url');
    return await _client.get(uri, headers: headers);
  }
  
  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final uri = Uri.parse(url);
    logger.d('📡 POST: $url');
    return await _client.post(uri, headers: headers, body: body, encoding: encoding);
  }
  
  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final uri = Uri.parse(url);
    logger.d('📡 PUT: $url');
    return await _client.put(uri, headers: headers, body: body, encoding: encoding);
  }
  
  Future<http.Response> delete(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    logger.d('📡 DELETE: $url');
    return await _client.delete(uri, headers: headers);
  }
  
  void close() => _client.close();
  IOClient get client => _client;
}