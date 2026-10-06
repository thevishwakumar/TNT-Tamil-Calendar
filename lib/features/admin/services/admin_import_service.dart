import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import '../../../services/supabase_service.dart';

class AdminImportResult {
  final bool success;
  final String message;
  final int rowsProcessed;
  final int errors;

  AdminImportResult({
    required this.success,
    required this.message,
    this.rowsProcessed = 0,
    this.errors = 0,
  });
}

class AdminImportService {
  final SupabaseService _db = SupabaseService();

  Future<AdminImportResult> pickAndImportMuhurtham() async {
    return _pickAndImport('muhurtham_dates');
  }

  Future<AdminImportResult> pickAndImportFestivals() async {
    return _pickAndImport('festivals');
  }

  Future<AdminImportResult> pickAndImportSpecialDays() async {
    return _pickAndImport('special_days');
  }

  Future<AdminImportResult> _pickAndImport(String tableName) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (files.isEmpty) {
        return AdminImportResult(success: false, message: 'No file selected');
      }

      final file = files.first;
      final bytes = await file.readAsBytes();
      
      List<List<dynamic>> rows = [];

      if (file.extension?.toLowerCase() == 'csv') {
        final csvString = utf8.decode(bytes);
        rows = csv.decode(csvString);
      } else if (file.extension?.toLowerCase() == 'xlsx') {
        var excel = Excel.decodeBytes(bytes);
        if (excel.tables.isNotEmpty) {
          final sheet = excel.tables[excel.tables.keys.first];
          if (sheet != null) {
            for (var row in sheet.rows) {
              rows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
            }
          }
        }
      } else {
        return AdminImportResult(success: false, message: 'Unsupported file format');
      }

      if (rows.isEmpty || rows.length == 1) {
        return AdminImportResult(success: false, message: 'File is empty or contains only headers');
      }

      final headers = rows.removeAt(0).map((e) => e.toString().trim().toLowerCase()).toList();

      List<Map<String, dynamic>> recordsToInsert = [];
      int errorCount = 0;

      for (var row in rows) {
        if (row.isEmpty || row.every((element) => element == null || element.toString().trim().isEmpty)) {
          continue;
        }

        try {
          final record = _mapRowToRecord(headers, row, tableName);
          if (record != null) {
            recordsToInsert.add(record);
          } else {
            errorCount++;
          }
        } catch (e) {
          debugPrint('Error parsing row: $e');
          errorCount++;
        }
      }

      if (recordsToInsert.isEmpty) {
        return AdminImportResult(success: false, message: 'No valid records found to import', errors: errorCount);
      }

      // Upsert to handle updates for existing IDs
      await _db.client.from(tableName).upsert(recordsToInsert);

      return AdminImportResult(
        success: true,
        message: 'Successfully imported ${recordsToInsert.length} records. Errors: $errorCount',
        rowsProcessed: recordsToInsert.length,
        errors: errorCount,
      );
    } catch (e) {
      debugPrint('Import Error: $e');
      return AdminImportResult(success: false, message: 'Import failed: $e');
    }
  }

  Map<String, dynamic>? _mapRowToRecord(List<String> headers, List<dynamic> row, String tableName) {
    final map = <String, dynamic>{};
    for (int i = 0; i < headers.length; i++) {
      if (i < row.length) {
        final val = row[i]?.toString().trim();
        if (val != null && val.isNotEmpty) {
          map[headers[i]] = val;
        }
      }
    }

    if (tableName == 'muhurtham_dates') {
      if (!map.containsKey('date') || !map.containsKey('category')) return null;
      map['location'] ??= 'Chennai';
      map['is_published'] = true;
      if (!map.containsKey('id')) map['id'] = _generateDateBasedId(map['date'], map['category']);
    } else if (tableName == 'festivals') {
      if (!map.containsKey('date') || !map.containsKey('name')) return null;
      if (!map.containsKey('category')) map['category'] = 'hindu';
      map['is_published'] = true;
      if (!map.containsKey('id')) map['id'] = _generateDateBasedId(map['date'], map['name']);
    } else if (tableName == 'special_days') {
      if (!map.containsKey('date') || !map.containsKey('name') || !map.containsKey('category')) return null;
      map['is_published'] = true;
      if (!map.containsKey('id')) map['id'] = _generateDateBasedId(map['date'], map['name']);
    }

    return map;
  }

  String _generateDateBasedId(String dateStr, String suffix) {
    final safeSuffix = suffix.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    return '${dateStr}_$safeSuffix';
  }
}
