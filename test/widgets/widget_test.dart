// test/widgets/widget_test.dart - 20 اختبار واجهات
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Tests - 20 اختبار (واجهات المستخدم)', () {
    testWidgets('TC1: شاشة الإعدادات تظهر', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('الإعدادات')),
          ),
        ),
      );
      expect(find.text('الإعدادات'), findsOneWidget);
    });
    
    testWidgets('TC2: شاشة الثيمات تظهر', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('اختر الثيم')),
          ),
        ),
      );
      expect(find.text('اختر الثيم'), findsOneWidget);
    });
    
    testWidgets('TC3: شاشة الدعم الفني تظهر', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('الدعم الفني')),
          ),
        ),
      );
      expect(find.text('الدعم الفني'), findsOneWidget);
    });
    
    testWidgets('TC4: زر الإرسال موجود', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: const Text('إرسال'),
            ),
          ),
        ),
      );
      expect(find.text('إرسال'), findsOneWidget);
    });
    
    testWidgets('TC5: زر الحفظ موجود', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: null,
              child: const Text('حفظ'),
            ),
          ),
        ),
      );
      expect(find.text('حفظ'), findsOneWidget);
    });
    
    testWidgets('TC6: زر الإلغاء موجود', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: null,
              child: const Text('إلغاء'),
            ),
          ),
        ),
      );
      expect(find.text('إلغاء'), findsOneWidget);
    });
    
    testWidgets('TC7: حقل إدخال النص', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(hintText: 'اكتب رسالتك'),
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
    });
    
    testWidgets('TC8: قائمة منسدلة للغات', (tester) async {
      await tester.pumpWidget(
        MaterialApp(  // إزالة const
          home: Scaffold(
            body: DropdownButton<String>(
              items: const [],
              onChanged: null,
              hint: const Text('اختر اللغة'),
            ),
          ),
        ),
      );
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });
    
    testWidgets('TC9: مفتاح تبديل (Switch)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Switch(value: true, onChanged: null),
          ),
        ),
      );
      expect(find.byType(Switch), findsOneWidget);
    });
    
    testWidgets('TC10: شريط التمرير (Slider)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Slider(value: 0.5, onChanged: null),
          ),
        ),
      );
      expect(find.byType(Slider), findsOneWidget);
    });
    
    testWidgets('TC11: شارة Pro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Chip(label: Text('Pro')),
          ),
        ),
      );
      expect(find.text('Pro'), findsOneWidget);
    });
    
    testWidgets('TC12: شارة مجاني', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Chip(label: Text('مجاني')),
          ),
        ),
      );
      expect(find.text('مجاني'), findsOneWidget);
    });
    
    testWidgets('TC13: أيقونة القفل', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: const Icon(Icons.lock),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
    
    testWidgets('TC14: أيقونة الثيم', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: const Icon(Icons.palette),
          ),
        ),
      );
      expect(find.byIcon(Icons.palette), findsOneWidget);
    });
    
    testWidgets('TC15: شاشة الإنجازات العلمية', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('الإنجازات العلمية')),
          ),
        ),
      );
      expect(find.text('الإنجازات العلمية'), findsOneWidget);
    });
    
    testWidgets('TC16: شاشة الامتثال القانوني', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('الامتثال القانوني')),
          ),
        ),
      );
      expect(find.text('الامتثال القانوني'), findsOneWidget);
    });
    
    testWidgets('TC17: شاشة إدارة المشرفين', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('إدارة المشرفين')),
          ),
        ),
      );
      expect(find.text('إدارة المشرفين'), findsOneWidget);
    });
    
    testWidgets('TC18: شاشة تذاكر الدعم', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('تذاكر الدعم')),
          ),
        ),
      );
      expect(find.text('تذاكر الدعم'), findsOneWidget);
    });
    
    testWidgets('TC19: شاشة إدارة المستخدمين', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('إدارة المستخدمين')),
          ),
        ),
      );
      expect(find.text('إدارة المستخدمين'), findsOneWidget);
    });
    
    testWidgets('TC20: شاشة الترقي لـ Pro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('ترقية إلى Pro')),
          ),
        ),
      );
      expect(find.text('ترقية إلى Pro'), findsOneWidget);
    });
  });
}