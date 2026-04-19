import 'package:sqflite/sqflite.dart';
import 'package:kreatif_pos/data/database/database_helper.dart';
import 'package:kreatif_pos/data/models/product.dart';
import 'package:kreatif_pos/data/models/product_unit.dart';
import 'package:kreatif_pos/core/constants/app_constants.dart';

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
        whereClause += ' AND (name LIKE ? OR barcode LIKE ?)';
      } else {
        whereClause = '(name LIKE ? OR barcode LIKE ?)';
      }
      final queryParam = '%$query%';
      whereArgs.add(queryParam);
      whereArgs.add(queryParam);
    }

    final List<Map<String, dynamic>> productMaps = await db.query(
      'products',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    List<Product> products = [];
    for (var pMap in productMaps) {
      final unitMaps = await db.query('product_units', where: 'product_id = ?', whereArgs: [pMap['id']]);
      final units = unitMaps.map((u) => ProductUnit.fromMap(u)).toList();
      products.add(Product.fromMap({...pMap, 'units': units}));
    }

    return products;
  }

  Future<Product?> getProductById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final unitMaps = await db.query('product_units', where: 'product_id = ?', whereArgs: [id]);
      final units = unitMaps.map((u) => ProductUnit.fromMap(u)).toList();
      return Product.fromMap({...maps.first, 'units': units});
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
      final id = maps.first['id'];
      final unitMaps = await db.query('product_units', where: 'product_id = ?', whereArgs: [id]);
      final units = unitMaps.map((u) => ProductUnit.fromMap(u)).toList();
      return Product.fromMap({...maps.first, 'units': units});
    }
    return null;
  }

  Future<int> addProduct(Product product) async {
    final db = await _databaseHelper.database;
    if (AppConstants.isDemo) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final count = result.first['count'] as int;
      if (count >= 15) { // Increased limit for demo
        throw Exception('Anda telah melebihi batas master item aplikasi demo');
      }
    }
    
    return await db.transaction((txn) async {
      final productId = await txn.insert('products', product.toMap());
      for (var unit in product.units) {
        await txn.insert('product_units', unit.copyWith(productId: productId).toMap());
      }
      return productId;
    });
  }

  Future<int> updateProduct(Product product) async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      final rows = await txn.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      final List<Map<String, dynamic>> existingUnitMaps = await txn.query(
        'product_units',
        where: 'product_id = ?',
        whereArgs: [product.id],
      );
      
      final existingIds = existingUnitMaps.map((m) => m['id'] as int).toSet();
      final newIds = product.units.where((u) => u.id != null).map((u) => u.id!).toSet();

      for (final id in existingIds) {
        if (!newIds.contains(id)) {
          await txn.delete('product_units', where: 'id = ?', whereArgs: [id]);
        }
      }

      for (var unit in product.units) {
        if (unit.id != null && existingIds.contains(unit.id)) {
          await txn.update(
            'product_units',
            unit.toMap(),
            where: 'id = ?',
            whereArgs: [unit.id],
          );
        } else {
          await txn.insert('product_units', unit.copyWith(productId: product.id).toMap());
        }
      }
      return rows;
    });
  }

  Future<int> deleteProduct(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStock(int productId, double quantityChange, {int? unitId}) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      if (unitId != null) {
        if (quantityChange < 0) {
          await _deductStockRecursive(txn, productId, unitId, quantityChange.abs());
        } else {
          await txn.rawUpdate(
            'UPDATE product_units SET stock = stock + ? WHERE id = ?',
            [quantityChange, unitId],
          );
        }
      } else {
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
          [quantityChange, DateTime.now().toIso8601String(), productId],
        );
      }
    });
  }

  Future<void> _deductStockRecursive(Transaction txn, int productId, int unitId, double amountToDeduct) async {
    final List<Map<String, dynamic>> units = await txn.query('product_units', where: 'id = ?', whereArgs: [unitId]);
    if (units.isEmpty) return;
    
    final unit = ProductUnit.fromMap(units.first);
    double currentStock = unit.stock;

    if (currentStock >= amountToDeduct) {
      await txn.update('product_units', {'stock': currentStock - amountToDeduct}, where: 'id = ?', whereArgs: [unitId]);
    } else {
      if (unit.parentUnitId != null) {
        double neededFromParent = ((amountToDeduct - currentStock) / unit.multiplier).ceilToDouble();
        await _deductStockRecursive(txn, productId, unit.parentUnitId!, neededFromParent);
        
        await txn.insert('unit_conversions', {
          'product_id': productId,
          'from_unit_id': unit.parentUnitId,
          'to_unit_id': unitId,
          'qty_changed': neededFromParent * unit.multiplier,
          'type': 'auto',
        });

        final updatedUnits = await txn.query('product_units', where: 'id = ?', whereArgs: [unitId]);
        final updatedStock = (updatedUnits.first['stock'] as num).toDouble() + (neededFromParent * unit.multiplier);
        await txn.update('product_units', {'stock': updatedStock - amountToDeduct}, where: 'id = ?', whereArgs: [unitId]);
      } else {
        await txn.update('product_units', {'stock': currentStock - amountToDeduct}, where: 'id = ?', whereArgs: [unitId]);
      }
    }
  }

  Future<void> convertUnit({
    required int productId,
    required int fromUnitId,
    required int toUnitId,
    required double fromQty,
    required double multiplier,
  }) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE product_units SET stock = stock - ? WHERE id = ?', [fromQty, fromUnitId]);
      await txn.rawUpdate('UPDATE product_units SET stock = stock + ? WHERE id = ?', [fromQty * multiplier, toUnitId]);
      await txn.insert('unit_conversions', {
        'product_id': productId,
        'from_unit_id': fromUnitId,
        'to_unit_id': toUnitId,
        'qty_changed': fromQty * multiplier,
        'type': 'manual',
      });
    });
  }
}
