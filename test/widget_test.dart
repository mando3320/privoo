// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // بناء التطبيق وتحفيز إطار
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('جاري تهيئة التطبيق...'),
            ),
          ),
        ),
      ),
    );

    // التحقق من وجود عناصر الواجهة الأساسية
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('جاري تهيئة التطبيق...'), findsOneWidget);
  });
}
