import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_offer_model.dart';

class SpecialOfferService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'special_offers';

  
  
  
  static Stream<List<SpecialOfferModel>> getSpecialOffersStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) => SpecialOfferModel.fromMap(
                doc.id,
                doc.data(),
              ))
          .toList();
      
      
      offers.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate); 
      });
      
      return offers;
    });
  }

  
  static Future<List<SpecialOfferModel>> getSpecialOffers() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .get();

      final offers = snapshot.docs
          .map((doc) => SpecialOfferModel.fromMap(
                doc.id,
                doc.data(),
              ))
          .toList();
      
      
      offers.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate); 
      });
      
      return offers;
    } catch (e) {
      debugPrint('Error getting special offers: $e');
      return [];
    }
  }

  
  static Stream<List<SpecialOfferModel>> getActiveSpecialOffersStream() {
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map((doc) => SpecialOfferModel.fromMap(
                doc.id,
                doc.data(),
              ))
          .toList();
      
      
      offers.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate); 
      });
      
      return offers;
    });
  }

  
  static Future<String> addSpecialOffer(SpecialOfferModel offer) async {
    try {
      final now = DateTime.now();
      final offerWithTimestamps = offer.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(offerWithTimestamps.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding special offer: $e');
      rethrow;
    }
  }

  
  static Future<void> updateSpecialOffer(SpecialOfferModel offer) async {
    try {
      if (offer.id == null) {
        throw Exception('Offer ID is required for update');
      }

      final now = DateTime.now();
      final offerWithTimestamps = offer.copyWith(
        updatedAt: now,
      );

      await _firestore
          .collection(_collectionName)
          .doc(offer.id)
          .update(offerWithTimestamps.toMap());
    } catch (e) {
      debugPrint('Error updating special offer: $e');
      rethrow;
    }
  }

  
  static Future<void> deleteSpecialOffer(String offerId) async {
    try {
      await _firestore.collection(_collectionName).doc(offerId).delete();
    } catch (e) {
      debugPrint('Error deleting special offer: $e');
      rethrow;
    }
  }

  
  static Future<void> toggleActiveStatus(String offerId, bool isActive) async {
    try {
      await _firestore.collection(_collectionName).doc(offerId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error toggling active status: $e');
      rethrow;
    }
  }
}

