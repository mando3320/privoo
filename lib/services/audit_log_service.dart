// lib/services/audit_log_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../main.dart';

enum AuditEventType {
  login, logout, messageSent, callStarted, accountDeleted,
}

class AuditLogService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<void> logEvent({
    required AuditEventType eventType,
    String? details,
    String? severity,
  }) async {
    try {
      final user = SupabaseService().currentUser;
      await _supabase.from('audit_log').insert({
        'user_id': user?.id ?? 'anonymous',
        'event_type': eventType.name,
        'details': details ?? '',
        'severity': severity ?? 'info',
        'created_at': DateTime.now().toIso8601String(),
      });
      logger.d('📝 Audit log: $eventType - $details');
    } catch (e) {
      logger.e('خطأ في تسجيل التدقيق: $e');
    }
  }
}