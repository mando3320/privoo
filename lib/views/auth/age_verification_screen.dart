// lib/views/auth/age_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/region_compliance_service.dart';

class AgeVerificationScreen extends ConsumerStatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback onUnderAge;
  const AgeVerificationScreen({super.key, required this.onVerified, required this.onUnderAge});

  @override
  ConsumerState<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends ConsumerState<AgeVerificationScreen> {
  String _selectedYear = '2000';
  String _selectedMonth = '1';
  String _selectedDay = '1';
  late List<String> _years, _months, _days;
  
  @override
  void initState() {
    super.initState();
    _years = List.generate(100, (i) => (DateTime.now().year - i).toString());
    _months = List.generate(12, (i) => (i + 1).toString());
    _days = List.generate(31, (i) => (i + 1).toString());
  }
  
  int _calculateAge() {
    final birthDate = DateTime(int.parse(_selectedYear), int.parse(_selectedMonth), int.parse(_selectedDay));
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age;
  }
  
  Future<void> _verifyAge() async {
    final age = _calculateAge();
    final region = await RegionComplianceService.getUserRegion();
    final requirements = RegionComplianceService.getRequirements(region);
    if (age >= requirements.minAge) {
      widget.onVerified();
    } else {
      widget.onUnderAge();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من العمر'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text('يرجى إدخال تاريخ ميلادك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('يجب أن يكون عمرك مساوياً أو أكبر من الحد الأدنى المطلوب للوصول إلى Privoo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,  // ⭐ غيرنا من initialValue إلى value
                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                    decoration: const InputDecoration(labelText: 'السنة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,  // ⭐ غيرنا من initialValue إلى value
                    items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                    decoration: const InputDecoration(labelText: 'الشهر'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDay,  // ⭐ غيرنا من initialValue إلى value
                    items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _selectedDay = v!),
                    decoration: const InputDecoration(labelText: 'اليوم'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _verifyAge, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('تحقق من العمر')),
          ],
        ),
      ),
    );
  }
}
