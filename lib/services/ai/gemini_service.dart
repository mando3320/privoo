// lib/services/ai/gemini_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../main.dart';

class GeminiService {
  static String? get _apiKey => dotenv.env['GEMINI_API_KEY'];
  
  late final GenerativeModel _model;
  late final GenerativeModel _modelPro;

  GeminiService() {
    final apiKey = _apiKey;
    
    // ✅ التحقق الصحيح من وجود المفتاح
    if (apiKey == null || apiKey.isEmpty) {
      final errorMsg = '❌ GEMINI_API_KEY not found in .env file';
      logger.e(errorMsg);
      
      if (kDebugMode) {
        throw Exception('$errorMsg\nPlease add GEMINI_API_KEY=your_key to .env');
      } else {
        // وضع الإنتاج - نموذج وهمي مع تسجيل الخطأ
        _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: 'dummy');
        _modelPro = GenerativeModel(model: 'gemini-1.5-pro', apiKey: 'dummy');
        return;
      }
    }
    
    // ✅ استخدام نماذج متاحة ومجانية
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',  // ✅ بدلاً من gemini-1.5-flash
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 500,
        temperature: 0.7,
      ),
    );

    _modelPro = GenerativeModel(
      model: 'gemini-2.0-flash-exp',  // ✅ نموذج Pro أحدث وأسرع
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 1000,
        temperature: 0.7,
      ),
    );
    
    logger.i('✅ Gemini Service initialized successfully');
  }

  Future<String> chat({
    required String message,
    required bool isPro,
    String language = 'ar',
  }) async {
    try {
      final model = isPro ? _modelPro : _model;
      
      // ✅ دعم اللغة في الـ Prompt
      final languageName = _getLanguageName(language);
      
      final prompt = '''
أنت مساعد ذكي يتحدث اللغة $languageName بطلاقة.
الرجاء الرد بنفس اللغة التي كتب بها المستخدم.
كن مفيداً ومختصراً.

السؤال: $message
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'عذراً، لم أستطع الرد.';
      
    } catch (e) {
      logger.e('Gemini Error: $e');
      return 'حدث خطأ أثناء معالجة الطلب. حاول مرة أخرى.';
    }
  }
  
  // ✅ إضافة دالة generateWithRetry للمزيد من الموثوقية
  Future<String> chatWithRetry({
    required String message,
    required bool isPro,
    String language = 'ar',
    int retries = 3,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await chat(message: message, isPro: isPro, language: language);
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 << i));
        logger.d('🔄 إعادة محاولة Gemini (${i + 1}/$retries)');
      }
    }
    return 'حدث خطأ، حاول مرة أخرى.';
  }

  // ✅ دالة مساعدة لتحويل كود اللغة إلى اسم
  String _getLanguageName(String code) {
    switch (code) {
      case 'ar': return 'العربية';
      case 'en': return 'الإنجليزية';
      case 'fr': return 'الفرنسية';
      case 'es': return 'الإسبانية';
      case 'de': return 'الألمانية';
      case 'zh': return 'الصينية';
      case 'ru': return 'الروسية';
      case 'hi': return 'الهندية';
      case 'tr': return 'التركية';
      case 'ja': return 'اليابانية';
      default: return 'العربية';
    }
  }
}