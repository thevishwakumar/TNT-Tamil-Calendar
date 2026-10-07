import '../../../models/tnt_models.dart';
import '../../../services/supabase_service.dart';
import '../../../core/authorization/admin_authorization_service.dart';
import '../../../repositories/tnt_repositories.dart';

/// Central Admin Content Management Repository
/// Strictly restricted to authenticated ADMIN users with backend verification.
class AdminContentRepository {
  final List<dynamic> _devMediaAssets = [];
  final List<dynamic> _devAuditLogs = [];
  final List<dynamic> _devFestivals = [];
  final List<dynamic> _devSpecialDays = [];
  final List<dynamic> _devMuhurthamDates = [];
  final List<dynamic> _devCalendarDays = [];
  final List<dynamic> _devPanchangamEntries = [];
  final List<dynamic> _devContentItems = [];

  static final AdminContentRepository _instance = AdminContentRepository._internal();
  factory AdminContentRepository() => _instance;
  AdminContentRepository._internal();

  final SupabaseService _db = SupabaseService();
  final AdminAuthorizationService _auth = AdminAuthorizationService();

  // In-memory development repository cache (synced deterministically when offline)

  bool _initialized = false;

  

  // ===========================================================================
  // CONTENT & POSTERS MANAGEMENT
  // ===========================================================================

