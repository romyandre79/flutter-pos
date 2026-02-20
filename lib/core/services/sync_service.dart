import 'package:flutter/foundation.dart';

import 'package:flutter_pos/core/api/api_service.dart';
import 'package:flutter_pos/data/database/database_helper.dart';
import 'package:flutter_pos/data/models/customer.dart';
import 'package:flutter_pos/data/models/order.dart';
import 'package:flutter_pos/data/models/order_item.dart';
import 'package:flutter_pos/data/models/product.dart';
import 'package:flutter_pos/data/models/supplier.dart';


import 'package:flutter_pos/core/services/session_service.dart';

class SyncService {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;

  SyncService({
    required ApiService apiService,
    required DatabaseHelper dbHelper,
  })  : _apiService = apiService,
        _dbHelper = dbHelper;

  Future<void> _ensureAuthenticated() async {
    final session = await SessionService.getInstance();
    
    // Check if we have cached credentials
    if (!session.hasCachedCredentials()) {
      throw Exception('Sesi kadaluarsa. Silakan login ulang ke aplikasi untuk melakukan sinkronisasi.');
    }

    final username = session.getUsername()!;
    final password = session.getCachedPassword()!;

    // Attempt login to server
    final token = await _apiService.login(username, password);
    
    if (token != null) {
      await _apiService.setAuthToken(token);
    } else {
      throw Exception('Gagal login ke server. Periksa koneksi internet atau kredensial Anda.');
    }
  }

  // Upload unsynced orders
  Future<int> uploadOrders() async {
    await _ensureAuthenticated();

    final db = await _dbHelper.database;
    
    // Get unsynced orders
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    if (maps.isEmpty) return 0;

    int successCount = 0;

    for (final map in maps) {
      try {
        final order = Order.fromMap(map);
        
        // Get order items
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [order.id],
        );
        final items = itemMaps.map((e) => OrderItem.fromMap(e)).toList();
        
        // Prepare payload
        final payload = order.toMap();
        payload['items'] = items.map((e) => e.toMap()).toList();
        
        // Send to server using executeFlow
        final response = await _apiService.executeFlow('pos_sync_orders', 'pos', payload);
        
        if (response.data['code'] == 200) {
          final serverId = response.data['data']['data']['id']; 
          
          // Update local order as synced
          await db.update(
            'orders',
            {
              'is_synced': 1,
              'server_id': serverId,
            },
            where: 'id = ?',
            whereArgs: [order.id],
          );
          successCount++;
        }
      } catch (e) {
        debugPrint('Error uploading order ${map['invoice_no']}: $e');
      }
    }

