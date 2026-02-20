import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/unit.dart';

class UnitRepository {
  final DatabaseHelper _databaseHelper;

  UnitRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<Unit>> getUnits() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'units',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Unit.fromMap(maps[i]));
  }

  Future<int> addUnit(Unit unit) async {
    final db = await _databaseHelper.database;
    final unitWithDate = unit.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await db.insert('units', unitWithDate.toMap());
  }

  Future<int> updateUnit(Unit unit) async {
    final db = await _databaseHelper.database;
    final unitWithDate = unit.copyWith(
      updatedAt: DateTime.now(),
    );
    return await db.update(
      'units',
      unitWithDate.toMap(),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<int> deleteUnit(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'units',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
