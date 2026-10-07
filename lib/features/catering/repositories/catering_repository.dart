import '../../../services/supabase_service.dart';
import '../models/catering_enquiry.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class CateringRepository {
  final SupabaseService _db = SupabaseService();

  String _generateReferenceCode() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomStr = (100 + Random().nextInt(900)).toString(); // 3 digit
    return 'TNT-CE-$dateStr-$randomStr';
  }

  Future<CateringEnquiry> submitEnquiry(CateringEnquiry enquiry) async {
    if (!_db.isInitialized) {
      throw Exception('Database not initialized');
    }

    final userId = _db.client.auth.currentUser?.id;
    final referenceCode = _generateReferenceCode();

    final payload = enquiry.copyWith(
      userId: userId,
      referenceCode: referenceCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toJson();
    
    // Safety against empty ID insertion if handled by DB default gen_random_uuid
    payload.remove('id');

    final response = await _db.client
        .from('catering_enquiries')
        .insert(payload)
        .select()
        .single();
        
    // Optionally trigger admin notification via another table or RPC
    try {
      await _db.client.from('admin_notifications').insert({
        'title': 'New Catering Enquiry',
        'body': '${enquiry.fullName} submitted a ${enquiry.eventType} enquiry for ${DateFormat('dd MMM yyyy').format(enquiry.eventDate)}.',
        'type': 'catering_enquiry',
        'payload': {
          'enquiry_id': response['id'],
          'reference_code': response['reference_code'],
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Catering Enquiry notification failed: $e');
      // Do not throw, main insert succeeded
    }

    return CateringEnquiry.fromJson(response);
  }

  Future<List<CateringEnquiry>> getAdminLeads({String filter = 'All', int page = 0, int pageSize = 25}) async {
    if (!_db.isInitialized) return [];

    var query = _db.client
        .from('catering_enquiries')
        .select()
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    if (filter != 'All') {
      query = query.eq('status', filter.toLowerCase());
    }

    final response = await query;
    return (response as List).map((json) => CateringEnquiry.fromJson(json)).toList();
  }

  Future<CateringEnquiry> updateLeadStatus(String id, String newStatus, String? notes) async {
    if (!_db.isInitialized) throw Exception('Database not initialized');

    final updateData = <String, dynamic>{
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (notes != null) {
      updateData['notes'] = notes;
    }
    if (newStatus == 'contacted') {
      updateData['contacted_at'] = DateTime.now().toIso8601String();
    }

    final response = await _db.client
        .from('catering_enquiries')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return CateringEnquiry.fromJson(response);
  }

  Future<Map<String, int>> getLeadCounts() async {
    if (!_db.isInitialized) return {'new': 0, 'follow_up': 0, 'confirmed': 0};

    try {
      final res = await _db.client.rpc('get_catering_lead_counts');
      return {
        'new': res['new'] ?? 0,
        'follow_up': res['follow_up'] ?? 0,
        'confirmed': res['confirmed'] ?? 0,
      };
    } catch (e) {
      // Fallback if RPC doesn't exist
      try {
        final newCount = await _db.client.from('catering_enquiries').select('id').eq('status', 'new').count();
        final followCount = await _db.client.from('catering_enquiries').select('id').eq('status', 'follow_up').count();
        final confirmedCount = await _db.client.from('catering_enquiries').select('id').eq('status', 'confirmed').count();
        return {
          'new': newCount.count,
          'follow_up': followCount.count,
          'confirmed': confirmedCount.count,
        };
      } catch (e2) {
         return {'new': 0, 'follow_up': 0, 'confirmed': 0};
      }
    }
  }
}

// Add copyWith to CateringEnquiry
extension CateringEnquiryExtension on CateringEnquiry {
  CateringEnquiry copyWith({
    String? id,
    String? userId,
    String? referenceCode,
    String? fullName,
    String? mobileNumber,
    String? eventType,
    String? otherEventType,
    DateTime? eventDate,
    int? guestCount,
    String? eventLocation,
    String? message,
    String? status,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? contactedAt,
    String? notes,
    String? assignedTo,
  }) {
    return CateringEnquiry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      referenceCode: referenceCode ?? this.referenceCode,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      eventType: eventType ?? this.eventType,
      otherEventType: otherEventType ?? this.otherEventType,
      eventDate: eventDate ?? this.eventDate,
      guestCount: guestCount ?? this.guestCount,
      eventLocation: eventLocation ?? this.eventLocation,
      message: message ?? this.message,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactedAt: contactedAt ?? this.contactedAt,
      notes: notes ?? this.notes,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
