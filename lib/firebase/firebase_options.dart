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
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('❌ FIREBASE_API_KEY not found in .env file');
    }
    if (messagingSenderId == null || messagingSenderId.isEmpty) {
      throw Exception('❌ FIREBASE_MESSAGING_SENDER_ID not found in .env file');
    }
    if (projectId == null || projectId.isEmpty) {
      throw Exception('❌ FIREBASE_PROJECT_ID not found in .env file');
    }
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:android:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket ?? '${projectId}.appspot.com',
    );
  }

  static FirebaseOptions get web {
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('❌ FIREBASE_API_KEY not found in .env file');
    }
    if (projectId == null || projectId.isEmpty) {
      throw Exception('❌ FIREBASE_PROJECT_ID not found in .env file');
    }
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:web:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId ?? '392831856847',
      projectId: projectId,
      authDomain: authDomain ?? '${projectId}.firebaseapp.com',
      storageBucket: storageBucket ?? '${projectId}.appspot.com',
    );
  }

  static FirebaseOptions get windows {
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('❌ FIREBASE_API_KEY not found in .env file');
    }
    if (projectId == null || projectId.isEmpty) {
      throw Exception('❌ FIREBASE_PROJECT_ID not found in .env file');
    }
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:windows:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId ?? '392831856847',
      projectId: projectId,
      authDomain: authDomain ?? '${projectId}.firebaseapp.com',
      storageBucket: storageBucket ?? '${projectId}.appspot.com',
    );
  }

  static FirebaseOptions get linux {
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('❌ FIREBASE_API_KEY not found in .env file');
    }
    if (projectId == null || projectId.isEmpty) {
      throw Exception('❌ FIREBASE_PROJECT_ID not found in .env file');
    }
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:392831856847:linux:672e8fe9b9f9bf1e6847ba',
      messagingSenderId: messagingSenderId ?? '392831856847',
      projectId: projectId,
      authDomain: authDomain ?? '${projectId}.firebaseapp.com',
      storageBucket: storageBucket ?? '${projectId}.appspot.com',
    );
  }
}
