// lib/views/settings/parental_control_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_theme.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل حفظ الإعدادات: ${e.toString()}'),
            backgroundColor: AppTheme.privooError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                  const SnackBar(content: Text('❌ الرمز غير متطابق أو غير صحيح')),
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

  Future<void> _removePinCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة رمز PIN'),
        content: const Text('هل أنت متأكد من إزالة رمز PIN؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.privooError,
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _pinCode = '';
        _isPinSet = false;
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
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
              _buildPinSection(),
              const SizedBox(height: 16),
              _buildFilterCard(),
              const SizedBox(height: 16),
              _buildTimeLimitCard(),
              const SizedBox(height: 16),
              _buildAllowedContactsCard(),
              const SizedBox(height: 16),
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            title: const Text('حماية بكلمة مرور', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              _isPinSet ? '✓ تم تعيين رمز PIN' : 'لم يتم تعيين رمز PIN بعد',
              style: TextStyle(color: _isPinSet ? Colors.green : Colors.red),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isPinSet)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _removePinCode,
                    tooltip: 'إزالة PIN',
                  ),
                ElevatedButton(
                  onPressed: _setPinCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPinSet ? Colors.green : Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(_isPinSet ? 'تغيير' : 'تعيين'),
                ),
              ],
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
                Text('تصفية المحتوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'سيتم تطبيق هذه الإعدادات على جميع المحادثات',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
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
                      Text('$_dailyLimitMinutes دقيقة', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 8),
                  Text(
                    'الوقت المتبقي اليوم: ${_dailyLimitMinutes} دقيقة',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
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
            title: const Text('جهات الاتصال المسموح بها', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${_allowedContacts.length} جهة اتصال مسموحة',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _isEnabled ? () => _addAllowedContact() : null,
              tooltip: 'إضافة جهة اتصال',
            ),
          ),
          if (_allowedContacts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا توجد جهات اتصال مسموحة',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ..._allowedContacts.map((contact) => Dismissible(
              key: Key(contact),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف جهة اتصال'),
                    content: Text('هل أنت متأكد من حذف "$contact" من القائمة؟'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.privooError,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              onDismissed: (direction) {
                setState(() {
                  _allowedContacts.remove(contact);
                  _saveSettings();
                });
              },
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
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
                  tooltip: 'حذف',
                ),
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
            hintText: 'مثال: أحمد أو 01012345678',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('❌ الرجاء إدخال اسم أو رقم هاتف')),
                );
              }
            },
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
          _showActivityReportDialog();
        },
      ),
    );
  }

  void _showActivityReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نشاط الطفل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 وقت الاستخدام اليومي:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_dailyLimitMinutes} دقيقة'),
            const SizedBox(height: 16),
            const Text('👥 جهات الاتصال المسموحة:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_allowedContacts.isEmpty)
              Text(
                'لا توجد جهات اتصال مسموحة',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ..._allowedContacts.map((contact) => Text('• $contact')),
            const SizedBox(height: 16),
            const Text('🔒 المحتوى المحظور:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_blockAdultContent) Text('• المحتوى الإباحي'),
            if (_blockViolence) Text('• محتوى العنف'),
            if (_blockHateSpeech) Text('• خطاب الكراهية'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}