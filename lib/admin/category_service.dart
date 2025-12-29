import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'categories';

  
  
  static String sanitizeCategoryName(String name) {
    
    
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-.]'), '_')
        .replaceAll(RegExp(r'_+'), '_') 
        .replaceAll(RegExp(r'^_|_$'), ''); 
  }

  
  
  static Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        
        return CategoryModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  
  static Future<int> getCategoryCount() async {
    try {
      final countSnapshot = await _firestore
          .collection(_collection)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));
      
      return countSnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting category count: $e');
      return 0;
    }
  }

  
  
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .get()
          .timeout(const Duration(seconds: 10));

      return querySnapshot.docs.map((doc) {
        
        return CategoryModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  
  
  static Future<String?> addCategory({
    required String name,
    required String iconName,
    Map<String, dynamic>? iconData,
  }) async {
    try {
      
      final sanitizedId = sanitizeCategoryName(name);
      
      
      final docRef = _firestore.collection(_collection).doc(sanitizedId);
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 10));

      if (docSnapshot.exists) {
        throw Exception('Category with this name already exists');
      }

      
      await docRef.set({
        'name': name, 
        'iconName': iconName,
        if (iconData != null && iconData.isNotEmpty) 'iconData': iconData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      return sanitizedId; 
    } catch (e) {
      debugPrint('Error adding category: $e');
      String errorMessage = 'Failed to add category';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('already exists')) {
        errorMessage = 'Category with this name already exists';
      } else if (errorString.contains('permission-denied') || 
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

  
  
  static Future<bool> updateCategory({
    required String id, 
    required String name, 
    required String iconName,
    Map<String, dynamic>? iconData,
  }) async {
    try {
      final newSanitizedId = sanitizeCategoryName(name);
      final oldDocRef = _firestore.collection(_collection).doc(id);
      
      
      if (id != newSanitizedId) {
        final newDocRef = _firestore.collection(_collection).doc(newSanitizedId);
        final newDocSnapshot = await newDocRef.get().timeout(const Duration(seconds: 10));
        
        if (newDocSnapshot.exists) {
        throw Exception('Category with this name already exists');
      }

        
        final oldDocSnapshot = await oldDocRef.get().timeout(const Duration(seconds: 10));
        if (!oldDocSnapshot.exists) {
          throw Exception('Category not found');
        }

        
        await newDocRef.set({
          'name': name,
          'iconName': iconName,
          if (iconData != null && iconData.isNotEmpty) 'iconData': iconData,
          'createdAt': oldDocSnapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10));

        
        await oldDocRef.delete().timeout(const Duration(seconds: 10));
      } else {
        
      final updateData = <String, dynamic>{
        'name': name,
        'iconName': iconName,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (iconData != null && iconData.isNotEmpty) {
        updateData['iconData'] = iconData;
      }
        await oldDocRef.update(updateData).timeout(const Duration(seconds: 10));
      }

      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      String errorMessage = 'Failed to update category';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('already exists')) {
        errorMessage = 'Category with this name already exists';
      } else if (errorString.contains('not found')) {
        errorMessage = 'Category not found';
      } else if (errorString.contains('permission-denied') || 
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

  
  
  static Future<bool> deleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete()
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      String errorMessage = 'Failed to delete category';
      
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
}

