import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/core/utils/password_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = docsDir.path;
    } else {
      dbPath = await getDatabasesPath();
    }
    final path = join(dbPath, filePath);

    // Print path for debugging
    // print('Database path: $path');

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT UNIQUE,
        address TEXT,
        notes TEXT,
        total_orders INTEGER DEFAULT 0,
        total_spent INTEGER DEFAULT 0,
        last_order_date TEXT,
        server_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Services table
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price INTEGER NOT NULL,
        duration_days INTEGER DEFAULT 3,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price INTEGER NOT NULL,
        cost INTEGER DEFAULT 0,
        stock INTEGER,
        unit TEXT NOT NULL,
        type TEXT NOT NULL, -- service, goods
        min_stock INTEGER DEFAULT 0,
        barcode TEXT,
        duration_days INTEGER,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        server_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Orders table
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        order_date TEXT NOT NULL,
        due_date TEXT,
        status TEXT NOT NULL,
        total_items INTEGER DEFAULT 0,
        total_weight REAL DEFAULT 0,
        total_price INTEGER NOT NULL,
        paid INTEGER DEFAULT 0,
        notes TEXT,
        created_by INTEGER,
        is_synced INTEGER DEFAULT 0,
        server_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Create Order Items table
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        service_id INTEGER,
        service_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        price_per_unit INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        product_id INTEGER,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
      )
    ''');

    // Create Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        change INTEGER DEFAULT 0,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        received_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (received_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Create App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create Suppliers table
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_person TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        server_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Simpans table
    await db.execute('''
      CREATE TABLE purchase_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        order_date TEXT NOT NULL,
        expected_date TEXT,
        status TEXT NOT NULL, -- pending, received, cancelled
        total_amount INTEGER DEFAULT 0,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        server_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');

    // Simpan Items table
    await db.execute('''
      CREATE TABLE purchase_order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_order_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        cost INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        product_id INTEGER,
        unit TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
      )
    ''');

    // Create Units table
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        server_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes
    await _createIndexes(db);

    // Seed default data
    await _seedData(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Users indexes
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');

    // Customers indexes
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');

    // Orders indexes
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
    await db.execute('CREATE INDEX idx_orders_date ON orders(order_date)');
    await db.execute('CREATE INDEX idx_orders_invoice ON orders(invoice_no)');
    await db.execute('CREATE INDEX idx_orders_customer ON orders(customer_id)');

    // Order Items indexes
    await db.execute('CREATE INDEX idx_order_items_order ON order_items(order_id)');

    // Payments indexes
    await db.execute('CREATE INDEX idx_payments_order ON payments(order_id)');
    await db.execute('CREATE INDEX idx_payments_date ON payments(payment_date)');

    // Products indexes
    await db.execute('CREATE INDEX idx_products_type ON products(type)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
  }

  Future<void> _seedData(Database db) async {
    // Seed default owner
    final passwordHash = PasswordHelper.hashPassword(AppConstants.defaultOwnerPassword);
    await db.insert('users', {
      'username': AppConstants.defaultOwnerUsername,
      'password_hash': passwordHash,
      'name': AppConstants.defaultOwnerName,
      'role': 'owner',
      'is_active': 1,
    });

    // Seed default services
    final services = [
    ];

    for (final service in services) {
      await db.insert('services', {
        ...service,
        'is_active': 1,
      });
      // Also insert into products
      await db.insert('products', {
        'name': service['name'],
        'unit': service['unit'],
        'price': service['price'],
        'duration_days': service['duration_days'],
        'type': 'service',
        'is_active': 1,
      });
    }

    // Seed default settings
    final settings = {
      AppConstants.keyStoreName: AppConstants.defaultStoreName,
      AppConstants.keyStoreAddress: AppConstants.defaultStoreAddress,
      AppConstants.keyStorePhone: AppConstants.defaultStorePhone,
      AppConstants.keyInvoicePrefix: AppConstants.defaultInvoicePrefix,
      AppConstants.keyPrinterAddress: '',
      AppConstants.keyLastInvoiceDate: '',
      AppConstants.keyLastInvoiceNumber: '0',
    };

    for (final entry in settings.entries) {
      await db.insert('app_settings', {
        'key': entry.key,
        'value': entry.value,
      });
    }
    
    // Seed default units
    final units = ['pcs', 'kg', 'liter', 'box', 'pack'];
    for (final unit in units) {
       await db.insert('units', {
         'name': unit,
       });
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here
    if (oldVersion < 2) {
      // Add change column to payments table if it doesn't exist
      final columns = await db.rawQuery('PRAGMA table_info(payments)');
      final hasChangeColumn = columns.any((col) => col['name'] == 'change');
      
      if (!hasChangeColumn) {
        await db.execute('ALTER TABLE payments ADD COLUMN change INTEGER DEFAULT 0');
      }
      
      
      // Add Purchasing tables (Suppliers, POs) if they don't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          contact_person TEXT,
          address TEXT,
          phone TEXT,
          email TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_id INTEGER NOT NULL,
          order_date TEXT NOT NULL,
          expected_date TEXT,
          status TEXT NOT NULL,
          total_amount INTEGER DEFAULT 0,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_order_id INTEGER NOT NULL,
          item_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          cost INTEGER NOT NULL,
          subtotal INTEGER NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      // Create Products table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          price INTEGER NOT NULL,
          cost INTEGER DEFAULT 0,
          stock INTEGER,
          unit TEXT NOT NULL,
          type TEXT NOT NULL, -- service, goods
          duration_days INTEGER,
          image_url TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Migrate Services to Products
      // Check if services table exists and has data
      final servicesExist = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='services'");
      if (servicesExist.isNotEmpty) {
        await db.execute('''
          INSERT INTO products (id, name, unit, price, duration_days, is_active, created_at, type)
          SELECT id, name, unit, price, duration_days, is_active, created_at, 'service'
          FROM services
        ''');
      }

      // Add product_id to order_items
      final columns = await db.rawQuery('PRAGMA table_info(order_items)');
      final hasProductIdColumn = columns.any((col) => col['name'] == 'product_id');

      if (!hasProductIdColumn) {
        await db.execute('ALTER TABLE order_items ADD COLUMN product_id INTEGER');
        
        // Migrate service_id to product_id
        await db.execute('UPDATE order_items SET product_id = service_id WHERE service_id IS NOT NULL');
        
        // Create index for product_id
        await db.execute('CREATE INDEX idx_order_items_product ON order_items(product_id)');
      }
    }

    if (oldVersion < 4) {
      // Add permission columns to users table
      final columns = await db.rawQuery('PRAGMA table_info(users)');
      final hasSuppliersColumn = columns.any((col) => col['name'] == 'can_access_suppliers');
      final hasItemsColumn = columns.any((col) => col['name'] == 'can_access_items');

      if (!hasSuppliersColumn) {
        await db.execute('ALTER TABLE users ADD COLUMN can_access_suppliers INTEGER DEFAULT 0');
      }

      if (!hasItemsColumn) {
        await db.execute('ALTER TABLE users ADD COLUMN can_access_items INTEGER DEFAULT 0');
      }
      
      // Update existing Owner users to have full access
      await db.rawUpdate('''
        UPDATE users 
        SET can_access_suppliers = 1, can_access_items = 1 
        WHERE role = ?
      ''', ['owner']);
    }

    if (oldVersion < 5) {
      // Add product_id to purchase_order_items
      final columns = await db.rawQuery('PRAGMA table_info(purchase_order_items)');
      final hasProductIdColumn = columns.any((col) => col['name'] == 'product_id');

      if (!hasProductIdColumn) {
        await db.execute('ALTER TABLE purchase_order_items ADD COLUMN product_id INTEGER');
        
        // No need to backfill as older items didn't have this concept
        // Create index
        await db.execute('CREATE INDEX idx_po_items_product ON purchase_order_items(product_id)');
      }
    }

    if (oldVersion < 6) {
      // Add synchronization columns
      
      // Orders: is_synced, server_id
      final orderCols = await db.rawQuery('PRAGMA table_info(orders)');
      if (!orderCols.any((col) => col['name'] == 'is_synced')) {
        await db.execute('ALTER TABLE orders ADD COLUMN is_synced INTEGER DEFAULT 0');
        await db.execute('CREATE INDEX idx_orders_synced ON orders(is_synced)');
      }
      if (!orderCols.any((col) => col['name'] == 'server_id')) {
        await db.execute('ALTER TABLE orders ADD COLUMN server_id INTEGER');
      }
      
      // Products: server_id
      final productCols = await db.rawQuery('PRAGMA table_info(products)');
      if (!productCols.any((col) => col['name'] == 'server_id')) {
        await db.execute('ALTER TABLE products ADD COLUMN server_id INTEGER');
      }
      
      // Customers: server_id
      final customerCols = await db.rawQuery('PRAGMA table_info(customers)');
      if (!customerCols.any((col) => col['name'] == 'server_id')) {
        await db.execute('ALTER TABLE customers ADD COLUMN server_id INTEGER');
      }

      // Categories (if we had them, but we don't seem to have a table yet, skippping)
      
      // Suppliers: server_id
      final supplierCols = await db.rawQuery('PRAGMA table_info(suppliers)');
      if (!supplierCols.any((col) => col['name'] == 'server_id')) {
        await db.execute('ALTER TABLE suppliers ADD COLUMN server_id INTEGER');
      }
    }

    if (oldVersion < 7) {
      // Version 7: Units, Barcodes, Purchasing Sync
      
      // 1. Create Units table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS units (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          server_id INTEGER,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Seed default units if empty
      final unitsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM units'));
      if (unitsCount == 0) {
        final units = ['pcs', 'kg', 'liter', 'box', 'pack'];
        for (final unit in units) {
           await db.insert('units', {
             'name': unit,
           });
        }
      }

      // 2. Add barcode to products
      final productCols = await db.rawQuery('PRAGMA table_info(products)');
      if (!productCols.any((col) => col['name'] == 'barcode')) {
        await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
        await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
      }

      // 3. Add unit to purchase_order_items
      final poItemCols = await db.rawQuery('PRAGMA table_info(purchase_order_items)');
      if (!poItemCols.any((col) => col['name'] == 'unit')) {
        await db.execute('ALTER TABLE purchase_order_items ADD COLUMN unit TEXT');
      }
      
      // 4. Add sync columns to purchase_orders (server_id, is_synced)
      final poCols = await db.rawQuery('PRAGMA table_info(purchase_orders)');
      if (!poCols.any((col) => col['name'] == 'server_id')) {
        await db.execute('ALTER TABLE purchase_orders ADD COLUMN server_id INTEGER');
      }
      if (!poCols.any((col) => col['name'] == 'is_synced')) {
        await db.execute('ALTER TABLE purchase_orders ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      
      // 5. Ensure server_id on suppliers (already in v6 but check again to be safe)
      final supplierCols = await db.rawQuery('PRAGMA table_info(suppliers)');
      if (!supplierCols.any((col) => col['name'] == 'server_id')) {
        await db.execute('ALTER TABLE suppliers ADD COLUMN server_id INTEGER');
      }
    }
  }
  
  Future<String> getDbPath() async {
    final String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = docsDir.path;
    } else {
      dbPath = await getDatabasesPath();
    }
    return join(dbPath, AppConstants.databaseName);
  }

  // Utility methods
  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> resetDatabase() async {
    await deleteDatabase();
    await database; // This will recreate the database
  }
}

