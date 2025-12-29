import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_method_model.dart';

class PaymentMethodService {
  static final PaymentMethodService _instance = PaymentMethodService._internal();
  factory PaymentMethodService() => _instance;
  PaymentMethodService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'payment_methods.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payment_methods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        cardNumber TEXT NOT NULL,
        cardHolderName TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        cvv TEXT,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  Future<int> addPaymentMethod(PaymentMethodModel paymentMethod) async {
    final db = await database;
    
    
    if (paymentMethod.isDefault) {
      await db.update('payment_methods', {'isDefault': 0});
    }
    
    final now = DateTime.now();
    final methodWithTimestamps = paymentMethod.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    
    return await db.insert('payment_methods', methodWithTimestamps.toMap());
  }

  Future<List<PaymentMethodModel>> getAllPaymentMethods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      orderBy: 'isDefault DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => PaymentMethodModel.fromMap(maps[i]));
  }

  Future<PaymentMethodModel?> getDefaultPaymentMethod() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PaymentMethodModel.fromMap(maps.first);
  }

  Future<PaymentMethodModel?> getPaymentMethodById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PaymentMethodModel.fromMap(maps.first);
  }

  Future<int> updatePaymentMethod(PaymentMethodModel paymentMethod) async {
    final db = await database;
    
    
    if (paymentMethod.isDefault) {
      await db.update('payment_methods', {'isDefault': 0});
    }
    
    final now = DateTime.now();
    final methodWithTimestamps = paymentMethod.copyWith(
      updatedAt: now,
    );
    
    return await db.update(
      'payment_methods',
      methodWithTimestamps.toMap(),
      where: 'id = ?',
      whereArgs: [paymentMethod.id],
    );
  }

  Future<int> deletePaymentMethod(int id) async {
    final db = await database;
    return await db.delete(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> setDefaultPaymentMethod(int id) async {
    final db = await database;
    
    await db.update('payment_methods', {'isDefault': 0});
    
    return await db.update(
      'payment_methods',
      {'isDefault': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

