import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/data/models/order.dart';
import 'package:flutter_pos/data/models/product.dart';
import 'package:flutter_pos/data/models/purchase_order.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<String?> saveExcelFile(Excel excel, String fileName) async {
    final fileBytes = excel.save();
    if (fileBytes == null) return null;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: fileName,
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(fileBytes);
        return outputFile;
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return filePath;
    }
    return null;
  }

  // Templates
  Future<String?> downloadProductTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Template Produk'];
    
    List<String> headers = ['Nama Produk', 'Deskripsi', 'Harga Jual', 'Harga Beli', 'Stok', 'Satuan', 'Tipe (Barang/Jasa)', 'Barcode'];
    for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
    }
    
    // Example Row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Contoh Produk');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = TextCellValue('Deskripsi produk');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = IntCellValue(10000);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1)).value = IntCellValue(5000);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1)).value = IntCellValue(100);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1)).value = TextCellValue('pcs');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1)).value = TextCellValue('Barang');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1)).value = TextCellValue('123456789');

    excel.delete('Sheet1');
    return await saveExcelFile(excel, 'Template_Import_Produk.xlsx');
  }

  Future<String?> downloadCustomerTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Template Pelanggan'];
    
    List<String> headers = ['Nama Pelanggan', 'Nomor HP', 'Alamat', 'Catatan'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
    }
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Budi Santoso');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = TextCellValue('081234567890');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = TextCellValue('Jl. Merdeka No. 45');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1)).value = TextCellValue('Pelanggan VIP');

    excel.delete('Sheet1');
    return await saveExcelFile(excel, 'Template_Import_Pelanggan.xlsx');
  }

  Future<String?> downloadSupplierTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Template Supplier'];
    
    List<String> headers = ['Nama Supplier', 'Contact Person', 'Alamat', 'Telepon', 'Email'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
    }
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('PT. Supplier Maju');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = TextCellValue('Pak Joko');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = TextCellValue('Jl. Industri Blok A');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1)).value = TextCellValue('021-5555555');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1)).value = TextCellValue('supplier@example.com');

    excel.delete('Sheet1');
    return await saveExcelFile(excel, 'Template_Import_Supplier.xlsx');
  }

  // Reports
  Future<String?> exportOrders(List<Order> orders, DateTime startDate, DateTime endDate) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Penjualan'];

    List<String> headers = ['No Invoice', 'Tanggal', 'Pelanggan', 'Status', 'Total Item', 'Total Harga', 'Dibayar', 'Catatan'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
    }

    for (int i = 0; i < orders.length; i++) {
        final order = orders[i];
        final row = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(order.invoiceNo);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(DateFormat(AppConstants.dateTimeFormat).format(order.orderDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(order.customerName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(order.statusDisplay);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = IntCellValue(order.totalItems);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = IntCellValue(order.totalPrice);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = IntCellValue(order.paid);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = TextCellValue(order.notes ?? '-');
    }

    excel.delete('Sheet1');
    final fileName = 'Laporan_Penjualan_${DateFormat('yyyyMMdd').format(startDate)}-${DateFormat('yyyyMMdd').format(endDate)}.xlsx';
    return await saveExcelFile(excel, fileName);
  }

  Future<String?> exportStock(List<Product> products) async {
     final excel = Excel.createExcel();
     final sheet = excel['Laporan Stok'];

     List<String> headers = ['Nama Produk', 'Kategori', 'Stok', 'Satuan', 'Harga Beli', 'Harga Jual', 'Nilai Aset'];
     for (int i = 0; i < headers.length; i++) {
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
           ..value = TextCellValue(headers[i])
           ..cellStyle = CellStyle(bold: true);
     }

     for (int i = 0; i < products.length; i++) {
       final product = products[i];
       final row = i + 1;
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(product.name);
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(product.isService ? 'Jasa' : 'Barang');
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = IntCellValue(product.stock ?? 0);
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(product.unit);
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = IntCellValue(product.cost);
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = IntCellValue(product.price);
       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = IntCellValue(product.cost * (product.stock ?? 0));
     }

     excel.delete('Sheet1');
     final fileName = 'Laporan_Stok_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
     return await saveExcelFile(excel, fileName);
  }
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Exported File');
  }
}
