import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class WishlistService {
  static Database? _database;
  static const String _tableName = 'wishlist';

  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  
  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'wishlist.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            productId TEXT PRIMARY KEY
          )
        ''');
      },
    );
  }

  
  static Future<bool> addToWishlist(String productId) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        {'productId': productId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
      return false;
    }
  }

  
  static Future<bool> removeFromWishlist(String productId) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      return true;
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
      return false;
    }
  }

  
  static Future<bool> isInWishlist(String productId) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking wishlist: $e');
      return false;
    }
  }

  
  static Future<List<String>> getWishlistProductIds() async {
    try {
      final db = await database;
      final result = await db.query(_tableName);
      return result.map((row) => row['productId'] as String).toList();
    } catch (e) {
      debugPrint('Error getting wishlist: $e');
      return [];
    }
  }

  
  static Stream<List<String>> getWishlistStream() {
    return Stream.periodic(const Duration(milliseconds: 500), (_) async {
      return await getWishlistProductIds();
    }).asyncMap((future) => future);
  }

  
  static Future<bool> clearWishlist() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      return true;
    } catch (e) {
      debugPrint('Error clearing wishlist: $e');
      return false;
    }
  }
}

