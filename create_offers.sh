#!/bin/bash

# إنشاء المجلدات لو مش موجودة
mkdir -p lib/models lib/services lib/views/admin

# 1. ملف نموذج البيانات
cat > lib/models/offer_model.dart << 'EOF'
// lib/models/offer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferType { percentage, fixed }

class OfferModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final OfferType type;
  final double value;
  final DateTime startDate;
  final DateTime endDate;
  final int maxUses;
  final int currentUses;
  final List<String> usedBy;
  final bool isActive;
  final String? targetPlan;

  OfferModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    this.maxUses = -1,
    this.currentUses = 0,
    this.usedBy = const [],
    this.isActive = true,
    this.targetPlan,
  });

  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (maxUses == -1 || currentUses < maxUses);
  }

  double applyDiscount(double originalPrice) {
    if (!isValid) return originalPrice;
    if (type == OfferType.percentage) {
      return originalPrice * (1 - value / 100);
    } else {
      return (originalPrice - value).clamp(0, originalPrice);
    }
  }

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: OfferType.values.firstWhere((e) => e.toString() == data['type']),
      value: (data['value'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      maxUses: data['maxUses'] ?? -1,
      currentUses: data['currentUses'] ?? 0,
      usedBy: List<String>.from(data['usedBy'] ?? []),
      isActive: data['isActive'] ?? true,
      targetPlan: data['targetPlan'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code.toUpperCase(),
      'title': title,
      'description': description,
      'type': type.toString(),
      'value': value,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'usedBy': usedBy,
      'isActive': isActive,
      'targetPlan': targetPlan,
    };
  }
}
EOF

# 2. ملف الخدمة
cat > lib/services/offer_service.dart << 'EOF'
// lib/services/offer_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<OfferModel?> validateCoupon(String code, {String? plan}) async {
    final snapshot = await _firestore
        .collection('offers')
        .where('code', isEqualTo: code.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final offer = OfferModel.fromFirestore(snapshot.docs.first);
    if (!offer.isValid) return null;
    if (offer.targetPlan != null && offer.targetPlan != plan) return null;

    return offer;
  }

  Future<bool> redeemCoupon(String userId, String couponCode) async {
    final snapshot = await _firestore
        .collection('offers')
        .where('code', isEqualTo: couponCode.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final doc = snapshot.docs.first;
    final offer = OfferModel.fromFirestore(doc);

    if (!offer.isValid) return false;
    if (offer.usedBy.contains(userId)) return false;

    await doc.reference.update({
      'currentUses': FieldValue.increment(1),
      'usedBy': FieldValue.arrayUnion([userId]),
    });

    return true;
  }

  Stream<List<OfferModel>> getActiveOffers() {
    return _firestore
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OfferModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<OfferModel>> getAllOffers() {
    return _firestore
        .collection('offers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OfferModel.fromFirestore(doc))
            .toList());
  }

  Future<void> createOffer(OfferModel offer) async {
    await _firestore.collection('offers').add({
      ...offer.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOffer(String id, Map<String, dynamic> data) async {
    await _firestore.collection('offers').doc(id).update(data);
  }

  Future<void> deleteOffer(String id) async {
    await _firestore.collection('offers').doc(id).delete();
  }
}

final offerServiceProvider = Provider<OfferService>((ref) => OfferService());
EOF

# 3. ملف إدارة العروض للمشرفين
cat > lib/views/admin/manage_offers_screen.dart << 'EOF'
// lib/views/admin/manage_offers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/offer_service.dart';

class ManageOffersScreen extends ConsumerStatefulWidget {
  const ManageOffersScreen({super.key});

  @override
  ConsumerState<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends ConsumerState<ManageOffersScreen> {
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _maxUsesController = TextEditingController();

  OfferType _selectedType = OfferType.percentage;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _targetPlan;

  Future<void> _addOffer() async {
    if (_codeController.text.isEmpty || _titleController.text.isEmpty || _valueController.text.isEmpty) return;
    if (_startDate == null || _endDate == null) return;

    final offer = OfferModel(
      id: '',
      code: _codeController.text,
      title: _titleController.text,
      description: _descController.text,
      type: _selectedType,
      value: double.parse(_valueController.text),
      startDate: _startDate!,
      endDate: _endDate!,
      maxUses: int.tryParse(_maxUsesController.text) ?? -1,
    );

    await ref.read(offerServiceProvider).createOffer(offer);
    Navigator.pop(context);
    _clearForm();
  }

  void _clearForm() {
    _codeController.clear();
    _titleController.clear();
    _descController.clear();
    _valueController.clear();
    _maxUsesController.clear();
    _selectedType = OfferType.percentage;
    _startDate = null;
    _endDate = null;
    _targetPlan = null;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) _startDate = date;
        else _endDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offerServiceProvider).getAllOffers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العروض والكوبونات'),
        backgroundColor: Colors.deepPurple,
      ),
      body: offersAsync.when(
        data: (offers) => ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: offer.isValid ? Colors.green : Colors.red,
                  child: Text(offer.code.substring(0, 1)),
                ),
                title: Text('${offer.code} - ${offer.title}'),
                subtitle: Text(
                  '${offer.type == OfferType.percentage ? "${offer.value}%" : "${offer.value} ج.م"} | استخدم: ${offer.currentUses}/${offer.maxUses == -1 ? '∞' : offer.maxUses}\n${offer.startDate.day}/${offer.startDate.month} → ${offer.endDate.day}/${offer.endDate.month}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => ref.read(offerServiceProvider).deleteOffer(offer.id),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة عرض'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عرض جديد'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'الكود *')),
                TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'العنوان *')),
                TextField(controller: _descController, decoration: const InputDecoration(labelText: 'الوصف')),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<OfferType>(
                        value: _selectedType,
                        items: const [
                          DropdownMenuItem(value: OfferType.percentage, child: Text('نسبة مئوية %')),
                          DropdownMenuItem(value: OfferType.fixed, child: Text('قيمة ثابتة ج.م')),
                        ],
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _valueController,
                        decoration: InputDecoration(labelText: _selectedType == OfferType.percentage ? 'النسبة % *' : 'القيمة ج.م *'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(_startDate == null ? 'بداية العرض' : 'من: ${_startDate!.day}/${_startDate!.month}'),
                        onTap: () => _selectDate(ctx, true),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(_endDate == null ? 'نهاية العرض' : 'إلى: ${_endDate!.day}/${_endDate!.month}'),
                        onTap: () => _selectDate(ctx, false),
                      ),
                    ),
                  ],
                ),
                TextField(controller: _maxUsesController, decoration: const InputDecoration(labelText: 'الحد الأقصى للاستخدام (اتركه فارغاً لغير محدود)'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: _targetPlan,
                  decoration: const InputDecoration(labelText: 'خطة محددة (اختياري)'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                    DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
                    DropdownMenuItem(value: 'lifetime', child: Text('مدى الحياة')),
                  ],
                  onChanged: (v) => setState(() => _targetPlan = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: _addOffer, child: const Text('إضافة')),
        ],
      ),
    );
  }
}
EOF

echo "✅ تم إنشاء الملفات بنجاح!"
echo ""
echo "الملفات التي تم إنشاؤها:"
echo "  - lib/models/offer_model.dart"
echo "  - lib/services/offer_service.dart"
echo "  - lib/views/admin/manage_offers_screen.dart"