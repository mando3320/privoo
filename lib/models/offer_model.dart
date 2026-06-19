// lib/models/offer_model.dart
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

  factory OfferModel.fromSupabase(Map<String, dynamic> data) {
    return OfferModel(
      id: data['id'] ?? '',
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] == 'OfferType.percentage' ? OfferType.percentage : OfferType.fixed,
      value: (data['value'] ?? 0).toDouble(),
      startDate: data['start_date'] != null 
          ? DateTime.tryParse(data['start_date']) ?? DateTime.now()
          : DateTime.now(),
      endDate: data['end_date'] != null 
          ? DateTime.tryParse(data['end_date']) ?? DateTime.now()
          : DateTime.now(),
      maxUses: data['max_uses'] ?? -1,
      currentUses: data['current_uses'] ?? 0,
      usedBy: List<String>.from(data['used_by'] ?? []),
      isActive: data['is_active'] ?? true,
      targetPlan: data['target_plan'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'code': code.toUpperCase(),
      'title': title,
      'description': description,
      'type': type.toString(),
      'value': value,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'max_uses': maxUses,
      'current_uses': currentUses,
      'used_by': usedBy,
      'is_active': isActive,
      'target_plan': targetPlan,
    };
  }
}