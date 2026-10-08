import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../models/catering_enquiry.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class CateringRepository {
  final SupabaseService _db = SupabaseService();
  static const String _localLeadsKey = 'tnt_local_catering_leads';

  String _generateReferenceCode() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomStr = (100 + Random().nextInt(900)).toString(); // 3 digit
    return 'TNT-CE-$dateStr-$randomStr';
  }

  Future<void> _saveLocalLead(CateringEnquiry lead) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_localLeadsKey) ?? [];
      list.add(jsonEncode(lead.toJson()));
      await prefs.setStringList(_localLeadsKey, list);
    } catch (_) {}
  }

  Future<List<CateringEnquiry>> _getLocalLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_localLeadsKey) ?? [];
      return list.map((str) => CateringEnquiry.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<CateringEnquiry> submitEnquiry(CateringEnquiry enquiry) async {
    final userId = _db.isInitialized ? _db.client.auth.currentUser?.id : null;
    final referenceCode = _generateReferenceCode();

    final payload = enquiry.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      referenceCode: referenceCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_db.isInitialized) {
      try {
        final dbPayload = payload.toJson()..remove('id');
        final response = await _db.client
            .from('catering_enquiries')
            .insert(dbPayload)
            .select()
            .single();

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
        } catch (_) {}

        return CateringEnquiry.fromJson(response);
      } catch (e) {
        debugPrint('Catering Supabase insert failed: $e. Storing locally.');
      }
    }

    await _saveLocalLead(payload);
    return payload;
  }

  Future<List<CateringEnquiry>> getAdminLeads({String filter = 'All', int page = 0, int pageSize = 25}) async {
    List<CateringEnquiry> remote = [];
    if (_db.isInitialized) {
      try {
        var query = _db.client.from('catering_enquiries').select();
        if (filter != 'All') {
          query = query.eq('status', filter.toLowerCase());
        }
        final response = await query
            .order('created_at', ascending: false)
            .range(page * pageSize, (page + 1) * pageSize - 1);
        remote = (response as List).map((json) => CateringEnquiry.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Catering remote load error: $e');
      }
    }

    final local = await _getLocalLeads();
    final all = [...remote, ...local];
    if (filter != 'All') {
      return all.where((l) => l.status.toLowerCase() == filter.toLowerCase()).toList();
    }
    return all;
  }

  Future<CateringEnquiry> updateLeadStatus(String id, String newStatus, String? notes) async {
    if (_db.isInitialized) {
      try {
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
      } catch (e) {
        debugPrint('Remote update failed: $e');
      }
    }

    final local = await _getLocalLeads();
    final updated = <CateringEnquiry>[];
    CateringEnquiry? target;
    for (var l in local) {
      if (l.id == id || l.referenceCode == id) {
        target = l.copyWith(status: newStatus, notes: notes, updatedAt: DateTime.now());
        updated.add(target);
      } else {
        updated.add(l);
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_localLeadsKey, updated.map((e) => jsonEncode(e.toJson())).toList());
    } catch (_) {}

    return target ??
        CateringEnquiry(
          id: id,
          referenceCode: 'TNT-CE-$id',
          fullName: '',
          mobileNumber: '',
          eventType: '',
          eventDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  Future<Map<String, int>> getLeadCounts() async {
    int newCount = 0;
    int followCount = 0;
    int confirmedCount = 0;
    int totalCount = 0;

    if (_db.isInitialized) {
      try {
        final res = await _db.client.rpc('get_catering_lead_counts');
        newCount = res['new'] ?? 0;
        followCount = res['follow_up'] ?? 0;
        confirmedCount = res['confirmed'] ?? 0;
        totalCount = newCount + followCount + confirmedCount;
        return {
          'new': newCount,
          'follow_up': followCount,
          'confirmed': confirmedCount,
          'total': totalCount,
        };
      } catch (_) {
        try {
          final resNew = await _db.client.from('catering_enquiries').select('id').eq('status', 'new').count(CountOption.exact);
          final resFollow = await _db.client.from('catering_enquiries').select('id').eq('status', 'follow_up').count(CountOption.exact);
          final resConf = await _db.client.from('catering_enquiries').select('id').eq('status', 'confirmed').count(CountOption.exact);
          final resTotal = await _db.client.from('catering_enquiries').select('id').count(CountOption.exact);
          return {
            'new': resNew.count ?? 0,
            'follow_up': resFollow.count ?? 0,
            'confirmed': resConf.count ?? 0,
            'total': resTotal.count ?? 0,
          };
        } catch (_) {}
      }
    }

    final localLeads = await _getLocalLeads();
    newCount = localLeads.where((l) => l.status.toLowerCase() == 'new').length;
    followCount = localLeads.where((l) => l.status.toLowerCase() == 'follow_up').length;
    confirmedCount = localLeads.where((l) => l.status.toLowerCase() == 'confirmed').length;
    totalCount = localLeads.length;

    return {
      'new': newCount,
      'follow_up': followCount,
      'confirmed': confirmedCount,
      'total': totalCount,
    };
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
