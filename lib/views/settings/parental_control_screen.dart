// lib/views/settings/parental_control_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';
import '../../controllers/parental_control_controller.dart';

class ParentalControlScreen extends ConsumerStatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  ConsumerState<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends ConsumerState<ParentalControlScreen> {
  bool _isEnabled = false;
  bool _blockAdultContent = true;
  bool _blockViolence = true;
  bool _blockHateSpeech = true;
  bool _limitScreenTime = false;
  int _dailyLimitMinutes = 120;
  bool _requirePassword = true;
  String _pinCode = '';
  bool _isPinSet = false;
  List<String> _allowedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('parental_enabled') ?? false;
      _blockAdultContent = prefs.getBool('parental_block_adult') ?? true;
      _blockViolence = prefs.getBool('parental_block_violence') ?? true;
      _blockHateSpeech = prefs.getBool('parental_block_hate') ?? true;
      _limitScreenTime = prefs.getBool('parental_limit_time') ?? false;
      _dailyLimitMinutes = prefs.getInt('parental_daily_limit') ?? 120;
      _requirePassword = prefs.getBool('parental_require_password') ?? true;
      _pinCode = prefs.getString('parental_pin') ?? '';
      _isPinSet = _pinCode.isNotEmpty;
      _allowedContacts = prefs.getStringList('parental_allowed_contacts') ?? [];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('parental_enabled', _isEnabled);
    await prefs.setBool('parental_block_adult', _blockAdultContent);
    await prefs.setBool('parental_block_violence', _blockViolence);
    await prefs.setBool('parental_block_hate', _blockHateSpeech);
    await prefs.setBool('parental_limit_time', _limitScreenTime);
    await prefs.setInt('parental_daily_limit', _dailyLimitMinutes);
    await prefs.setBool('parental_require_password', _requirePassword);
    await prefs.setStringList('parental_allowed_contacts', _allowedContacts);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ إعدادات الرقابة الأبوية'),
          backgroundColor: AppTheme.privooSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setPinCode() async {
    final controller = TextEditingController();
    final confirmedController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعيين رمز PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'رمز PIN (4 أرقام)',
                hintText: '****',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmedController,
              decoration: const InputDecoration(
                labelText: 'تأكيد رمز PIN',
                hintText: '****',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == confirmedController.text && controller.text.length == 4) {
                _pinCode = controller.text;
                _isPinSet = true;
                _saveSettings();
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('الرمز غير متطابق أو غير صحيح')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرقابة الأبوية'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ تفعيل الرقابة الأبوية
            _buildSwitchCard(
              icon: Icons.family_restroom,
              title: 'تفعيل الرقابة الأبوية',
              subtitle: 'تقييد المحتوى وإدارة وقت الاستخدام',
              value: _isEnabled,
              onChanged: (value) {
                setState(() => _isEnabled = value);
                _saveSettings();
              },
              color: Colors.purple,
            ),
            
            if (_isEnabled) ...[
              const SizedBox(height: 16),
              
              // ✅ حماية بكلمة مرور
              _buildPinSection(),
              const SizedBox(height: 16),
              
              // ✅ تصفية المحتوى
              _buildFilterCard(),
              const SizedBox(height: 16),
              
              // ✅ تحديد وقت الاستخدام
              _buildTimeLimitCard(),
              const SizedBox(height: 16),
              
              // ✅ قائمة جهات الاتصال المسموح بها
              _buildAllowedContactsCard(),
              const SizedBox(height: 16),
              
              // ✅ نشاط الطفل
              _buildActivityCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildPinSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_outline, color: Colors.orange, size: 28),
            ),
            title: const Text(
              'حماية بكلمة مرور',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _isPinSet ? '✓ تم تعيين رمز PIN' : 'لم يتم تعيين رمز PIN بعد',
              style: TextStyle(color: _isPinSet ? Colors.green : Colors.red),
            ),
            trailing: ElevatedButton(
              onPressed: _setPinCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPinSet ? Colors.green : Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(_isPinSet ? 'تغيير' : 'تعيين'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'تصفية المحتوى',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            value: _blockAdultContent,
            onChanged: _isEnabled ? (value) {
              setState(() => _blockAdultContent = value);
              _saveSettings();
            } : null,
            title: const Text('حظر المحتوى الإباحي'),
            subtitle: const Text('منع المحتوى غير المناسب'),
          ),
          SwitchListTile(
            value: _blockViolence,
            onChanged: _isEnabled ? (value) {
              setState(() => _blockViolence = value);
              _saveSettings();
            } : null,
            title: const Text('حظر محتوى العنف'),
          ),
          SwitchListTile(
            value: _blockHateSpeech,
            onChanged: _isEnabled ? (value) {
              setState(() => _blockHateSpeech = value);
              _saveSettings();
            } : null,
            title: const Text('حظر خطاب الكراهية'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLimitCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _limitScreenTime,
            onChanged: _isEnabled ? (value) {
              setState(() => _limitScreenTime = value);
              _saveSettings();
            } : null,
            secondary: const Icon(Icons.timer_outlined, color: Colors.teal),
            title: const Text('تحديد وقت الاستخدام اليومي'),
          ),
          if (_limitScreenTime && _isEnabled)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الحد اليومي:'),
                      Text(
                        '$_dailyLimitMinutes دقيقة',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _dailyLimitMinutes.toDouble(),
                    min: 30,
                    max: 240,
                    divisions: 7,
                    activeColor: AppTheme.privooGold,
                    onChanged: (value) {
                      setState(() => _dailyLimitMinutes = value.toInt());
                      _saveSettings();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم إشعار الطفل عند انتهاء الوقت',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllowedContactsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.contact_phone, color: Colors.green, size: 28),
            ),
            title: const Text(
              'جهات الاتصال المسموح بها',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${_allowedContacts.length} جهة اتصال مسموحة'),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _isEnabled ? () => _addAllowedContact() : null,
            ),
          ),
          if (_allowedContacts.isNotEmpty)
            ..._allowedContacts.map((contact) => ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person, size: 18),
              ),
              title: Text(contact),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _allowedContacts.remove(contact);
                    _saveSettings();
                  });
                },
              ),
            )),
        ],
      ),
    );
  }

  Future<void> _addAllowedContact() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جهة اتصال مسموحة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم جهة الاتصال أو رقم الهاتف',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _allowedContacts.add(result);
        _saveSettings();
      });
    }
  }

  Widget _buildActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.analytics_outlined, color: Colors.purple, size: 28),
        ),
        title: const Text('نشاط الطفل'),
        subtitle: const Text('عرض تقارير الاستخدام'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // فتح شاشة النشاط
        },
      ),
    );
  }
}