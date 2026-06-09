import 'package:flutter_tts/flutter_tts.dart';
import '../main.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();

  static bool _isPaused = false;
  static bool _isInitialized = false;

  // ✅ بديل للخصائص المحذوفة من flutter_tts الحديثة
  static bool _isSpeaking = false;
  static String _lastText = '';

  /// إعداد TTS مبدئي
  static Future<void> init({String language = 'ar'}) async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage(language);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);

      // تحسين تجربة الانتظار
      await _tts.awaitSpeakCompletion(true);

      _isInitialized = true;

      logger.i('✅ TTS Service initialized with language: $language');
    } catch (e) {
      logger.e('❌ فشل تهيئة TTS Service: $e');
    }
  }

  /// نطق النصوص
  static Future<void> speak(
    String text, {
    String language = 'ar',
    double pitch = 1.0,
    double rate = 0.45,
    String voiceGender = 'male',
  }) async {
    if (text.isEmpty) return;

    // حفظ آخر نص
    _lastText = text;

    // حالة التشغيل
    _isSpeaking = true;

    // التأكد من التهيئة
    if (!_isInitialized) {
      await init(language: language);
    }

    try {
      await _tts.setLanguage(language);
      await _tts.setPitch(pitch);
      await _tts.setSpeechRate(rate);

      // اختيار الصوت المناسب إن توفر
      try {
        final voices = await _tts.getVoices;

        if (voices.isNotEmpty) {
          final selectedVoice = voices.firstWhere(
            (v) {
              final vLocale = v['locale']?.toString() ?? '';
              final vName = v['name']?.toString().toLowerCase() ?? '';

              return vLocale == language &&
                  vName.contains(voiceGender.toLowerCase());
            },
            orElse: () => voices.first,
          );

          await _tts.setVoice({
            'name': selectedVoice['name'],
            'locale': selectedVoice['locale'],
          });
        }
      } catch (e) {
        logger.w('⚠️ فشل اختيار الصوت: $e');
      }

      // تقسيم النصوص الطويلة
      final chunks = _splitText(text, maxLength: 200);

      for (final chunk in chunks) {
        await _tts.speak(chunk);

        // انتظار تقريبي بديل لـ isSpeaking المحذوفة
        await Future.delayed(
          Duration(
            milliseconds: (chunk.length * 75).clamp(1000, 15000),
          ),
        );

        // دعم الإيقاف المؤقت
        while (_isPaused) {
          await Future.delayed(
            const Duration(milliseconds: 200),
          );
        }
      }

      _isSpeaking = false;

      logger.d(
        '🔊 TTS: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."',
      );
    } catch (e) {
      _isSpeaking = false;

      logger.e('❌ فشل تشغيل TTS: $e');
    }
  }

  /// إيقاف النطق
  static Future<void> stop() async {
    _isPaused = false;
    _isSpeaking = false;

    try {
      await _tts.stop();

      logger.d('⏹️ TTS stopped');
    } catch (e) {
      logger.e('❌ فشل إيقاف TTS: $e');
    }
  }

  /// إيقاف مؤقت
  static Future<void> pause() async {
    _isPaused = true;

    try {
      await _tts.pause();

      logger.d('⏸️ TTS paused');
    } catch (e) {
      logger.e('❌ فشل إيقاف TTS مؤقتاً: $e');
    }
  }

  /// استئناف
  static Future<void> resume() async {
    _isPaused = false;

    try {
      if (_lastText.isNotEmpty) {
        await _tts.speak(_lastText);
      }

      logger.d('▶️ TTS resumed');
    } catch (e) {
      logger.e('❌ فشل استئناف TTS: $e');
    }
  }

  /// معرفة هل يوجد نطق حالي
  static Future<bool> isSpeaking() async {
    try {
      return _isSpeaking;
    } catch (e) {
      return false;
    }
  }

  /// تقسيم النصوص الطويلة
  static List<String> _splitText(
    String text, {
    int maxLength = 200,
  }) {
    if (text.length <= maxLength) {
      return [text];
    }

    final List<String> chunks = [];

    int start = 0;

    while (start < text.length) {
      int end = start + maxLength;

      if (end > text.length) {
        end = text.length;
      }

      // محاولة التقسيم عند نهاية جملة
      if (end < text.length) {
        final lastPeriod = text.lastIndexOf('.', end);
        final lastQuestion = text.lastIndexOf('?', end);
        final lastExclamation = text.lastIndexOf('!', end);
        final lastSpace = text.lastIndexOf(' ', end);

        final breakPoints = [
          lastPeriod,
          lastQuestion,
          lastExclamation,
          lastSpace,
        ].where((i) => i > start);

        if (breakPoints.isNotEmpty) {
          final lastBreak = breakPoints.reduce(
            (a, b) => a > b ? a : b,
          );

          end = lastBreak + 1;
        }
      }

      chunks.add(
        text.substring(start, end).trim(),
      );

      start = end;
    }

    return chunks;
  }
}