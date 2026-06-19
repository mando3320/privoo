// lib/services/offer_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/offer_model.dart';
import '../main.dart';

final offerServiceProvider = Provider<OfferService>((ref) {
  return OfferService();
});

class OfferService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createOffer(OfferModel offer) async {
    await _supabase.from('offers').insert({
      'code': offer.code,
      'title': offer.title,
      'description': offer.description,
      'type': offer.type.toString(),
      'value': offer.value,
      'start_date': offer.startDate.toIso8601String(),
      'end_date': offer.endDate.toIso8601String(),
      'max_uses': offer.maxUses,
      'target_plan': offer.targetPlan,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    });
    logger.i('✅ تم إنشاء العرض: ${offer.code}');
  }

  Future<OfferModel?> validateCoupon(String code) async {
    final response = await _supabase
        .from('offers')
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true)
        .maybeSingle();
    
    if (response == null) return null;
    
    final offer = OfferModel.fromSupabase(response);
    if (!offer.isValid) return null;
    
    return offer;
  }

  Future<void> redeemCoupon(String userId, String code) async {
    final offer = await validateCoupon(code);
    if (offer == null) throw Exception('كود غير صالح');

    // ✅ تحديث عدد الاستخدامات
    await _supabase
        .from('offers')
        .update({
          'current_uses': offer.currentUses + 1,
          'used_by': [...offer.usedBy, userId],
        })
        .eq('id', offer.id);
    
    logger.i('✅ تم استخدام الكوبون $code من قبل المستخدم $userId');
  }

  Stream<List<OfferModel>> getAllOffers() {
    return _supabase
        .from('offers')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((doc) => OfferModel.fromSupabase(doc)).toList();
        });
  }

  Future<void> deleteOffer(String id) async {
    await _supabase.from('offers').delete().eq('id', id);
    logger.i('✅ تم حذف العرض: $id');
  }
}