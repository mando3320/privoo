// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:firebase_performance/firebase_performance.dart';

import 'app.dart';
// ❌ تم إزالة import 'core/device_helper.dart';
import 'firebase/firebase_options.dart';
import 'config/app_theme.dart';
import 'controllers/app_controller.dart';
import 'l10n/app_localizations.dart';
import 'services/hive_storage_service.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    logger.i('✅ تم تحميل ملف .env بنجاح');

    // ❌ تم إزالة كود DeviceHelper بالكامل
    // if (Platform.isAndroid) {
    //   final isProblematic = await DeviceHelper.isProblematicDevice();
    //   if (isProblematic) {
    //     logger.w('⚠️ تم اكتشاف جهاز OPPO / Realme / OnePlus / Vivo — تفعيل الحماية الخاصة.');
    //   }
    // }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('✅ تم تهيئة Firebase بنجاح');

    await HiveStorageService.init();
    logger.i('✅ تم تهيئة Hive Storage بنجاح');

    const isReleaseMode = bool.fromEnvironment('dart.vm.product');
    if (isReleaseMode) {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      logger.i('📊 Firebase Performance Monitoring enabled');
    }

    runApp(
      const ProviderScope(
        child: PrivooMainApp(),
      ),
    );
  } catch (e, s) {
    logger.e('❌ خطأ أثناء التهيئة: $e');
    logger.e('Stacktrace: $s');
    
    // عرض شاشة خطأ بديلة
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ في تهيئة التطبيق: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrivooMainApp extends ConsumerWidget {
  const PrivooMainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    
    // الحصول على الثيم الحالي
    final theme = app.getCurrentTheme();

    return MaterialApp(
      title: 'Privoo',
      theme: theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: app.themeMode,
      locale: app.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'), Locale('en'), Locale('fr'), Locale('es'),
        Locale('de'), Locale('zh'), Locale('ru'), Locale('hi'),
        Locale('tr'), Locale('ja'),
      ],
      home: const PrivooApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}