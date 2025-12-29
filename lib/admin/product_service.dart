import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'category_service.dart';

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _categoriesCollection = 'categories';
  static const String _productsSubcollection = 'products';

  
  static CollectionReference _getProductsCollection(String categoryName) {
    final sanitizedCategoryName = CategoryService.sanitizeCategoryName(categoryName);
    return _firestore
        .collection(_categoriesCollection)
        .doc(sanitizedCategoryName)
        .collection(_productsSubcollection);
  }

  
  static Stream<List<ProductModel>> getProductsStream() {
    
    return _firestore
        .collection(_categoriesCollection)
        .snapshots()
        .asyncExpand((categoriesSnapshot) {
      if (categoriesSnapshot.docs.isEmpty) {
        return Stream.value(<ProductModel>[]);
      }
      
      
      final streams = categoriesSnapshot.docs.map((categoryDoc) {
        return categoryDoc.reference
            .collection(_productsSubcollection)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.id, doc.data());
          }).toList();
        });
      });
      
      
      return _combineProductStreams(streams.toList());
    });
  }

  
  static Stream<List<ProductModel>> _combineProductStreams(
    List<Stream<List<ProductModel>>> streams,
  ) {
    if (streams.isEmpty) {
      return Stream.value(<ProductModel>[]);
    }
    
    final controller = StreamController<List<ProductModel>>.broadcast();
    final Map<int, List<ProductModel>> streamData = {};
    final List<StreamSubscription> subscriptions = [];
    int streamIndex = 0;
    
    void emitCombined() {
      
      final allProducts = <ProductModel>[];
      for (var productsList in streamData.values) {
        allProducts.addAll(productsList);
      }
      
      
      allProducts.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(1970);
        final bTime = b.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      if (!controller.isClosed) {
        controller.add(allProducts);
      }
    }
    
    for (var stream in streams) {
      final index = streamIndex++;
      streamData[index] = [];
      
      final subscription = stream.listen(
        (products) {
          streamData[index] = products;
          emitCombined();
        },
        onError: (error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
      );
      
      subscriptions.add(subscription);
    }
    
    
    controller.onCancel = () {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    };
    
    return controller.stream;
  }

  
  static Stream<List<ProductModel>> getProductsByCategoryStream(String categoryName) {
    return _getProductsCollection(categoryName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  
  static Future<List<ProductModel>> getProducts() async {
    try {
      final categoriesSnapshot = await _firestore
          .collection(_categoriesCollection)
          .get()
          .timeout(const Duration(seconds: 10));

      final allProducts = <ProductModel>[];
      
      for (var categoryDoc in categoriesSnapshot.docs) {
        final productsSnapshot = await categoryDoc.reference
            .collection(_productsSubcollection)
            .orderBy('createdAt', descending: true)
            .get()
            .timeout(const Duration(seconds: 10));
        
        allProducts.addAll(
          productsSnapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.id, doc.data());
          }),
        );
      }
      
      
      allProducts.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(1970);
        final bTime = b.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      return allProducts;
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  
  static Future<List<ProductModel>> getProductsByCategory(String categoryName) async {
    try {
      final querySnapshot = await _getProductsCollection(categoryName)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      return querySnapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      return [];
    }
  }

  
  static Future<String?> addProduct({
    required String name,
    required String description,
    required double originalPrice,
    required double price,
    required double discount,
    required String categoryName,
    String? imageUrl,
    List<String>? imageUrls,
    int stock = 1,
    bool isActive = true,
    bool isRecommended = false,
  }) async {
    try {
      final productData = {
        'name': name,
        'description': description,
        'originalPrice': originalPrice,
        'price': price,
        'discount': discount,
        'categoryName': categoryName, 
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl, 
        if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls, 
        'stock': stock,
        'isActive': isActive,
        'isRecommended': isRecommended,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _getProductsCollection(categoryName)
          .add(productData)
          .timeout(const Duration(seconds: 10));

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding product: $e');
      String errorMessage = 'Failed to add product';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission-denied') || 
          errorString.contains('permission denied')) {
        errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else if (errorString.contains('unable to establish connection') || 
                 errorString.contains('connection') ||
                 errorString.contains('channel')) {
        errorMessage = 'Cannot connect to Firestore. Please ensure Firestore is enabled in Firebase Console.';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      throw Exception(errorMessage);
    }
  }

  
  
  static Future<bool> updateProduct({
    required String id,
    required String name,
    required String description,
    required double originalPrice,
    required double price,
    required double discount,
    required String categoryName,
    required String oldCategoryName, 
    String? imageUrl,
    List<String>? imageUrls,
    int? stock,
    bool? isActive,
    bool? isRecommended,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
        'originalPrice': originalPrice,
        'price': price,
        'discount': discount,
        'categoryName': categoryName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl; 
      }
      if (imageUrls != null) {
        if (imageUrls.isNotEmpty) {
          updateData['imageUrls'] = imageUrls; 
        } else {
          updateData['imageUrls'] = FieldValue.delete(); 
        }
      }
      if (stock != null) {
        updateData['stock'] = stock;
      }
      if (isActive != null) {
        updateData['isActive'] = isActive;
      }
      if (isRecommended != null) {
        updateData['isRecommended'] = isRecommended;
      }

      
      if (oldCategoryName != categoryName) {
        
        final oldProductsRef = _getProductsCollection(oldCategoryName);
        final oldProductDoc = await oldProductsRef.doc(id).get().timeout(const Duration(seconds: 10));
        
        if (!oldProductDoc.exists) {
          throw Exception('Product not found in old category');
        }

        
        final newProductsRef = _getProductsCollection(categoryName);
        await newProductsRef.doc(id).set({
          ...oldProductDoc.data() as Map<String, dynamic>,
          ...updateData,
        }).timeout(const Duration(seconds: 10));

        
        await oldProductsRef.doc(id).delete().timeout(const Duration(seconds: 10));
      } else {
        
        await _getProductsCollection(categoryName)
            .doc(id)
            .update(updateData)
            .timeout(const Duration(seconds: 10));
      }

      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      String errorMessage = 'Failed to update product';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission-denied') || 
          errorString.contains('permission denied')) {
        errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else if (errorString.contains('unable to establish connection') || 
                 errorString.contains('connection') ||
                 errorString.contains('channel')) {
        errorMessage = 'Cannot connect to Firestore. Please ensure Firestore is enabled in Firebase Console.';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      throw Exception(errorMessage);
    }
  }

  
  static Future<bool> deleteProduct(String id, String categoryName) async {
    try {
      await _getProductsCollection(categoryName)
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      String errorMessage = 'Failed to delete product';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission-denied') || 
          errorString.contains('permission denied')) {
        errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else if (errorString.contains('unable to establish connection') || 
                 errorString.contains('connection') ||
                 errorString.contains('channel')) {
        errorMessage = 'Cannot connect to Firestore. Please ensure Firestore is enabled in Firebase Console.';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      throw Exception(errorMessage);
    }
  }

  
  static Future<int> getProductCount() async {
    try {
      final categoriesSnapshot = await _firestore
          .collection(_categoriesCollection)
          .get()
          .timeout(const Duration(seconds: 10));

      int totalCount = 0;
      
      for (var categoryDoc in categoriesSnapshot.docs) {
        final countSnapshot = await categoryDoc.reference
            .collection(_productsSubcollection)
            .count()
            .get()
            .timeout(const Duration(seconds: 10));
        
        totalCount += countSnapshot.count ?? 0;
      }
      
      return totalCount;
    } catch (e) {
      debugPrint('Error getting product count: $e');
      return 0;
    }
  }
}

