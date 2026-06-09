// lib/services/offer_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
