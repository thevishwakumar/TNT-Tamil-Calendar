import 'package:tnt_tamil_calendar/services/supabase_service.dart';
import 'package:tnt_tamil_calendar/services/shastra_panchangam/shastra_panchangam_api.dart';
import 'package:tnt_tamil_calendar/services/shastra_panchangam/shastra_api_models.dart';
import 'package:intl/intl.dart';

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
  });
}

class PanchangamSyncService {
  final ShastraPanchangamApi _shastraApi = ShastraPanchangamApi();
  final SupabaseService _db = SupabaseService();

  Future<SyncPreviewResult> previewFestivals(String cityCode, int year) async {
    int fetched = 0;
    int valid = 0;
    int newRecs = 0;
    int updatedRecs = 0;
    int skipped = 0;
    int errors = 0;
    List<String> errorDetails = [];
    List<Map<String, dynamic>> pendingInserts = [];
    List<Map<String, dynamic>> pendingUpdates = [];

    try {
      final festivals = await _shastraApi.getFestivals();
      fetched = festivals.length;

      // Map to db records
      // We will only look at dates matching the specified year
      List<Map<String, dynamic>> apiRecords = [];
      for (var f in festivals) {
        // Find best date
        List<String> datesToUse = f.localDates[cityCode] ?? f.dates;
        for (var d in datesToUse) {
          if (d.startsWith(year.toString())) {
            valid++;
            apiRecords.add({
              'date': d,
              'name_english': f.nameEn,
              'name_tamil': f.nameEn, // Default translation fallback
              'is_published': true,
              'description_english': f.rule ?? '',
              'description_tamil': '',
            });
          }
        }
      }

      if (apiRecords.isEmpty) {
        return SyncPreviewResult(
            fetched: fetched, valid: valid, newRecords: 0, updatedRecords: 0, 
            skipped: 0, errors: 0, errorDetails: [], pendingInserts: [], pendingUpdates: []);
      }

      // Fetch existing festivals in that year to compare
      final start = '$year-01-01';
      final end = '$year-12-31';
      final existingRes = await _db.client.from('festivals')
          .select()
          .gte('date', start)
          .lte('date', end);

      final List<dynamic> existingList = existingRes as List<dynamic>;

      for (var apiRec in apiRecords) {
        final date = apiRec['date'];
        final name = apiRec['name_english'];
        
        // Find if exists
        final existingMatch = existingList.firstWhere(
          (e) => e['date'] == date && e['name_english'] == name,
          orElse: () => null,
        );

        if (existingMatch != null) {
          // Check if admin manual override (if we had a source field, we'd check here)
          // For now, assume we just update it if there's no custom description
          if (existingMatch['description_english'] != apiRec['description_english']) {
            pendingUpdates.add({
              'id': existingMatch['id'],
              ...apiRec,
            });
            updatedRecs++;
          } else {
            skipped++;
          }
        } else {
          pendingInserts.add(apiRec);
          newRecs++;
        }
      }

    } catch (e) {
      errors++;
      errorDetails.add(e.toString());
    }

    return SyncPreviewResult(
      fetched: fetched,
      valid: valid,
      newRecords: newRecs,
      updatedRecords: updatedRecs,
      skipped: skipped,
      errors: errors,
      errorDetails: errorDetails,
      pendingInserts: pendingInserts,
      pendingUpdates: pendingUpdates,
    );
  }

  Future<bool> commitSync(SyncPreviewResult preview, String tableName) async {
    try {
      if (preview.pendingInserts.isNotEmpty) {
        await _db.client.from(tableName).insert(preview.pendingInserts);
      }
      for (var update in preview.pendingUpdates) {
        final id = update['id'];
        final payload = Map<String, dynamic>.from(update)..remove('id');
        await _db.client.from(tableName).update(payload).eq('id', id);
      }
      return true;
    } catch (e) {
      print('Sync commit error: $e');
      return false;
    }
  }

  // Range-based panchang sync could be here
  Future<SyncPreviewResult> previewPanchang(String cityCode, int year) async {
    // Similarly fetch from Shastra and Navamsha
    return SyncPreviewResult(
      fetched: 0, valid: 0, newRecords: 0, updatedRecords: 0, skipped: 0, errors: 0, 
      errorDetails: ['Not fully implemented in preview'], pendingInserts: [], pendingUpdates: []
    );
  }
}
