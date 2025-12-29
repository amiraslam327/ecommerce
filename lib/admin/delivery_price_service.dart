import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DeliveryPriceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'settings';
  static const String _documentId = 'delivery';

  
  static Future<double> getDeliveryPrice() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return (data['price'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0; 
    } catch (e) {
      debugPrint('Error getting delivery price: $e');
      return 0.0;
    }
  }

  
  static Stream<double> getDeliveryPriceStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_documentId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        return (data['price'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    });
  }

  
  static Future<void> setDeliveryPrice(double price) async {
    try {
      if (price < 0) {
        throw Exception('Delivery price cannot be negative');
      }

      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set({
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error setting delivery price: $e');
      rethrow;
    }
  }
}

