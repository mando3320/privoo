// test/models/models_test.dart - 10 اختبار
import 'package:flutter_test/flutter_test.dart';
import 'package:privoo/models/admin_model.dart';
import 'package:privoo/models/message_model.dart';

void main() {
  group('Models Tests - 10 اختبار', () {
    test('TC1: إنشاء نموذج مشرف', () {
      final admin = AdminModel(
        phoneNumber: '+201234567890',
        role: AdminRole.superAdmin,
        name: 'مدير',
        assignedAt: DateTime.now(),
        permissions: [],
        isActive: true,
      );
      expect(admin.phoneNumber, '+201234567890');
      expect(admin.role, AdminRole.superAdmin);
    });
    
    test('TC2: تحويل نموذج مشرف لخريطة', () {
      final admin = AdminModel(
        phoneNumber: '+201234567890',
        role: AdminRole.superAdmin,
        name: 'مدير',
        assignedAt: DateTime(2024, 1, 1),
        permissions: [],
        isActive: true,
      );
      final map = admin.toMap();
      expect(map['phoneNumber'], '+201234567890');
      expect(map['isActive'], true);
    });
    
    test('TC3: إنشاء نموذج رسالة نصية', () {
      final message = MessageModel(
        id: 'msg1',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Hello',
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      expect(message.content, 'Hello');
      expect(message.type, MessageType.text);
    });
    
    test('TC4: إنشاء نموذج رسالة صورة', () {
      final message = MessageModel(
        id: 'msg2',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'image_url',
        timestamp: DateTime.now(),
        type: MessageType.image,
      );
      expect(message.type, MessageType.image);
    });
    
    test('TC5: رسالة مختفية', () {
      final message = MessageModel(
        id: 'msg3',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Secret',
        timestamp: DateTime.now(),
        type: MessageType.text,
        disappearAfterSeconds: 60,
      );
      expect(message.disappearAfterSeconds, 60);
    });
    
    test('TC6: رسالة مثبتة', () {
      final message = MessageModel(
        id: 'msg4',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Important',
        timestamp: DateTime.now(),
        type: MessageType.text,
        isPinned: true,
      );
      expect(message.isPinned, true);
    });
    
    test('TC7: رسالة مع رد', () {
      final message = MessageModel(
        id: 'msg5',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Reply',
        timestamp: DateTime.now(),
        type: MessageType.text,
        replyToMessageId: 'original_msg',
      );
      expect(message.replyToMessageId, 'original_msg');
    });
    
    test('TC8: رسالة مع منشن', () {
      final message = MessageModel(
        id: 'msg6',
        senderId: 'user1',
        receiverId: 'user2',
        content: '@user3 Hello',
        timestamp: DateTime.now(),
        type: MessageType.text,
        mentions: ['user3'],
      );
      expect(message.mentions?.contains('user3'), true);
    });
    
    test('TC9: رسالة مع تفاعلات', () {
      final message = MessageModel(
        id: 'msg7',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Post',
        timestamp: DateTime.now(),
        type: MessageType.text,
        reactions: {'❤️': ['user1', 'user2']},
      );
      expect(message.reactions?.containsKey('❤️'), true);
    });
    
    test('TC10: نسخة نموذج رسالة', () {
      final original = MessageModel(
        id: 'msg8',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Original',
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      final copy = original.copyWith(content: 'Modified');
      expect(copy.content, 'Modified');
      expect(copy.id, original.id);
    });
  });
}