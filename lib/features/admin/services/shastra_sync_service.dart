import 'package:tnt_tamil_calendar/services/supabase_service.dart';

class SyncPreviewResult {
  final int fetched;
  final int valid;
  final int newRecords;
  final int updatedRecords;
  final int skipped;
  final int errors;
  final List<String> errorDetails;
  final List<Map<String, dynamic>> pendingInserts;
  final List<Map<String, dynamic>> pendingUpdates;
  
  // To store state for commit
  final String cityCode;
  final int year;

  SyncPreviewResult({
    required this.fetched,
    required this.valid,
    required this.newRecords,
    required this.updatedRecords,
    required this.skipped,
    required this.errors,
    required this.errorDetails,
    required this.pendingInserts,
    required this.pendingUpdates,
    required this.cityCode,
    required this.year,
  });
}

class PanchangamSyncService {
  final SupabaseService _db = SupabaseService();

  Future<SyncPreviewResult> previewFestivals(String cityCode, int year) async {
    try {
      if (!_db.isInitialized) throw Exception('Database not initialized');
      
      final res = await _db.client.functions.invoke(
        'panchang-sync',
        body: {
          'action': 'sync_festivals',
          'year': year,
          'cityCode': cityCode,
          'preview_only': true
        },
      );
      
      if (res.status != null && res.status! >= 400) throw Exception('Function failed with status ${res.status}');
      
      final data = res.data;
      if (data['error'] != null) throw Exception(data['error']);
      
      return SyncPreviewResult(
        fetched: data['fetched'] ?? 0,
        valid: data['valid'] ?? data['fetched'] ?? 0,
        newRecords: data['newRecords'] ?? 0,
        updatedRecords: data['updatedRecords'] ?? 0,
        skipped: data['skipped'] ?? 0,
        errors: data['errors'] ?? 0,
        errorDetails: (data['errorDetails'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        pendingInserts: [],
        pendingUpdates: [],
        cityCode: cityCode,
        year: year,
      );
    } catch (e) {
      return SyncPreviewResult(
        fetched: 0, valid: 0, newRecords: 0, updatedRecords: 0,
        skipped: 0, errors: 1, errorDetails: [e.toString()],
        pendingInserts: [], pendingUpdates: [],
        cityCode: cityCode, year: year,
      );
    }
  }

  Future<bool> commitSync(SyncPreviewResult preview, String tableName) async {
    try {
      if (tableName != 'festivals') return false; // Only festivals implemented
      
      final res = await _db.client.functions.invoke(
        'panchang-sync',
        body: {
          'action': 'sync_festivals',
          'year': preview.year,
          'cityCode': preview.cityCode,
          'preview_only': false
        },
      );
      
      if (res.status != null && res.status! >= 400) throw Exception('Function failed with status ${res.status}');
      final data = res.data;
      if (data['error'] != null) throw Exception(data['error']);
      
      return data['success'] == true;
    } catch (e) {
      print('Sync commit error: $e');
      return false;
    }
  }

  // Range-based panchang sync could be here
  Future<SyncPreviewResult> previewPanchang(String cityCode, int year) async {
    return SyncPreviewResult(
      fetched: 0, valid: 0, newRecords: 0, updatedRecords: 0, skipped: 0, errors: 0, 
      errorDetails: ['Not fully implemented in edge function yet'], pendingInserts: [], pendingUpdates: [],
      cityCode: cityCode, year: year,
    );
  }
}
