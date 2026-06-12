// lib/services/contact_service.dart
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';

class ContactService {
  static Future<List<Contact>> getPhoneContacts() async {
    try {
      // ✅ طلب الإذن باستخدام permission_handler أولاً
      final status = await Permission.contacts.request();
      logger.i('📱 Contacts permission status: $status');
      
      if (status.isGranted) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        logger.i('📱 Found ${contacts.length} contacts');
        
        // ✅ طباعة أول 5 جهات اتصال
        for (var i = 0; i < contacts.length && i < 5; i++) {
          final contact = contacts[i];
          logger.i('📱 Contact: ${contact.displayName}, Phones: ${contact.phones.map((p) => p.number).join(', ')}');
        }
        
        return contacts;
      } else {
        logger.w('📱 Contacts permission denied');
        return [];
      }
    } catch (e) {
      logger.e('❌ Error getting contacts: $e');
      return [];
    }
  }
  
  static Future<bool> hasPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }
  
  static Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }
}