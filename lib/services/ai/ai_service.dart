// services/ai/ai_service.dart
import 'package:privoo/main.dart';
import 'gemini_service.dart';
import '../web_search_service.dart';
import '../conversation_memory_service.dart';
import '../tts_service.dart';
import '../prompt_builder.dart';

class AIService {
  final GeminiService _gemini = GeminiService();

  Future<String> chat({
    required String user,
    required String message,
    required bool isPro,
    required bool isLifetime,
    required int messagesToday,
    int dailyLimit = 10,
    int? feedback,
    String language = 'ar',
    bool withRAG = true,
    bool withTTS = false,
  }) async {
    if (!(isPro || isLifetime) && messagesToday >= dailyLimit) {
      return '[تم الوصول إلى الحد اليومي. اشترك في Privoo Pro للاستمرار.]';
    }

    try {
      String finalPrompt = message;

      if (withRAG) {
        await ConversationMemoryEncryptedService.saveMessage(
          userId: user,
          chatId: 'ai_chat',
          role: 'user',
          text: message,
        );

        final history = await ConversationMemoryEncryptedService.getConversation(
          userId: user,
          chatId: 'ai_chat',
        );
        
        final needsSearch = _shouldUseRAG(message);
        List<String> searchResults = [];
        if (needsSearch) {
          searchResults = await WebSearchService.search(message, language: language);
        }

        final safeHistory = history.map((e) => {
          'role': e['role'] ?? 'user',
          'content': e['text'] ?? ''
        }).toList();

        finalPrompt = PromptBuilder.buildPrompt(
          userQuery: message,
          history: safeHistory,
          searchResults: searchResults,
          language: language,
        );
      }

      final response = await _gemini.chat(
        message: finalPrompt,
        isPro: isPro || isLifetime,
        language: language,
      );

      if (withRAG) {
        await ConversationMemoryEncryptedService.saveMessage(
          userId: user,
          chatId: 'ai_chat',
          role: 'assistant',
          text: response,
        );
      }

      if (withTTS) {
        await TTSService.speak(response, language: language);
      }

      return response.trim();
    } catch (e) {
      logger.e("⚠️ خطأ أثناء معالجة الذكاء الاصطناعي: $e");
      return "[حدث خطأ أثناء معالجة الذكاء الاصطناعي]";
    }
  }

  Future<String> translate(String text, String targetLanguage) async {
    try {
      final prompt = 'ترجم النص التالي إلى اللغة $targetLanguage:\n\n$text';
      final response = await _gemini.chat(
        message: prompt,
        isPro: true,
        language: targetLanguage,
      );
      return response.trim();
    } catch (e) {
      logger.e("⚠️ خطأ في الترجمة: $e");
      return text;
    }
  }

  bool _shouldUseRAG(String input) {
    final lower = input.toLowerCase();
    final patterns = [
      'آخر', 'متى', 'ما هو', 'من هو', 'أحدث', 'خبر',
      'تاريخ', 'وين', 'كم', 'أيه الجديد', 'شرح', 'مين',
    ];
    return patterns.any((pattern) => lower.contains(pattern));
  }
}