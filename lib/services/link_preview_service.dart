// lib/services/link_preview_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LinkPreview {
  final String title;
  final String? description;
  final String? image;
  final String url;

  LinkPreview({
    required this.title,
    this.description,
    this.image,
    required this.url,
  });
}

class LinkPreviewService {
  static String get _apiKey => dotenv.env['LINK_PREVIEW_API_KEY'] ?? '';

  static Future<LinkPreview?> getPreview(String url) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_LINK_PREVIEW_API_KEY_HERE') {
      debugPrint('⚠️ LINK_PREVIEW_API_KEY not configured');
      return null;
    }
    
    try {
      final response = await http.get(
        Uri.parse('https://api.linkpreview.net/?q=$url'),
        headers: {
          'X-API-Key': _apiKey,
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) return null;
      
      final data = jsonDecode(response.body);
      return LinkPreview(
        title: data['title'] ?? '',
        description: data['description'],
        image: data['image'],
        url: url,
      );
    } catch (e) {
      return null;
    }
  }
  
  static List<String> extractLinks(String text) {
    final regex = RegExp(r'(https?://[^\s]+)');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }
}