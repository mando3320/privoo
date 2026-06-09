import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class WebSearchService {
  static Future<List<String>> search(
    String query, {
    String language = 'ar',
    int maxResults = 5,
    int retryCount = 2,
  }) async {
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        final encodedQuery = Uri.encodeComponent(query);
        final url =
            'https://html.duckduckgo.com/html/?q=$encodedQuery&kl=$language';

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (PrivooBot)',
            'Accept-Language': language,
            'Accept': 'text/html',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          if (attempt < retryCount) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          return ['⚠️ فشل الاتصال بـ DuckDuckGo: ${response.statusCode}'];
        }

        final document = parse(response.body);
        final results = <String>{}; // ← يمنع التكرار

        final elements = document.querySelectorAll(
          '.result__snippet, .result__body, .result__a, .result__title'
        );

        for (final element in elements) {
          final text = _cleanText(element.text);
          if (text.isNotEmpty) results.add(text);
          if (results.length >= maxResults) break;
        }

        return results.isNotEmpty
            ? results.toList()
            : [
                '⚠️ لا توجد نتائج مفيدة. جرب إعادة صياغة السؤال.',
              ];
      } catch (e) {
        if (attempt < retryCount) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        return ['⚠️ خطأ أثناء تنفيذ البحث: $e'];
      }
    }

    return ['⚠️ خطأ غير متوقع أثناء البحث.'];
  }

  static String _cleanText(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}