import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_pos/data/models/product.dart';
import 'package:flutter_pos/data/models/customer.dart';
import 'package:flutter_pos/data/models/supplier.dart';

class ImportService {
  // Parse Products
  Future<List<Product>> parseProductsFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<Product> products = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      // Skip header row
      bool isHeader = true;
      
      for (var row in sheet.rows) {
        if (isHeader) {
          isHeader = false;
          continue;
        }

        if (row.isEmpty) continue;

        try {
          // Index based parsing based on Template
          // 0: Name, 1: Description, 2: Price, 3: Cost, 4: Stock, 5: Unit, 6: Type, 7: Barcode
          final name = _getCellValue(row.elementAt(0));
          if (name.isEmpty) continue;

          final description = _getCellValue(row.elementAt(1));
          final price = int.tryParse(_getCellValue(row.elementAt(2))) ?? 0;
          final cost = int.tryParse(_getCellValue(row.elementAt(3))) ?? 0;
          final stock = int.tryParse(_getCellValue(row.elementAt(4))) ?? 0;
          final unit = _getCellValue(row.elementAt(5));
          final typeStr = _getCellValue(row.elementAt(6)).toLowerCase();
          final barcode = _getCellValue(row.elementAt(7));

          final type = typeStr.contains('jasa') || typeStr.contains('service') 
              ? ProductType.service 
              : ProductType.goods;

          products.add(Product(
            name: name,
            description: description,
            price: price,
            cost: cost,
            stock: stock,
            unit: unit.isEmpty ? 'pcs' : unit,
            type: type,
            barcode: barcode.isEmpty ? null : barcode,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } catch (e) {
          // Skip invalid rows
          continue;
        }
      }
    }
    return products;
  }

  // Parse Customers
  Future<List<Customer>> parseCustomersFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<Customer> customers = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      bool isHeader = true;
      for (var row in sheet.rows) {
        if (isHeader) {
          isHeader = false;
          continue;
        }

        if (row.isEmpty) continue;

        try {
          // 0: Name, 1: Phone, 2: Address, 3: Notes
          final name = _getCellValue(row.elementAt(0));
          if (name.isEmpty) continue;

          final phone = _getCellValue(row.elementAt(1));
          final address = _getCellValue(row.elementAt(2));
          final notes = _getCellValue(row.elementAt(3));

          customers.add(Customer(
            name: name,
            phone: phone,
            address: address,
            notes: notes,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } catch (e) {
          continue;
        }
      }
    }
    return customers;
  }

  // Parse Suppliers
  Future<List<Supplier>> parseSuppliersFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<Supplier> suppliers = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      bool isHeader = true;
      for (var row in sheet.rows) {
        if (isHeader) {
          isHeader = false;
          continue;
        }

        if (row.isEmpty) continue;

        try {
          // 0: Name, 1: Contact Person, 2: Address, 3: Phone, 4: Email
          final name = _getCellValue(row.elementAt(0));
          if (name.isEmpty) continue;

          final contactPerson = _getCellValue(row.elementAt(1));
          final address = _getCellValue(row.elementAt(2));
          final phone = _getCellValue(row.elementAt(3));
          final email = _getCellValue(row.elementAt(4));

          suppliers.add(Supplier(
            name: name,
            contactPerson: contactPerson,
            address: address,
            phone: phone,
            email: email,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } catch (e) {
          continue;
        }
      }
    }
    return suppliers;
  }

  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }
}