    return successCount;
  }

  // Upload unsynced Purchase Orders
  Future<int> uploadPurchaseOrders() async {
    // Only upload if authenticated? Or let it fail inside?
    // We assume _ensureAuthenticated called before or handles it.
    await _ensureAuthenticated();

    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    if (maps.isEmpty) return 0;

    int successCount = 0;

    for (final map in maps) {
      try {
        // We probably need a PurchaseOrder model that supports fromMap/toMap properly 
        // including the new server_id and is_synced fields if not present
        // But here we can just use raw map manipulation if the model isn't updated yet, 
        // however we should update the model. Assuming model will be updated.
        // For now, let's construct payload manually to be safe or use model if available.
        
        // Get PO Items
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'purchase_order_items',
          where: 'purchase_order_id = ?',
          whereArgs: [map['id']],
        );
        
        final payload = Map<String, dynamic>.from(map);
        payload['items'] = itemMaps;
        
        // Remove local-only fields if necessary, or handled by server ignoring them
        payload.remove('id'); 
        payload.remove('is_synced');
        payload.remove('server_id'); // Should be null anyway if unsynced

        // Send to server
        final response = await _apiService.executeFlow('pos_sync_purchase_orders', 'pos', payload);

        if (response.data['code'] == 200) {
           final serverId = response.data['data']['data']['id'];
           
           await db.update(
             'purchase_orders',
             {
               'is_synced': 1,
               'server_id': serverId,
             },
             where: 'id = ?',
             whereArgs: [map['id']],
           );
           successCount++;
        }

      } catch (e) {
        debugPrint('Error uploading PO ${map['id']}: $e');
      }
    }
    return successCount;
  }

  // Download master data (Products, Customers, Suppliers, Units)
  Future<void> downloadMasterData() async {
    await _ensureAuthenticated();
    await _downloadUnits();
    await _downloadProducts();
    await _downloadCustomers();
    await _downloadSuppliers();
  }
  
  Future<void> _downloadUnits() async {
    try {
      final response = await _apiService.executeFlow('pos_get_units', 'pos', {});
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;
        
        await db.transaction((txn) async {
          for (final item in data) {
            final List<Map<String, dynamic>> existing = await txn.query(
              'units',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );
            
            final unitMap = {
              'name': item['name'],
              'server_id': item['id'],
              // 'updated_at': DateTime.now().toIso8601String(), // Optional
            };

            if (existing.isNotEmpty) {
              await txn.update(
                'units',
                unitMap,
                where: 'server_id = ?',
                whereArgs: [item['id']],
              );
            } else {
              await txn.insert('units', unitMap);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading units: $e');
      // Don't rethrow, just log, so other syncs continue?
      // rethrow; 
    }
  }

  Future<void> _downloadProducts() async {
    try {
      final response = await _apiService.executeFlow('pos_get_products', 'pos', {});
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          for (final item in data) {
            // Check if exists by server_id
            final List<Map<String, dynamic>> existing = await txn.query(
              'products',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );

            // Robust parsing
            final price = int.tryParse(item['price'].toString()) ?? 0;
            final cost = int.tryParse(item['cost'].toString()) ?? 0;
            final stock = int.tryParse(item['stock'].toString());
            final durationDays = int.tryParse(item['duration_days'].toString());

            final product = Product(
              name: item['name'],
              price: price,
              unit: item['unit'] ?? 'pcs',
              type: ProductTypeExtension.fromString(item['type'] ?? 'goods'),
              description: item['description'],
              cost: cost,
              stock: stock,
              durationDays: durationDays,
              imageUrl: item['image_url'],
              barcode: item['barcode'], // Added barcode
              serverId: item['id'],
            );

            if (existing.isNotEmpty) {
              // Update
              final updateMap = product.toMap()..remove('id'); // Keep local ID
              await txn.update(
                'products',
                updateMap,
                where: 'server_id = ?',
                whereArgs: [item['id']],
              );
            } else {
              // Insert
              await txn.insert('products', product.toMap());
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading products: $e');
      rethrow;
    }
  }

  Future<void> _downloadCustomers() async {
    try {
      final response = await _apiService.executeFlow('pos_get_customers', 'pos', {});
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          for (final item in data) {
            final List<Map<String, dynamic>> existing = await txn.query(
              'customers',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );

            final customer = Customer(
              name: item['name'],
              phone: item['phone'],
              address: item['address'],
              notes: item['notes'],
              serverId: item['id'],
            );

            if (existing.isNotEmpty) {
              final updateMap = customer.toMap()..remove('id');
              await txn.update(
                'customers',
                updateMap,
                where: 'server_id = ?',
                whereArgs: [item['id']],
              );
            } else {
              await txn.insert('customers', customer.toMap());
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading customers: $e');
      rethrow;
    }
  }

  Future<void> _downloadSuppliers() async {
    try {
      final response = await _apiService.executeFlow('pos_get_suppliers', 'pos', {});
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data']['data'];
        final db = await _dbHelper.database;

        await db.transaction((txn) async {
          for (final item in data) {
            final List<Map<String, dynamic>> existing = await txn.query(
              'suppliers',
              where: 'server_id = ?',
              whereArgs: [item['id']],
            );

            final supplier = Supplier(
              name: item['name'],
              contactPerson: item['contact_person'],
              address: item['address'],
              phone: item['phone'],
              email: item['email'],
              serverId: item['id'],
            );

            if (existing.isNotEmpty) {
              final updateMap = supplier.toMap()..remove('id');
              await txn.update(
                'suppliers',
                updateMap,
                where: 'server_id = ?',
                whereArgs: [item['id']],
              );
            } else {
              await txn.insert('suppliers', supplier.toMap());
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error downloading suppliers: $e');
      rethrow;
    }
  }
}
