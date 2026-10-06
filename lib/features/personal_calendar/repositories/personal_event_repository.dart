// ignore_for_file: avoid_print
import '../../../services/supabase_service.dart';
import '../models/personal_event_model.dart';

class PersonalEventRepository {
  final SupabaseService _db = SupabaseService();

  Future<List<PersonalEvent>> getEventsForMonth(int year, int month) async {
    if (!_db.isInitialized) throw StateError("Database not initialized");

    try {
      final startDate = DateTime.utc(year, month, 1).toIso8601String();
      // month+1 day 0 = last day of month; handles December -> January correctly
      final endDate =
          DateTime.utc(year, month + 1, 1).subtract(const Duration(seconds: 1)).toIso8601String();

      final res = await _db.client
          .from('personal_events')
          .select()
          .gte('start_time', startDate)
          .lte('start_time', endDate) // query on start_time so index is used
          .order('start_time');

      final list = res as List;
      return list
          .map((item) => PersonalEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createEvent(PersonalEvent event) async {
    if (!_db.isInitialized) throw StateError("Database not initialized");
    try {
      await _db.client.from('personal_events').insert(event.toJsonForInsert());
    } catch (e) {
      print('PersonalEventRepository.createEvent: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(PersonalEvent event) async {
    if (!_db.isInitialized) throw StateError("Database not initialized");
    try {
      await _db.client
          .from('personal_events')
          .update(event.toJsonForUpdate())
          .eq('id', event.id);
    } catch (e) {
      print('PersonalEventRepository.updateEvent: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    if (!_db.isInitialized) throw StateError("Database not initialized");
    try {
      await _db.client.from('personal_events').delete().eq('id', id);
    } catch (e) {
      print('PersonalEventRepository.deleteEvent: $e');
      rethrow;
    }
  }
}