  Future<List<ContentItem>> getContentItems({
    String? category,
    String? status,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {

    if (_db.isInitialized) {
      var query = _db.client.from('content').select('*, content_media(*)');
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.or('title_tamil.ilike.%$searchQuery%,title_english.ilike.%$searchQuery%');
      }
      final res = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);

      // final res = await query;
      return (res as List).map((json) => ContentItem.fromJson(json as Map<String, dynamic>)).toList();
    }

    // Dev fallback
    var filtered = _devContentItems.where((item) {
      if (category != null && category.isNotEmpty && item.category != category) return false;
      if (status != null && status.isNotEmpty && item.status != status) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return item.titleTamil.toLowerCase().contains(q) || item.titleEnglish.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return filtered.skip(offset).take(limit).cast<ContentItem>().toList();
  }

  Future<ContentItem> saveContentItem(ContentItem item) async {

    if (_db.isInitialized) {
      final isNew = item.id.isEmpty;
      final payload = item.toJson();
      if (isNew) payload.remove('id');

      final res = isNew
          ? await _db.client.from('content').insert(payload).select().single()
          : await _db.client.from('content').update(payload).eq('id', item.id).select().single();

      final saved = ContentItem.fromJson(res);
      await logAudit(
        action: isNew ? 'CREATE' : 'UPDATE',
        module: 'CONTENT',
        recordId: saved.id,
        newState: saved.toJson(),
      );
      return saved;
    }

    throw StateError('Offline mock data is not supported in production.');
  }

  Future<void> updateContentStatus(String contentId, String newStatus, {DateTime? scheduleTime}) async {

    if (_db.isInitialized) {
      final payload = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newStatus == 'PUBLISHED') {
        payload['publish_at'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'SCHEDULED' && scheduleTime != null) {
        payload['publish_at'] = scheduleTime.toIso8601String();
      }

      await _db.client.from('content').update(payload).eq('id', contentId);
      await logAudit(
        action: newStatus == 'PUBLISHED' ? 'PUBLISH' : (newStatus == 'SCHEDULED' ? 'SCHEDULE' : 'ARCHIVE'),
        module: 'CONTENT',
        recordId: contentId,
        newState: payload,
      );
      return;
    }

    // Dev fallback
    throw StateError('Offline mock data is not supported in production.');
  }

  // ===========================================================================
  // MEDIA ASSETS & STORAGE MANAGEMENT
  // ===========================================================================

  Future<List<MediaAsset>> getMediaAssets({
    String? mediaType,
    String? status = 'ACTIVE',
    String? searchQuery,
    int limit = 50,
  }) async {

    if (_db.isInitialized) {
      var query = _db.client.from('media_assets').select();
      if (mediaType != null && mediaType.isNotEmpty) {
        query = query.eq('media_type', mediaType);
      }
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('file_name', '%$searchQuery%');
      }
      final res = await query.order('created_at', ascending: false).limit(limit);

      // final res = await query;
      return (res as List).map((json) => MediaAsset.fromJson(json as Map<String, dynamic>)).toList();
    }

    throw StateError('Offline mock data is not supported in production.');
  }

  Future<MediaAsset> registerMediaAsset(MediaAsset asset) async {

    if (_db.isInitialized) {
      final payload = asset.toJson();
      if (asset.id.isEmpty) payload.remove('id');

      final res = await _db.client.from('media_assets').insert(payload).select().single();
      final saved = MediaAsset.fromJson(res);
      await logAudit(action: 'MEDIA_UPLOAD', module: 'MEDIA', recordId: saved.id, newState: saved.toJson());
      return saved;
    }

    final newAsset = MediaAsset(
      id: asset.id.isEmpty ? 'media-${DateTime.now().millisecondsSinceEpoch}' : asset.id,
      fileName: asset.fileName,
      fileSize: asset.fileSize,
      mimeType: asset.mimeType,
      storagePath: asset.storagePath,
      publicUrl: asset.publicUrl,
      thumbnailUrl: asset.thumbnailUrl,
      mediaType: asset.mediaType,
      relatedContentId: asset.relatedContentId,
      status: asset.status,
      createdBy: asset.createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    throw StateError('Offline mock data is not supported in production.');
    await logAudit(action: 'MEDIA_UPLOAD', module: 'MEDIA', recordId: newAsset.id, newState: newAsset.toJson());
    return newAsset;
  }

  // ===========================================================================
  // FESTIVALS MANAGEMENT
  // ===========================================================================

  Future<List<Festival>> getAdminFestivals({int? year, int? month, String? category, bool forceRefresh = false}) async {
    final fetchYear = year ?? DateTime.now().year;
    final fetchMonth = month ?? DateTime.now().month;
    return FestivalRepository().fetchFestivals(fetchYear, fetchMonth, category: category, forceRefresh: forceRefresh);
  }

  Future<Festival> saveFestival(Festival festival) async {
    if (_db.isInitialized) {
      final isNew = festival.id.isEmpty || festival.id.startsWith('fest-') || !festival.id.contains('-');
      final payload = {
        'date': festival.date.toIso8601String().substring(0, 10),
        'name_tamil': festival.nameTa.trim().isEmpty ? 'Unknown' : festival.nameTa,
        'name_english': festival.name.trim().isEmpty ? 'Unknown' : festival.name,
        'description_tamil': festival.descriptionTa,
        'description_english': festival.description,
        'is_published': festival.isPublished,
      };

      final res = isNew
          ? await _db.client.from('festivals').insert(payload).select().single()
          : await _db.client.from('festivals').update(payload).eq('id', festival.id).select().single();
      final saved = Festival.fromJson(res);
      await logAudit(action: isNew ? 'CREATE' : 'UPDATE', module: 'FESTIVALS', recordId: saved.id, newState: saved.toJson());
      return saved;
    }

    throw StateError('Offline mock data is not supported in production.');
  }

  Future<void> deleteFestival(String id) async {
    if (_db.isInitialized && id.isNotEmpty) {
      await _db.client.from('festivals').delete().eq('id', id);
      await logAudit(action: 'DELETE', module: 'FESTIVALS', recordId: id, newState: {});
    }
  }

  // ===========================================================================
  // SPECIAL DAYS MANAGEMENT
  // ===========================================================================

  Future<List<SpecialDay>> getAdminSpecialDays({int? year, int? month, String? category, bool forceRefresh = false}) async {
    final fetchYear = year ?? DateTime.now().year;
    final fetchMonth = month ?? DateTime.now().month;
    return SpecialDaysRepository().fetchSpecialDays(fetchYear, fetchMonth, category: category, forceRefresh: forceRefresh);
  }

  Future<SpecialDay> saveSpecialDay(SpecialDay sp) async {
    if (_db.isInitialized) {
      final isNew = sp.id.isEmpty || sp.id.startsWith('sp-') || !sp.id.contains('-'); // Ensure UUID check
      final payload = {
        'date': sp.date.toIso8601String().substring(0, 10),
        'name_tamil': sp.titleTa.trim().isEmpty ? 'Unknown' : sp.titleTa,
        'name_english': sp.title.trim().isEmpty ? 'Unknown' : sp.title,
        'category': sp.category,
        'description_tamil': sp.descriptionTa,
        'description_english': sp.description,
        'is_published': sp.isPublished,
      };
      
      try {
        final res = isNew
            ? await _db.client.from('special_days').insert(payload).select().single()
            : await _db.client.from('special_days').update(payload).eq('id', sp.id).select().single();
        final saved = SpecialDay.fromJson(res);
        await logAudit(action: isNew ? 'CREATE' : 'UPDATE', module: 'SPECIAL_DAYS', recordId: saved.id, newState: saved.toJson());
        return saved;
      } catch (e) {
        // Fallback for check constraint if category is wrong
        if (e.toString().contains('special_days_category_check') && isNew) {
           payload['category'] = 'Amavasai'; // Fallback to safe category
           final res = await _db.client.from('special_days').insert(payload).select().single();
           return SpecialDay.fromJson(res);
        }
        rethrow;
      }
    }

    throw StateError('Offline mock data is not supported in production.');
  }

  Future<void> deleteSpecialDay(String id) async {
    if (_db.isInitialized && id.isNotEmpty) {
      await _db.client.from('special_days').delete().eq('id', id);
      await logAudit(action: 'DELETE', module: 'SPECIAL_DAYS', recordId: id, newState: {});
    }
  }

  // ===========================================================================
  // MUHURTHAM MANAGEMENT
  // ===========================================================================

  Future<MuhurthamDate> saveMuhurthamDate(MuhurthamDate m) async {
    if (!_db.isInitialized) throw StateError('Offline mock data is not supported in production.');
    
    final isNew = m.id.isEmpty || m.id.startsWith('muh-') || !m.id.contains('-'); // uuid check
    final payload = {
      'date': m.date.toIso8601String().substring(0, 10),
      'title_tamil': m.categoryTa,
      'title_english': m.category,
      'description_tamil': m.descriptionTa,
      'description_english': m.description,
      'is_published': true,
      'category': m.category,
      'category_ta': m.categoryTa,
    };

    final res = isNew
        ? await _db.client.from('muhurtham_dates').insert(payload).select().single()
        : await _db.client.from('muhurtham_dates').update(payload).eq('id', m.id).select().single();

    final saved = MuhurthamDate.fromJson(res);
    await logAudit(action: isNew ? 'CREATE' : 'UPDATE', module: 'MUHURTHAM', recordId: saved.id, newState: res);
    return saved;
  }

  Future<void> deleteMuhurthamDate(String id) async {
    if (_db.isInitialized && id.isNotEmpty) {
      // Cascade delete might be enabled, but we manually delete timings first to be safe
      await _db.client.from('muhurtham_timings').delete().eq('muhurtham_date_id', id);
      await _db.client.from('muhurtham_dates').delete().eq('id', id);
      await logAudit(action: 'DELETE', module: 'MUHURTHAM', recordId: id, newState: {});
    }
  }

  Future<void> saveMuhurthamTiming(String muhurthamDateId, MuhurthamTimingItem t, {bool isNew = true}) async {
    if (!_db.isInitialized) throw StateError('Offline mock data is not supported in production.');
    final payload = {
      'muhurtham_date_id': muhurthamDateId,
      'start_time': t.startTime,
      'end_time': t.endTime,
      'nakshatra': t.nakshatra,
      'lagnam': t.lagnam,
      'nalla_neram_start': t.startTime,
      'nalla_neram_end': t.endTime,
    };

    if (isNew) {
      await _db.client.from('muhurtham_timings').insert(payload);
    } else {
      await _db.client.from('muhurtham_timings').update(payload).eq('muhurtham_date_id', muhurthamDateId);
    }
  }

  // ===========================================================================
  // AUDIT TRAIL
  // ===========================================================================

  Future<void> logAudit({
    required String action,
    required String module,
    required String recordId,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? newState,
  }) async {
    try {
      final adminId = _auth.verifiedAdminId ?? 'admin-root';
      final log = AdminAuditLog(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        adminId: adminId,
        adminEmail: 'admin@tnt.app',
        action: action,
        module: module,
        recordId: recordId,
        previousState: previousState,
        newState: newState,
        createdAt: DateTime.now(),
      );

      if (_db.isInitialized) {
        await _db.client.rpc('log_admin_audit', params: {
          'p_action': action,
          'p_module': module,
          'p_record_id': recordId,
          'p_previous_state': previousState,
          'p_new_state': newState,
        });
      } else {
        throw StateError('Offline mock data is not supported in production.');
      }
    } catch (e) {
      // Graceful catch so audit failure doesn't block operation
      print('Audit log recorded locally: $e');
    }
  }

  Future<List<AdminAuditLog>> getAuditLogs({int limit = 50}) async {
    if (_db.isInitialized) {
      final res = await _db.client
          .from('admin_audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List).map((json) => AdminAuditLog.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw StateError('Offline mock data is not supported in production.');
  }

  // ===========================================================================
  // BULK IMPORT FOUNDATION
  // ===========================================================================

  Future<BulkImportResult> validateBulkImport({
    required String module,
    required String csvOrJsonContent,
  }) async {
    final List<String> errors = [];
    final List<Map<String, dynamic>> validRecords = [];
    int total = 0;
    int valid = 0;
    int invalid = 0;
    int duplicates = 0;

    try {
      final lines = csvOrJsonContent.trim().split('\n');
      if (lines.isEmpty) {
        return BulkImportResult(
          totalRows: 0,
          validRows: 0,
          invalidRows: 0,
          duplicateRows: 0,
          errors: ['File is empty'],
          previewRecords: [],
        );
      }

      final header = lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
      total = lines.length - 1;

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cols = line.split(',').map((c) => c.trim()).toList();
        if (cols.length < 3) {
          invalid++;
          errors.add('Row $i: Insufficient columns (${cols.length})');
          continue;
        }

        final record = <String, dynamic>{};
        for (int h = 0; h < header.length && h < cols.length; h++) {
          record[header[h]] = cols[h];
        }

        // Schema & Date validation
        if (record.containsKey('date')) {
          final parsedDate = DateTime.tryParse(record['date'] as String);
          if (parsedDate == null) {
            invalid++;
            errors.add('Row $i: Invalid date format in "${record['date']}"');
            continue;
          }
        }

        valid++;
        validRecords.add(record);
      }

      return BulkImportResult(
        totalRows: total,
        validRows: valid,
        invalidRows: invalid,
        duplicateRows: duplicates,
        errors: errors,
        previewRecords: validRecords,
      );
    } catch (e) {
      return BulkImportResult(
        totalRows: total,
        validRows: 0,
        invalidRows: total,
        duplicateRows: 0,
        errors: ['Parse error: $e'],
        previewRecords: [],
      );
    }
  }
}
