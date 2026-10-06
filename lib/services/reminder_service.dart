import 'package:flutter/foundation.dart';
import '../models/tnt_models.dart';
import '../repositories/tnt_repositories.dart';
import 'supabase_service.dart';

/// Centralized Reminder Service
/// UI -> Controller/Service -> ReminderRepository -> Supabase (user_reminders)
/// Works across Panchangam, Muhurtham, Festivals, and Special Days.
class ReminderService extends ChangeNotifier {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final ReminderRepository _repository = ReminderRepository();
  final SupabaseService _db = SupabaseService();

  final List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get count => _reminders.length;
  int get activeCount => _reminders.where((r) => r.isSet && !r.isPast).length;

  /// Check whether an item has an active reminder
  bool hasReminder(String itemType, String itemId) {
    final normalizedType = SavedItemType.fromDbString(itemType).toDbString();
    return _reminders.any((r) => 
      r.itemId == itemId && 
      SavedItemType.fromDbString(r.itemType).toDbString() == normalizedType &&
      r.isSet
    );
  }

  /// Retrieve the reminder for an item if it exists
  Reminder? getReminder(String itemType, String itemId) {
    final normalizedType = SavedItemType.fromDbString(itemType).toDbString();
    try {
      return _reminders.firstWhere((r) => 
        r.itemId == itemId && 
        SavedItemType.fromDbString(r.itemType).toDbString() == normalizedType
      );
    } catch (_) {
      return null;
    }
  }

  /// Filter reminders by Upcoming, Past, All
  List<Reminder> getRemindersByFilter(ReminderFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case ReminderFilter.upcoming:
        return _reminders.where((r) => r.reminderAt.isAfter(now) || r.eventDate.isAfter(now)).toList()
          ..sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
      case ReminderFilter.past:
        return _reminders.where((r) => r.reminderAt.isBefore(now) && r.eventDate.isBefore(now)).toList()
          ..sort((a, b) => b.reminderAt.compareTo(a.reminderAt));
      case ReminderFilter.all:
        return List.unmodifiable(_reminders);
    }
  }

  /// Initialize and load reminders
  Future<void> init() async {
    await refresh();
  }

  /// Refresh reminders from repository
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchReminders();
      _reminders.clear();
      _reminders.addAll(fetched);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Add or update a reminder
  Future<Reminder> setReminder({
    required String itemType,
    required String itemId,
    required String title,
    String titleTa = '',
    String subtitle = '',
    String subtitleTa = '',
    required DateTime eventDate,
    required String reminderTime,
    DateTime? reminderAt,
    String reminderType = '1_day_before',
  }) async {
    final userId = _getEffectiveUserId();
    
    // Calculate precise reminderAt if not provided
    DateTime targetReminderAt = reminderAt ?? eventDate;
    if (reminderAt == null) {
      if (reminderType == '1_day_before') {
        targetReminderAt = DateTime(eventDate.year, eventDate.month, eventDate.day - 1, 20, 0);
      } else if (reminderType == 'morning_6am') {
        targetReminderAt = DateTime(eventDate.year, eventDate.month, eventDate.day, 6, 0);
      } else if (reminderType == '1_hour_before') {
        targetReminderAt = eventDate.subtract(const Duration(hours: 1));
      }
    }

    final reminder = Reminder(
      id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      itemType: SavedItemType.fromDbString(itemType).toDbString(),
      itemId: itemId,
      title: title,
      titleTa: titleTa,
      subtitle: subtitle,
      subtitleTa: subtitleTa,
      eventDate: eventDate,
      reminderTime: reminderTime,
      reminderAt: targetReminderAt,
      reminderType: reminderType,
      isSet: true,
      status: 'active',
      createdAt: DateTime.now(),
    );

    // Remove any previous reminder for the same item locally
    _reminders.removeWhere((r) => r.itemId == itemId && r.itemType == reminder.itemType);
    _reminders.insert(0, reminder);
    notifyListeners();

    try {
      final saved = await _repository.insertReminder(reminder);
      return saved;
    } catch (e) {
      _reminders.removeWhere((r) => r.id == reminder.id);
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle enabled/disabled status
  Future<void> toggleReminderStatus(String reminderId, bool isEnabled) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isSet: isEnabled,
        status: isEnabled ? 'active' : 'disabled',
        updatedAt: DateTime.now(),
      );
      notifyListeners();

      try {
        await _repository.updateReminderStatus(reminderId, isEnabled);
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Delete / cancel reminder
  Future<void> removeReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    notifyListeners();

    try {
      await _repository.deleteReminder(reminderId);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove reminder for a specific item
  Future<void> removeReminderForItem(String itemType, String itemId) async {
    final normalizedType = SavedItemType.fromDbString(itemType).toDbString();
    final toRemove = _reminders.where((r) => 
      r.itemId == itemId && 
      SavedItemType.fromDbString(r.itemType).toDbString() == normalizedType
    ).toList();

    for (final r in toRemove) {
      await removeReminder(r.id);
    }
  }

  String _getEffectiveUserId() {
    if (_db.isInitialized) {
      final user = _db.client.auth.currentUser;
      if (user != null) return user.id;
    }
    throw StateError('User not authenticated. Cannot set reminders.');
  }
}
