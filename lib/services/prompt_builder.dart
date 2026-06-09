// lib/services/prompt_builder.dart

/// بناء الـ Prompt باستخدام السياق والبحث
class PromptBuilder {
  static String buildPrompt({
    required String userQuery,
    required List<Map<String, String>> history,
    required List<String> searchResults,
    required String language,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('أنت مساعد ذكي يتحدث العربية بطلاقة. كن مفيداً ومختصراً.');
    
    if (history.isNotEmpty) {
      buffer.writeln('\n=== سياق المحادثة السابقة ===');
      for (final entry in history) {
        final role = entry['role'] == 'user' ? 'المستخدم' : 'المساعد';
        buffer.writeln('$role: ${entry['text']}');
      }
    }
    
    if (searchResults.isNotEmpty) {
      buffer.writeln('\n=== معلومات إضافية من البحث ===');
      for (final result in searchResults) {
        buffer.writeln('- $result');
      }
    }
    
    buffer.writeln('\n=== سؤال المستخدم ===');
    buffer.writeln(userQuery);
    
    buffer.writeln('\n=== المطلوب ===');
    buffer.writeln('أجب على السؤال باستخدام السياق والمعلومات المتاحة. إن لم تجد المعلومة، قل "لا أعرف".');
    
    return buffer.toString();
  }
}