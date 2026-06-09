// test/encryption_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:privoo/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    test('should encrypt and decrypt text correctly', () async {
      final keyBytes = List.generate(32, (i) => i);
      final plaintext = 'Hello, Privoo!';
      
      final encrypted = await EncryptionService.encrypt(
        plaintext: plaintext,
        keyBytes: keyBytes,
      );
      
      final decrypted = await EncryptionService.decrypt(
        encrypted: encrypted,
        keyBytes: keyBytes,
      );
      
      expect(decrypted, plaintext);
    });
    
    test('should fail with wrong key', () async {
      final keyBytes1 = List.generate(32, (i) => i);
      final keyBytes2 = List.generate(32, (i) => 255 - i);
      final plaintext = 'Secret message';
      
      final encrypted = await EncryptionService.encrypt(
        plaintext: plaintext,
        keyBytes: keyBytes1,
      );
      
      expect(
        () async => await EncryptionService.decrypt(
          encrypted: encrypted,
          keyBytes: keyBytes2,
        ),
        throwsException,
      );
    });
  });
}
