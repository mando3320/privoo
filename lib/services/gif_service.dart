// services/gif_service.dart
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GifService {
  static String? get _apiKey => dotenv.env['GIPHY_API_KEY'];

  /// فتح منتقي GIF (خطة بسيطة: نجلب GIF واحدًا عبر واجهة Giphy REST)
  /// تعيد رابط GIF أو null عند الإلغاء/الخطأ.
  static Future<String?> pickGif(BuildContext context, {String query = 'funny'}) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      _showApiKeyWarning(context);
      return null;
    }

    try {
      final uri = Uri.https('api.giphy.com', '/v1/gifs/search', {
        'api_key': key,
        'q': query,
        'limit': '1',
        'rating': 'pg',
        'lang': 'ar'
      });

      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final map = convert.jsonDecode(resp.body) as Map<String, dynamic>;
        final data = map['data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          final images = first['images'] as Map<String, dynamic>?;
          final original = images?['original'] as Map<String, dynamic>?;
          final url = original?['url'] as String?;
          return url;
        }
      }
    } catch (e) {
      // ignore and return null
    }

    return null;
  }
  
  static void _showApiKeyWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ يرجى إضافة GIPHY_API_KEY في ملف .env'),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  /// الحصول على رابط GIF (لم يعد مطلوبًا - `pickGif` يعيد الرابط مباشرة)
  static String getGifUrlFromResponse(String? url) => url ?? '';
}