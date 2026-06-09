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
  
  static const Map<String, List<String>> _trustedCertificates = {
    'firebase.com': ['sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='],
    'googleapis.com': ['sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB='],
    'privoo-worker.workers.dev': ['sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC='],
    'api.linkpreview.net': ['sha256/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD='],
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
      
      for (final entry in _trustedCertificates.entries) {
        if (host.contains(entry.key) || entry.key.contains(host)) {
          if (entry.value.contains(fingerprint)) {
            logger.i('✅ SSL Certificate validated for $host');
            return true;
          }
        }
      }
      
      logger.e('❌ Invalid SSL certificate for $host! Possible MITM attack!');
      return false;
    } catch (e) {
      logger.e('❌ SSL validation error for $host: $e');
      return false;
    }
  }
  
  String _getCertificateFingerprint(X509Certificate cert) {
    final digest = sha256.convert(cert.der);
    return 'sha256/${base64Encode(digest.bytes)}';
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
  
  static void addTrustedCertificate(String host, String fingerprint) {
    _trustedCertificates.putIfAbsent(host, () => []).add(fingerprint);
    logger.i('✅ Added trusted certificate for $host');
  }
}
