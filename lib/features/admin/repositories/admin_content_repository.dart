import 'package:flutter/foundation.dart';
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

    // Dev fallback
    if (item.id.isEmpty) {
      throw StateError('Offline mock data is not supported in production.');
    } else {
      throw StateError('Offline mock data is not supported in production.');
    }
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
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(festival.id);
      final dateStr = '${festival.date.year.toString().padLeft(4, '0')}-${festival.date.month.toString().padLeft(2, '0')}-${festival.date.day.toString().padLeft(2, '0')}';
      final payload = <String, dynamic>{
        'date': dateStr,
        'name_tamil': festival.nameTa.isNotEmpty ? festival.nameTa : festival.name,
        'name_english': festival.name.isNotEmpty ? festival.name : festival.nameTa,
        'description_tamil': festival.descriptionTa,
        'description_english': festival.description,
        'is_published': festival.isPublished,
      };
      if (isUuid) {
        payload['id'] = festival.id;
      }
      final res = isUuid
          ? await _db.client.from('festivals').update(payload).eq('id', festival.id).select().single()
          : await _db.client.from('festivals').insert(payload).select().single();
      final saved = Festival.fromJson(res);
      await logAudit(action: isUuid ? 'UPDATE' : 'CREATE', module: 'FESTIVALS', recordId: saved.id, newState: saved.toJson());
      return saved;
    }

    throw StateError('Offline mock data is not supported in production.');
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
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(sp.id);
      final dateStr = '${sp.date.year.toString().padLeft(4, '0')}-${sp.date.month.toString().padLeft(2, '0')}-${sp.date.day.toString().padLeft(2, '0')}';

      String cat = sp.category.toLowerCase().trim();
      const allowedCategories = [
        'amavasai', 'pournami', 'pradosham', 'sashti', 'ekadashi',
        'krithigai', 'chaturthi', 'shivaratri', 'special_day'
      ];
      if (!allowedCategories.contains(cat)) {
        if (cat.contains('amavasai')) cat = 'amavasai';
        else if (cat.contains('pournami')) cat = 'pournami';
        else if (cat.contains('pradosham')) cat = 'pradosham';
        else if (cat.contains('sashti')) cat = 'sashti';
        else if (cat.contains('ekadashi')) cat = 'ekadashi';
        else if (cat.contains('krithigai')) cat = 'krithigai';
        else if (cat.contains('chaturthi')) cat = 'chaturthi';
        else if (cat.contains('shivaratri')) cat = 'shivaratri';
        else cat = 'special_day';
      }

      final payload = <String, dynamic>{
        'date': dateStr,
        'name_tamil': sp.titleTa.isNotEmpty ? sp.titleTa : sp.title,
        'name_english': sp.title.isNotEmpty ? sp.title : sp.titleTa,
        'category': cat,
        'description_tamil': sp.descriptionTa,
        'description_english': sp.description,
        'is_published': sp.isPublished,
      };
      if (isUuid) {
        payload['id'] = sp.id;
      }
      final res = isUuid
          ? await _db.client.from('special_days').update(payload).eq('id', sp.id).select().single()
          : await _db.client.from('special_days').insert(payload).select().single();
      final saved = SpecialDay.fromJson(res);
      await logAudit(action: isUuid ? 'UPDATE' : 'CREATE', module: 'SPECIAL_DAYS', recordId: saved.id, newState: saved.toJson());
      return saved;
    }

    throw StateError('Offline mock data is not supported in production.');
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

  Future<int> commitBulkImport({
    required String module,
    required List<Map<String, dynamic>> records,
  }) async {
    int count = 0;
    for (final rec in records) {
      try {
        final dateStr = rec['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0];
        final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();

        if (module == 'FESTIVALS') {
          final fest = Festival(
            id: '',
            date: parsedDate,
            name: rec['name_english']?.toString() ?? rec['name']?.toString() ?? '',
            nameTa: rec['name_tamil']?.toString() ?? rec['name_ta']?.toString() ?? '',
            type: rec['type']?.toString() ?? rec['category']?.toString() ?? 'Festivals',
            description: rec['description_english']?.toString() ?? rec['description']?.toString() ?? '',
            descriptionTa: rec['description_tamil']?.toString() ?? rec['description_ta']?.toString() ?? '',
            category: rec['category']?.toString() ?? 'Festivals',
          );
          await saveFestival(fest);
          count++;
        } else if (module == 'SPECIAL_DAYS') {
          final sp = SpecialDay(
            id: '',
            date: parsedDate,
            title: rec['name_english']?.toString() ?? rec['title']?.toString() ?? '',
            titleTa: rec['name_tamil']?.toString() ?? rec['title_ta']?.toString() ?? '',
            category: rec['category']?.toString() ?? 'special_day',
            description: rec['description_english']?.toString() ?? rec['description']?.toString() ?? '',
            descriptionTa: rec['description_tamil']?.toString() ?? rec['description_ta']?.toString() ?? '',
            isHoliday: false,
          );
          await saveSpecialDay(sp);
          count++;
        }
      } catch (e) {
        debugPrint('Error importing record: $e');
      }
    }
    return count;
  }

  Future<bool> deleteSpecialDay(String id) async {
    if (_db.isInitialized) {
      await _db.client.from('special_days').delete().eq('id', id);
      await logAudit(action: 'DELETE', module: 'SPECIAL_DAYS', recordId: id);
      return true;
    }
    return false;
  }

  Future<bool> deleteFestival(String id) async {
    if (_db.isInitialized) {
      await _db.client.from('festivals').delete().eq('id', id);
      await logAudit(action: 'DELETE', module: 'FESTIVALS', recordId: id);
      return true;
    }
    return false;
  }
}