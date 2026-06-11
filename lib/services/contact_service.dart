// lib/services/contact_service.dart
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  static Future<List<Contact>> getPhoneContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      return contacts;
    }
    return [];
  }
  
  static Future<bool> hasPermission() async {
    return await FlutterContacts.requestPermission();
  }
}