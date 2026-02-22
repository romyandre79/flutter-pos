import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/purchase_order.dart';
import 'package:flutter_pos/data/models/purchase_order_item.dart';
import 'package:flutter_pos/data/models/supplier.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';

class PurchaseOrderRepository {
  final DatabaseHelper _databaseHelper;

  PurchaseOrderRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // Get all POs with basic info
  Future<List<PurchaseOrder>> getAllPurchaseOrders() async {
    final db = await _databaseHelper.database;
    
    // Join with suppliers to get supplier name
    final result = await db.rawQuery('''
      SELECT po.*, s.name as supplier_name 
      FROM purchase_orders po
      LEFT JOIN suppliers s ON po.supplier_id = s.id
      ORDER BY po.order_date DESC
    ''');

    return result.map((map) {
      // Create a partial supplier object for display
      final supplier = map['supplier_name'] != null 
          ? Supplier(id: map['supplier_id'] as int, name: map['supplier_name'] as String) 
          : null;
          
      return PurchaseOrder.fromMap(map, supplier: supplier);
    }).toList();
  }

  // Get single PO with items
  Future<PurchaseOrder?> getPurchaseOrderById(int id) async {
    final db = await _databaseHelper.database;
    
    // Get PO
    final poResult = await db.rawQuery('''
      SELECT po.*, s.name as supplier_name, s.phone as supplier_phone, s.address as supplier_address, s.email as supplier_email, s.contact_person as supplier_contact
      FROM purchase_orders po
      LEFT JOIN suppliers s ON po.supplier_id = s.id
      WHERE po.id = ?
    ''', [id]);

    if (poResult.isEmpty) return null;

    final poMap = poResult.first;
    
    // Get Items
    final itemsResult = await db.query(
      'purchase_order_items',
      where: 'purchase_order_id = ?',
      whereArgs: [id],
    );

    final items = itemsResult.map((map) => PurchaseOrderItem.fromMap(map)).toList();

    // Construct Supplier
    final supplier = poMap['supplier_name'] != null 
        ? Supplier(
            id: poMap['supplier_id'] as int, 
            name: poMap['supplier_name'] as String,
            phone: poMap['supplier_phone'] as String?,
            address: poMap['supplier_address'] as String?,
            email: poMap['supplier_email'] as String?,
            contactPerson: poMap['supplier_contact'] as String?,
          ) 
        : null;

    return PurchaseOrder.fromMap(poMap, supplier: supplier, items: items);
  }

  // Create PO with items
  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder po) async {
    final db = await _databaseHelper.database;
    
    if (AppConstants.isDemo) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM purchase_orders');
      final count = result.first['count'] as int;
      if (count >= 10) {
        throw Exception('Anda telah melebihi batas transaksi pembelian aplikasi demo, silakan beli hubungi Sales Kreatif atau ke 081932701147');
      }
    }

    return await db.transaction((txn) async {
      final poMap = po.toMap();
      poMap.remove('id');
      poMap['created_at'] = DateTime.now().toIso8601String();
      poMap['updated_at'] = DateTime.now().toIso8601String();
      poMap['is_synced'] = 0; // New PO is not synced

      // Insert PO
        final poId = await txn.insert('purchase_orders', poMap);

      // Insert Items
      List<PurchaseOrderItem> newItems = [];
      for (final item in po.items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        itemMap['purchase_order_id'] = poId;
        itemMap['created_at'] = DateTime.now().toIso8601String();
        
        final itemId = await txn.insert('purchase_order_items', itemMap);
        newItems.add(item.copyWith(id: itemId, purchaseOrderId: poId));
      }

      return po.copyWith(id: poId, items: newItems, isSynced: false);
    });
  }

  // Update PO Status (e.g., to 'received')
  // When status becomes 'received', also:
  //  - Create new master products for items without product_id
  //  - Update cost (harga modal) and stock for items with product_id
  Future<void> updatePurchaseOrderStatus(int id, String status) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Update PO status
      await txn.update(
        'purchase_orders',
        {
          'status': status,
          'updated_at': now,
          'is_synced': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // 2. If receiving, process items against master products
      if (status == 'received') {
        final items = await txn.query(
          'purchase_order_items',
          where: 'purchase_order_id = ?',
          whereArgs: [id],
        );

        for (final item in items) {
          final productId = item['product_id'] as int?;
          final quantity = item['quantity'] as int;
          final cost = item['cost'] as int;
          final itemName = item['item_name'] as String;

          if (productId != null) {
            // Update existing product: cost + stock
            await txn.rawUpdate(
              'UPDATE products SET cost = ?, stock = COALESCE(stock, 0) + ?, updated_at = ? WHERE id = ?',
              [cost, quantity, now, productId],
            );
          } else {
            // Create new master product
            final newProductId = await txn.insert('products', {
              'name': itemName,
              'price': cost, // Default sell price = cost, user can adjust later
              'cost': cost,
              'stock': quantity,
              'unit': (item['unit'] as String?) ?? 'pcs',
              'type': 'goods',
              'is_active': 1,
              'created_at': now,
              'updated_at': now,
            });

            // Link the PO item back to the new product
            await txn.update(
              'purchase_order_items',
              {'product_id': newProductId},
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }
        }
      }
    });
  }

  // Update entire PO
  Future<void> updatePurchaseOrder(PurchaseOrder po) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
       // Update PO details
       await txn.update(
         'purchase_orders',
         {
           ...po.toMap(),
           'updated_at': DateTime.now().toIso8601String(),
           'is_synced': 0,
         }..remove('id'),
         where: 'id = ?',
         whereArgs: [po.id],
       );

       // Delete existing items and re-insert (simplest strategy for now)
       await txn.delete(
         'purchase_order_items', 
         where: 'purchase_order_id = ?', 
         whereArgs: [po.id]
       );

       for (final item in po.items) {
          final itemMap = item.toMap();
          itemMap.remove('id');
          itemMap['purchase_order_id'] = po.id;
          itemMap['created_at'] = DateTime.now().toIso8601String();
          await txn.insert('purchase_order_items', itemMap);
       }
    });
  }

  // Delete PO (Cascade delete items handled by DB schema if configured, but safe to do manual or rely on FK)
  // FK is ON DELETE CASCADE in schema, so items will be deleted automatically.
  Future<void> deletePurchaseOrder(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'purchase_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
