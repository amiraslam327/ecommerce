import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'orders';

  
  static String _getStatusCollection(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'cancelled') {
      return 'cancelled';
    } else if (statusLower == 'delivered' || statusLower == 'complete' || statusLower == 'completed') {
      return 'complete';
    } else {
      
      return 'pending';
    }
  }

  
  static Future<String?> saveOrder(OrderModel order) async {
    try {
      final orderMap = order.toMap();
      
      orderMap['createdAt'] = Timestamp.fromDate(order.createdAt);
      if (order.updatedAt != null) {
        orderMap['updatedAt'] = Timestamp.fromDate(order.updatedAt!);
      }
      
      
      final statusCollection = _getStatusCollection(order.status);
      
      final docRef = await _firestore
          .collection(_collectionName)
          .doc(statusCollection)
          .collection('items')
          .add(orderMap)
          .timeout(const Duration(seconds: 10));

      return docRef.id;
    } catch (e) {
      debugPrint('Error saving order: $e');
      rethrow;
    }
  }

  
  
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      debugPrint('Searching for order ID: $orderId');
      
      final statusCollections = ['pending', 'cancelled', 'complete'];
      
      for (final statusCollection in statusCollections) {
        debugPrint('Checking collection: orders/$statusCollection/items/$orderId');
        final doc = await _firestore
            .collection(_collectionName)
            .doc(statusCollection)
            .collection('items')
            .doc(orderId)
            .get()
            .timeout(const Duration(seconds: 10));

        if (doc.exists && doc.data() != null) {
          debugPrint('Order found in collection: $statusCollection');
          final data = doc.data()!;
          
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          return OrderModel.fromMap(doc.id, data);
        }
      }
      debugPrint('Order not found in any collection');
      return null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  
  
  
  static Stream<List<OrderModel>> getUserOrdersStream(String userId) {
    
    final statusCollections = ['pending', 'cancelled', 'complete'];
    final StreamController<List<OrderModel>> controller = StreamController<List<OrderModel>>.broadcast();
    final Map<String, OrderModel> ordersMap = {};
    final Map<String, Set<String>> collectionOrderIds = {}; 
    final List<StreamSubscription> subscriptions = [];
    
    
    for (final statusCollection in statusCollections) {
      collectionOrderIds[statusCollection] = <String>{};
      
      final subscription = _firestore
          .collection(_collectionName)
          .doc(statusCollection)
          .collection('items')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen(
        (snapshot) {
          
          final currentOrderIds = <String>{};
          
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            if (data['updatedAt'] is Timestamp) {
              data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
            }
            final order = OrderModel.fromMap(doc.id, data);
            ordersMap[doc.id] = order;
            currentOrderIds.add(doc.id);
          }
          
          
          final previousOrderIds = collectionOrderIds[statusCollection]!;
          for (final orderId in previousOrderIds) {
            if (!currentOrderIds.contains(orderId)) {
              ordersMap.remove(orderId);
            }
          }
          
          
          collectionOrderIds[statusCollection] = currentOrderIds;
          
          
          final allOrders = ordersMap.values.toList();
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          if (!controller.isClosed) {
            controller.add(allOrders);
          }
        },
        onError: (error) {
          debugPrint('Error in order stream for $statusCollection: $error');
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
      );
      
      subscriptions.add(subscription);
    }
    
    
    controller.onCancel = () {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      if (!controller.isClosed) {
        controller.close();
      }
    };
    
    return controller.stream;
  }

  
  
  
  static Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final statusCollections = ['pending', 'cancelled', 'complete'];
      final List<OrderModel> allOrders = [];

      for (final statusCollection in statusCollections) {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .doc(statusCollection)
            .collection('items')
            .where('userId', isEqualTo: userId)
            .get()
            .timeout(const Duration(seconds: 10));

        final orders = querySnapshot.docs.map((doc) {
          final data = doc.data();
          
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          return OrderModel.fromMap(doc.id, data);
        }).toList();

        allOrders.addAll(orders);
      }
      
      
      allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allOrders;
    } catch (e) {
      debugPrint('Error getting user orders: $e');
      return [];
    }
  }

  
  static Stream<List<OrderModel>> getAllOrdersStream() {
    
    final statusCollections = ['pending', 'cancelled', 'complete'];
    final StreamController<List<OrderModel>> controller = StreamController<List<OrderModel>>.broadcast();
    final Map<String, OrderModel> ordersMap = {};
    final Map<String, Set<String>> collectionOrderIds = {}; 
    final List<StreamSubscription> subscriptions = [];
    
    
    for (final statusCollection in statusCollections) {
      collectionOrderIds[statusCollection] = <String>{};
      
      final subscription = _firestore
          .collection(_collectionName)
          .doc(statusCollection)
          .collection('items')
          .snapshots()
          .listen(
        (snapshot) {
          
          final currentOrderIds = <String>{};
          
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            if (data['updatedAt'] is Timestamp) {
              data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
            }
            final order = OrderModel.fromMap(doc.id, data);
            ordersMap[doc.id] = order;
            currentOrderIds.add(doc.id);
          }
          
          
          final previousOrderIds = collectionOrderIds[statusCollection]!;
          for (final orderId in previousOrderIds) {
            if (!currentOrderIds.contains(orderId)) {
              ordersMap.remove(orderId);
            }
          }
          
          
          collectionOrderIds[statusCollection] = currentOrderIds;
          
          
          final allOrders = ordersMap.values.toList();
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          if (!controller.isClosed) {
            controller.add(allOrders);
          }
        },
        onError: (error) {
          debugPrint('Error in order stream for $statusCollection: $error');
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
      );
      
      subscriptions.add(subscription);
    }
    
    
    controller.onCancel = () {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      if (!controller.isClosed) {
        controller.close();
      }
    };
    
    return controller.stream;
  }

  
  static Future<List<OrderModel>> getAllOrders() async {
    try {
      final statusCollections = ['pending', 'cancelled', 'complete'];
      final List<OrderModel> allOrders = [];

      for (final statusCollection in statusCollections) {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .doc(statusCollection)
            .collection('items')
            .get()
            .timeout(const Duration(seconds: 10));

        final orders = querySnapshot.docs.map((doc) {
          final data = doc.data();
          
          if (data['createdAt'] is Timestamp) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          if (data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
          }
          return OrderModel.fromMap(doc.id, data);
        }).toList();

        allOrders.addAll(orders);
      }
      
      
      allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allOrders;
    } catch (e) {
      debugPrint('Error getting all orders: $e');
      return [];
    }
  }

  
  static Future<bool> updateOrderStatus(String orderId, String oldStatus, String newStatus) async {
    try {
      
      final oldStatusCollection = _getStatusCollection(oldStatus);
      final orderDoc = await _firestore
          .collection(_collectionName)
          .doc(oldStatusCollection)
          .collection('items')
          .doc(orderId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!orderDoc.exists) {
        debugPrint('Order not found in old status collection');
        return false;
      }

      final orderData = orderDoc.data()!;
      
      
      orderData['status'] = newStatus;
      orderData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      
      final newStatusCollection = _getStatusCollection(newStatus);

      
      if (oldStatusCollection != newStatusCollection) {
        
        await _firestore
            .collection(_collectionName)
            .doc(newStatusCollection)
            .collection('items')
            .doc(orderId)
            .set(orderData)
            .timeout(const Duration(seconds: 10));

        
        await _firestore
            .collection(_collectionName)
            .doc(oldStatusCollection)
            .collection('items')
            .doc(orderId)
            .delete()
            .timeout(const Duration(seconds: 10));
      } else {
        
        await _firestore
            .collection(_collectionName)
            .doc(oldStatusCollection)
            .collection('items')
            .doc(orderId)
            .update(orderData)
            .timeout(const Duration(seconds: 10));
      }

      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  
  static Future<Map<String, int>> getOrderCounts() async {
    try {
      final Map<String, int> counts = {
        'total': 0,
        'pending': 0,
        'cancelled': 0,
        'complete': 0,
      };

      final statusCollections = ['pending', 'cancelled', 'complete'];
      
      for (final statusCollection in statusCollections) {
        final countSnapshot = await _firestore
            .collection(_collectionName)
            .doc(statusCollection)
            .collection('items')
            .count()
            .get()
            .timeout(const Duration(seconds: 10));
        
        final count = countSnapshot.count ?? 0;
        counts[statusCollection] = count;
        counts['total'] = counts['total']! + count;
      }
      
      return counts;
    } catch (e) {
      debugPrint('Error getting order counts: $e');
      return {
        'total': 0,
        'pending': 0,
        'cancelled': 0,
        'complete': 0,
      };
    }
  }
}
