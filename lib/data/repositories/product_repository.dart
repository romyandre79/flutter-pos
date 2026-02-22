import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/product.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper;

  ProductRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<Product>> getProducts({ProductType? type, bool activeOnly = true, String? query}) async {
    final db = await _databaseHelper.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause = 'is_active = 1';
    }

    if (type != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND type = ?';
      } else {
        whereClause = 'type = ?';
      }
      whereArgs.add(type.value);
    }

    if (query != null && query.isNotEmpty) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND (name LIKE ? OR barcode = ?)';
      } else {
        whereClause = '(name LIKE ? OR barcode = ?)';
      }
      whereArgs.add('%$query%');
      whereArgs.add(query);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }
  
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> addProduct(Product product) async {
    final db = await _databaseHelper.database;
    if (AppConstants.isDemo) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final count = result.first['count'] as int;
      if (count >= 5) {
        throw Exception('Anda telah melebihi batas master item aplikasi demo, silakan beli hubungi Sales Kreatif atau ke 081932701147');
      }
    }
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _databaseHelper.database;
    // Soft delete: set is_active to 0
    return await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> hardDeleteProduct(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<void> updateStock(int productId, int quantityChange) async {
    final db = await _databaseHelper.database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
      [quantityChange, DateTime.now().toIso8601String(), productId],
    );
  }
}
