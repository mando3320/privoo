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
