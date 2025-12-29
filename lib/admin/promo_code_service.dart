import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/promo_code_model.dart';

class PromoCodeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'promoCodes';

  
  static Stream<List<PromoCodeModel>> getPromoCodesStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PromoCodeModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  
  static Future<List<PromoCodeModel>> getPromoCodes() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PromoCodeModel.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting promo codes: $e');
      return [];
    }
  }

  
  static Future<String> addPromoCode({
    required String code,
    required double discountValue,
    required bool isPercentage,
    bool isActive = true,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    try {
      final now = DateTime.now();
      final promoCode = PromoCodeModel(
        code: code.toUpperCase().trim(),
        discountValue: discountValue,
        isPercentage: isPercentage,
        isActive: isActive,
        validFrom: validFrom,
        validUntil: validUntil,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(promoCode.toMap());
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding promo code: $e');
      rethrow;
    }
  }

  
  static Future<void> updatePromoCode({
    required String id,
    required String code,
    required double discountValue,
    required bool isPercentage,
    required bool isActive,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'code': code.toUpperCase().trim(),
        'discountValue': discountValue,
        'isPercentage': isPercentage,
        'isActive': isActive,
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating promo code: $e');
      rethrow;
    }
  }

  
  static Future<void> deletePromoCode(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting promo code: $e');
      rethrow;
    }
  }

  
  static Future<bool> promoCodeExists(String code) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('code', isEqualTo: code.toUpperCase().trim())
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking promo code: $e');
      return false;
    }
  }

  
  static Future<PromoCodeModel?> getPromoCodeByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('code', isEqualTo: code.toUpperCase().trim())
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = snapshot.docs.first;
      final data = doc.data();
      return PromoCodeModel.fromMap(doc.id, data);
    } catch (e) {
      debugPrint('Error getting promo code: $e');
      return null;
    }
  }
}

