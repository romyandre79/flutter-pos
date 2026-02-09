import 'package:flutter/foundation.dart';

import 'package:flutter_pos_offline/core/api/api_service.dart';
import 'package:flutter_pos_offline/data/database/database_helper.dart';
import 'package:flutter_pos_offline/data/models/customer.dart';
import 'package:flutter_pos_offline/data/models/order.dart';
import 'package:flutter_pos_offline/data/models/order_item.dart';
import 'package:flutter_pos_offline/data/models/product.dart';
import 'package:flutter_pos_offline/data/models/supplier.dart';


import 'package:flutter_pos_offline/core/services/session_service.dart';

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
          // data.data might contain the record or list
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
        // Skip on error, try next
        debugPrint('Error uploading order ${map['invoice_no']}: $e');
      }
    }

    return successCount;
  }

  // Download master data (Products, Customers, Suppliers)
  Future<void> downloadMasterData() async {
    await _ensureAuthenticated();
    await _downloadProducts();
    await _downloadCustomers();
    await _downloadSuppliers();
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
