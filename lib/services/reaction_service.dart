// lib/services/reaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ إيموجي التفاعل الموسعة (18 إيموجي)
  static const List<String> availableReactions = [
    // الأساسية (6)
    '❤️', '👍', '😂', '😮', '😢', '😡',
    
    // إضافية (12)
    '🎉',  // احتفال
    '😍',  // حب شديد
    '🤔',  // تفكير
    '👏',  // تصفيق
    '🙏',  // شكراً
    '🔥',  // ممتاز
    '😎',  // رائع
    '🥰',  // حب
    '🤣',  // ضحك شديد
    '😱',  // صدمة
    '🥳',  // احتفال
    '💯',  // مئة بالمئة
  ];

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String reaction,
    required String userId,
    bool isGroup = false,
  }) async {
    // التحقق من أن الإيموجي مدعوم
    if (!availableReactions.contains(reaction)) {
      return; // أو رمي استثناء
    }
    
    final collection = isGroup
        ? _firestore.collection('groups').doc(chatId).collection('messages')
        : _firestore.collection('chats').doc(chatId).collection('messages');
    
    final doc = await collection.doc(messageId).get();
    final reactions = Map<String, dynamic>.from(doc.data()?['reactions'] ?? {});
    
    reactions[reaction] = (reactions[reaction] ?? 0) + 1;
    
    await collection.doc(messageId).update({'reactions': reactions});
  }

  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String reaction,
    required String userId,
    bool isGroup = false,
  }) async {
    final collection = isGroup
        ? _firestore.collection('groups').doc(chatId).collection('messages')
        : _firestore.collection('chats').doc(chatId).collection('messages');
    
    final doc = await collection.doc(messageId).get();
    final reactions = Map<String, dynamic>.from(doc.data()?['reactions'] ?? {});
    
    if (reactions[reaction] != null) {
      reactions[reaction] = reactions[reaction] - 1;
      if (reactions[reaction] <= 0) {
        reactions.remove(reaction);
      }
      await collection.doc(messageId).update({'reactions': reactions});
    }
  }
  
  // ✅ دالة مساعدة للحصول على اسم الإيموجي
  static String getReactionName(String reaction) {
    switch (reaction) {
      case '❤️': return 'قلب';
      case '👍': return 'أعجبني';
      case '😂': return 'ضحك';
      case '😮': return 'متفاجئ';
      case '😢': return 'حزين';
      case '😡': return 'غاضب';
      case '🎉': return 'احتفال';
      case '😍': return 'حب';
      case '🤔': return 'تفكير';
      case '👏': return 'تصفيق';
      case '🙏': return 'شكراً';
      case '🔥': return 'ممتاز';
      case '😎': return 'رائع';
      case '🥰': return 'حب';
      case '🤣': return 'ضحك';
      case '😱': return 'صدمة';
      case '🥳': return 'احتفال';
      case '💯': return 'مئة';
      default: return '';
    }
  }
  
  // ✅ دالة للحصول على كل الإيموجي مع أسمائها
  static List<Map<String, String>> getReactionsWithNames() {
    return availableReactions.map((reaction) {
      return {
        'code': reaction,
        'name': getReactionName(reaction),
      };
    }).toList();
  }
}