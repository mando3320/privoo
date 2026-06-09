// lib/services/text_formatter.dart
class TextFormatter {
  /// تطبيق التنسيق على النص
  static String format(String text) {
    String result = text;
    
    // **نص** → Bold
    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    result = result.replaceAllMapped(boldRegex, (match) => '<b>${match.group(1)}</b>');
    
    // *نص* → Italic
    final italicRegex = RegExp(r'\*(.+?)\*');
    result = result.replaceAllMapped(italicRegex, (match) => '<i>${match.group(1)}</i>');
    
    // __نص__ → Bold
    final boldUnderscoreRegex = RegExp(r'__(.+?)__');
    result = result.replaceAllMapped(boldUnderscoreRegex, (match) => '<b>${match.group(1)}</b>');
    
    // _نص_ → Italic
    final italicUnderscoreRegex = RegExp(r'_(.+?)_');
    result = result.replaceAllMapped(italicUnderscoreRegex, (match) => '<i>${match.group(1)}</i>');
    
    return result;
  }
  
  /// إزالة التنسيق (للحصول على النص الخام)
  static String removeFormatting(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1');
  }
  
  /// التحقق من وجود تنسيق في النص
  static bool hasFormatting(String text) {
    return RegExp(r'(\*\*.+?\*\*|\*.+?\*|__.+?__|_.+?_)').hasMatch(text);
  }
}