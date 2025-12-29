import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CartService {
  static Database? _database;
  static const String _tableName = 'cart';

  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  
  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'cart.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            productId TEXT PRIMARY KEY,
            quantity INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
  }

  
  static Future<bool> addToCart(String productId, {int quantity = 1}) async {
    try {
      final db = await database;
      
      
      final existing = await db.query(
        _tableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      
      if (existing.isNotEmpty) {
        
        final currentQuantity = existing.first['quantity'] as int;
        await db.update(
          _tableName,
          {'quantity': currentQuantity + quantity},
          where: 'productId = ?',
          whereArgs: [productId],
        );
      } else {
        
        await db.insert(
          _tableName,
          {'productId': productId, 'quantity': quantity},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      return false;
    }
  }

  
  static Future<bool> removeFromCart(String productId) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      return true;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }

  
  static Future<bool> updateQuantity(String productId, int quantity) async {
    try {
      final db = await database;
      if (quantity <= 0) {
        
        return await removeFromCart(productId);
      }
      await db.update(
        _tableName,
        {'quantity': quantity},
        where: 'productId = ?',
        whereArgs: [productId],
      );
      return true;
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      return false;
    }
  }

  
  static Future<bool> isInCart(String productId) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking cart: $e');
      return false;
    }
  }

  
  static Future<int> getQuantity(String productId) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      if (result.isEmpty) return 0;
      return result.first['quantity'] as int;
    } catch (e) {
      debugPrint('Error getting quantity: $e');
      return 0;
    }
  }

  
  static Future<Map<String, int>> getCartItems() async {
    try {
      final db = await database;
      final result = await db.query(_tableName);
      final Map<String, int> items = {};
      for (var row in result) {
        items[row['productId'] as String] = row['quantity'] as int;
      }
      return items;
    } catch (e) {
      debugPrint('Error getting cart items: $e');
      return {};
    }
  }

  
  static Future<List<String>> getCartProductIds() async {
    try {
      final db = await database;
      final result = await db.query(_tableName);
      return result.map((row) => row['productId'] as String).toList();
    } catch (e) {
      debugPrint('Error getting cart product IDs: $e');
      return [];
    }
  }

  
  static Stream<Map<String, int>> getCartStream() {
    return Stream.periodic(const Duration(milliseconds: 500), (_) async {
      return await getCartItems();
    }).asyncMap((future) => future);
  }

  
  static Future<bool> clearCart() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      return true;
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      return false;
    }
  }

  
  static Future<int> getTotalItemsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(quantity) as total FROM $_tableName');
      if (result.isEmpty || result.first['total'] == null) return 0;
      return result.first['total'] as int;
    } catch (e) {
      debugPrint('Error getting total items count: $e');
      return 0;
    }
  }
}

