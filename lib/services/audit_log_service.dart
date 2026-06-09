// lib/services/audit_log_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

enum AuditEventType {
  login, logout, messageSent, callStarted, accountDeleted,
}

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> logEvent({
    required AuditEventType eventType,
    String? details,
    String? severity,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore.collection('audit_logs').add({
        'userId': user?.uid ?? 'anonymous',
        'eventType': eventType.name,
        'details': details ?? '',
        'severity': severity ?? 'info',
        'timestamp': FieldValue.serverTimestamp(),
      });
      logger.d('📝 Audit log: $eventType - $details');
    } catch (e) {
      logger.e('خطأ في تسجيل التدقيق: $e');
    }
  }
}
