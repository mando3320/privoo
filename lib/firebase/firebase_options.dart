// lib/firebase/firebase_options.dart
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
            'DefaultFirebaseOptions have not been configured for iOS.');
      case TargetPlatform.macOS:
        throw UnsupportedError(
            'DefaultFirebaseOptions have not been configured for macOS.');
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static FirebaseOptions get android {
    // استخدام قيم افتراضية آمنة إذا لم تكن الـ env variables موجودة
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyB7Lb8Qx9Yz3W4aB5cD6eF7gH8iJ9kL0mN1oP2qR';
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '392831856847';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? 'privoo-b1c4b';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'privoo-b1c4b.firebasestorage.app';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:android:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }

  static FirebaseOptions get web {
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyB7Lb8Qx9Yz3W4aB5cD6eF7gH8iJ9kL0mN1oP2qR';
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '392831856847';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? 'privoo-b1c4b';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'privoo-b1c4b.firebasestorage.app';
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'privoo-b1c4b.firebaseapp.com';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:web:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
    );
  }

  static FirebaseOptions get windows {
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyB7Lb8Qx9Yz3W4aB5cD6eF7gH8iJ9kL0mN1oP2qR';
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '392831856847';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? 'privoo-b1c4b';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'privoo-b1c4b.firebasestorage.app';
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'privoo-b1c4b.firebaseapp.com';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:windows:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
    );
  }

  static FirebaseOptions get linux {
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyB7Lb8Qx9Yz3W4aB5cD6eF7gH8iJ9kL0mN1oP2qR';
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '392831856847';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? 'privoo-b1c4b';
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'privoo-b1c4b.firebasestorage.app';
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'privoo-b1c4b.firebaseapp.com';
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:linux:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
    );
  }
}