import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/supplier.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';

class SupplierRepository {
  final DatabaseHelper _databaseHelper;

  SupplierRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await _databaseHelper.database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    return result.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<Supplier> addSupplier(Supplier supplier) async {
    final db = await _databaseHelper.database;

    if (AppConstants.isDemo) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM suppliers');
      final count = result.first['count'] as int;
      if (count >= 5) {
        throw Exception('Anda telah melebihi batas master supplier aplikasi demo, silakan beli hubungi Sales Kreatif atau ke 081932701147');
      }
    }

    final id = await db.insert('suppliers', {
      ...supplier.toMap(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }..remove('id')); // Let DB generate ID

    return supplier.copyWith(id: id);
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'suppliers',
      {
        ...supplier.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
