// lib/views/admin/manage_offers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/offer_service.dart';
import '../../models/offer_model.dart';

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

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _addOffer() async {
    if (_codeController.text.isEmpty || 
        _titleController.text.isEmpty || 
        _valueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ الرجاء ملء جميع الحقول المطلوبة')),
      );
      return;
    }
    
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ الرجاء اختيار تاريخ البداية والنهاية')),
      );
      return;
    }

    final offer = OfferModel(
      id: '',
      code: _codeController.text.toUpperCase(),
      title: _titleController.text,
      description: _descController.text,
      type: _selectedType,
      value: double.parse(_valueController.text),
      startDate: _startDate!,
      endDate: _endDate!,
      maxUses: int.tryParse(_maxUsesController.text) ?? -1,
      targetPlan: _targetPlan,
    );

    await ref.read(offerServiceProvider).createOffer(offer);
    Navigator.pop(context);
    _clearForm();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم إضافة العرض بنجاح')),
    );
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
      lastDate: DateTime.now().add(const Duration(days: 730)), // سنتين
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _deleteOffer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العرض؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await ref.read(offerServiceProvider).deleteOffer(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حذف العرض')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offersStream = ref.watch(offerServiceProvider).getAllOffers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العروض والكوبونات'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<List<OfferModel>>(
        stream: offersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          
          final offers = snapshot.data ?? [];
          
          if (offers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد عروض حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text('اضغط على زر + لإضافة عرض جديد'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final isExpired = offer.endDate.isBefore(DateTime.now());
              
              return Card(
                margin: const EdgeInsets.all(8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isExpired ? Colors.grey : Colors.green,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: offer.isValid ? Colors.green : Colors.grey,
                    child: Text(
                      offer.code.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    '${offer.code} - ${offer.title}',
                    style: TextStyle(
                      decoration: isExpired ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${offer.type == OfferType.percentage ? "${offer.value}%" : "${offer.value} ج.م"} | '
                        'استخدم: ${offer.currentUses}/${offer.maxUses == -1 ? '∞' : offer.maxUses}',
                      ),
                      Text(
                        '${offer.startDate.day}/${offer.startDate.month}/${offer.startDate.year} → '
                        '${offer.endDate.day}/${offer.endDate.month}/${offer.endDate.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (offer.targetPlan != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'لخطة: ${offer.targetPlan}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteOffer(offer.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة عرض'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _showAddDialog() {
    _clearForm();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة عرض جديد'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'الكود *',
                        hintText: 'مثال: PRIVOO50',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان *',
                        hintText: 'مثال: خصم 50% على الاشتراك',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        hintText: 'وصف العرض (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<OfferType>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'نوع الخصم *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: OfferType.percentage,
                                child: Text('نسبة مئوية %'),
                              ),
                              DropdownMenuItem(
                                value: OfferType.fixed,
                                child: Text('قيمة ثابتة ج.م'),
                              ),
                            ],
                            onChanged: (v) => setDialogState(() => _selectedType = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _valueController,
                            decoration: InputDecoration(
                              labelText: _selectedType == OfferType.percentage ? 'النسبة % *' : 'القيمة ج.م *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(_startDate == null ? 'بداية العرض *' : 'من: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (date != null) {
                                setDialogState(() => _startDate = date);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(_endDate == null ? 'نهاية العرض *' : 'إلى: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (date != null) {
                                setDialogState(() => _endDate = date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _maxUsesController,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأقصى للاستخدام (اتركه فارغاً لغير محدود)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _targetPlan,
                      decoration: const InputDecoration(
                        labelText: 'خطة محددة (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('كل الخطط')),
                        const DropdownMenuItem(value: 'daily', child: Text('يومي')),
                        const DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                        const DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
                        const DropdownMenuItem(value: 'lifetime', child: Text('مدى الحياة')),
                        const DropdownMenuItem(value: 'family', child: Text('عائلي')),
                        const DropdownMenuItem(value: 'student', child: Text('طلابي')),
                      ],
                      onChanged: (v) => setDialogState(() => _targetPlan = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: _addOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }
}