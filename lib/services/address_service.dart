import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/address_model.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'addresses.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE addresses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        fullAddress TEXT NOT NULL,
        phone TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> addAddress(AddressModel address) async {
    final db = await database;
    
    
    if (address.isDefault) {
      await db.update('addresses', {'isDefault': 0});
    }
    
    return await db.insert('addresses', address.toMap());
  }

  Future<List<AddressModel>> getAllAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'addresses',
      orderBy: 'isDefault DESC, id DESC',
    );
    return List.generate(maps.length, (i) => AddressModel.fromMap(maps[i]));
  }

  Future<AddressModel?> getDefaultAddress() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'addresses',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AddressModel.fromMap(maps[0]);
  }

  Future<AddressModel?> getAddressById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return AddressModel.fromMap(maps[0]);
  }

  Future<int> updateAddress(AddressModel address) async {
    final db = await database;
    
    
    if (address.isDefault) {
      await db.update('addresses', {'isDefault': 0});
    }
    
    return await db.update(
      'addresses',
      address.toMap(),
      where: 'id = ?',
      whereArgs: [address.id],
    );
  }

  Future<int> deleteAddress(int id) async {
    final db = await database;
    return await db.delete(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> setDefaultAddress(int id) async {
    final db = await database;
    
    
    await db.update('addresses', {'isDefault': 0});
    
    
    return await db.update(
      'addresses',
      {'isDefault': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

