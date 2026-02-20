import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/data/database/database_helper.dart';

class InvoiceGenerator {
  /// Generate invoice number
  /// Format: PREFIX-YYMMDD-NNNN
  /// Example: LNDR-260115-0001
  static Future<String> generate() async {
    final db = await DatabaseHelper.instance.database;
    final today = DateTime.now();
    final dateStr = DateFormatter.formatForInvoice(today);


    // Get settings
    final settingsResult = await db.query(
      'app_settings',
      where: 'key IN (?, ?, ?, ?, ?)',
      whereArgs: [
        AppConstants.keyInvoicePrefix,
        AppConstants.keyPlantCode,
        AppConstants.keyMachineNumber,
        AppConstants.keyLastInvoiceDate,
        AppConstants.keyLastInvoiceNumber,
      ],
    );

    final settings = Map.fromEntries(
      settingsResult.map((e) => MapEntry(e['key'] as String, e['value'] as String)),
    );

    // Default prefix is POS if not set, or user standard
    final prefix = settings[AppConstants.keyInvoicePrefix] ?? AppConstants.defaultInvoicePrefix;
    final plantCode = settings[AppConstants.keyPlantCode] ?? '';
    final machineNumber = settings[AppConstants.keyMachineNumber] ?? AppConstants.defaultMachineNumber;
    
    final lastDate = settings[AppConstants.keyLastInvoiceDate] ?? '';
    final lastNumber = int.parse(settings[AppConstants.keyLastInvoiceNumber] ?? '0');

    int nextNumber;
    // Check if date changed (using yyMMdd format comparison)
    if (lastDate == dateStr) {
      // Same day, increment
      nextNumber = lastNumber + 1;
    } else {
      // New day, reset to 1
      nextNumber = 1;
    }

    // Update settings
    await db.rawInsert('''
      INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)
    ''', [AppConstants.keyLastInvoiceDate, dateStr]);

    await db.rawInsert('''
      INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)
    ''', [AppConstants.keyLastInvoiceNumber, nextNumber.toString()]);

    // Format: POS-[plant code]-[machine-number]-ddmmyy-[running number]
    // Note: User requested ddmmyy. DateFormatter.formatForInvoice is yyMMdd. 
    // Let's check DateFormatter.
    // If formatForInvoice is yyMMdd, I should maybe change it or format it manually here.
    // User asked for: ddmmyy
    final day = today.day.toString().padLeft(2, '0');
    final month = today.month.toString().padLeft(2, '0');
    final year = (today.year % 100).toString().padLeft(2, '0');
    final dateToken = '$day$month$year';

    // Running number padding (e.g. 0001)
    final paddedNumber = nextNumber.toString().padLeft(4, '0');
    
    // Construct Invoice
    // If plantCode is empty, handle gracefully? User pattern suggests it might be there.
    // Format: POS-PLANT-MACHINE-DDMMYY-NNNN
    final partPlant = plantCode.isNotEmpty ? '$plantCode-' : '';
    // machineNumber is likely '01', so it's always there.
    
    return '$prefix-$partPlant$machineNumber-$dateToken-$paddedNumber';
  }

  /// Validate invoice format
  static bool isValidInvoice(String invoice) {
    // Pattern: PREFIX-YYMMDD-NNNN
    final pattern = RegExp(r'^[A-Z]+-\d{6}-\d{4}$');
    return pattern.hasMatch(invoice);
  }

  /// Extract date from invoice
  static DateTime? extractDate(String invoice) {
    try {
      final parts = invoice.split('-');
      if (parts.length != 3) return null;

      final dateStr = parts[1];
      final year = 2000 + int.parse(dateStr.substring(0, 2));
      final month = int.parse(dateStr.substring(2, 4));
      final day = int.parse(dateStr.substring(4, 6));

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Extract sequence number from invoice
  static int? extractSequence(String invoice) {
    try {
      final parts = invoice.split('-');
      if (parts.length != 3) return null;
      return int.parse(parts[2]);
    } catch (e) {
      return null;
    }
  }
}
