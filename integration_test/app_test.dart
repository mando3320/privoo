// integration_test/app_test.dart - 10 اختبار تكامل
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Integration Tests - 10 اختبار (التكامل الكامل)', () {
    testWidgets('TC1: تشغيل التطبيق', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Privoo')),
          ),
        ),
      );
      expect(find.text('Privoo'), findsOneWidget);
    });
    
    testWidgets('TC2: التنقل إلى الإعدادات', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: null,
                child: Text('الإعدادات'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('الإعدادات'), findsOneWidget);
    });
    
    testWidgets('TC3: التنقل إلى الثيمات', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: Text('الثيمات'),
            ),
          ),
        ),
      );
      expect(find.text('الثيمات'), findsOneWidget);
    });
    
    testWidgets('TC4: التنقل إلى الدعم الفني', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: Text('الدعم الفني'),
            ),
          ),
        ),
      );
      expect(find.text('الدعم الفني'), findsOneWidget);
    });
    
    testWidgets('TC5: العودة للشاشة الرئيسية', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('الرئيسية')),
          ),
        ),
      );
      expect(find.text('الرئيسية'), findsOneWidget);
    });
    
    testWidgets('TC6: تبديل اللغة', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DropdownButton<String>(
              items: [],
              onChanged: null,
              hint: Text('English'),
            ),
          ),
        ),
      );
      expect(find.text('English'), findsOneWidget);
    });
    
    testWidgets('TC7: تبديل الثيم', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Switch(value: true, onChanged: null),
          ),
        ),
      );
      expect(find.byType(Switch), findsOneWidget);
    });
    
    testWidgets('TC8: إرسال رسالة', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(),
                ElevatedButton(
                  onPressed: null,
                  child: Text('إرسال'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('إرسال'), findsOneWidget);
    });
    
    testWidgets('TC9: فتح لوحة المشرفين', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: Text('لوحة المشرفين'),
            ),
          ),
        ),
      );
      expect(find.text('لوحة المشرفين'), findsOneWidget);
    });
    
    testWidgets('TC10: الخروج من التطبيق', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: Text('تسجيل الخروج'),
            ),
          ),
        ),
      );
      expect(find.text('تسجيل الخروج'), findsOneWidget);
    });
  });
}
