// lib/core/privoo_dev_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class PrivooDevPage extends StatefulWidget {
  const PrivooDevPage({super.key});

  @override
  State<PrivooDevPage> createState() => _PrivooDevPageState();
}

class _PrivooDevPageState extends State<PrivooDevPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Privoo Dev Tools'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ معلومات المستخدم
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👤 معلومات المستخدم',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _infoRow('UID', user?.id ?? 'غير مسجل'),
                    _infoRow('Email', user?.email ?? 'غير متوفر'),
                    _infoRow('Phone', user?.phone ?? 'غير متوفر'),
                    _infoRow('Session', user != null ? '✅ نشط' : '❌ غير مسجل'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ اختبار OTP
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '📱 اختبار OTP (Supabase)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق (6 أرقام)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sendOTP,
                            child: const Text('إرسال OTP'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('تحقق'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ اختبار قاعدة البيانات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '🗄️ اختبار Supabase',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testDatabase,
                            child: const Text('اختبار الاتصال'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('تسجيل الخروج'),
                          ),
                        ),
                      ],
                    ),
                    if (_status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status.contains('✅') ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _status = '❌ الرجاء إدخال رقم الهاتف');
      return;
    }

    try {
      await SupabaseService().signInWithOTP(phone);
      setState(() => _status = '✅ تم إرسال OTP إلى $phone');
    } catch (e) {
      setState(() => _status = '❌ فشل الإرسال: $e');
    }
  }

  Future<void> _verifyOTP() async {
    final phone = _phoneController.text.trim();
    final code = _otpController.text.trim();

    if (phone.isEmpty || code.length != 6) {
      setState(() => _status = '❌ الرجاء إدخال رقم الهاتف ورمز 6 أرقام');
      return;
    }

    try {
      final response = await SupabaseService().verifyOTP(phone, code);
      if (response.user != null) {
        setState(() => _status = '✅ تم تسجيل الدخول بنجاح!');
      } else {
        setState(() => _status = '❌ فشل التحقق');
      }
    } catch (e) {
      setState(() => _status = '❌ فشل التحقق: $e');
    }
  }

  Future<void> _testDatabase() async {
    try {
      final user = SupabaseService().currentUser;
      if (user == null) {
        setState(() => _status = '❌ الرجاء تسجيل الدخول أولاً');
        return;
      }

      final userData = await SupabaseService().getUser(user.id);
      if (userData != null) {
        setState(() => _status = '✅ قاعدة البيانات متصلة! المستخدم: ${userData.name}');
      } else {
        setState(() => _status = '⚠️ المستخدم غير موجود في قاعدة البيانات');
      }
    } catch (e) {
      setState(() => _status = '❌ فشل الاتصال: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService().signOut();
      setState(() => _status = '✅ تم تسجيل الخروج');
    } catch (e) {
      setState(() => _status = '❌ فشل تسجيل الخروج: $e');
    }
  }
}