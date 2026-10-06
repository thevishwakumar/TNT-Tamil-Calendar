import 'package:flutter/foundation.dart';
import '../models/tnt_models.dart';
import '../repositories/tnt_repositories.dart';
import 'supabase_service.dart';

/// Centralized Saved Items Service
/// Implements UI -> Controller/Service -> SavedItemsRepository -> Supabase
/// Cross-module persistence for Panchangam, Muhurtham, Special Days, and Festivals.
class SavedItemsService extends ChangeNotifier {
  static final SavedItemsService _instance = SavedItemsService._internal();
  factory SavedItemsService() => _instance;
  SavedItemsService._internal();

  final SavedItemsRepository _repository = SavedItemsRepository();
  final SupabaseService _db = SupabaseService();

  final List<SavedItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SavedItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Check whether a specific content item is bookmarked
  bool isItemSaved(String itemType, String itemId) {
    final normalizedType = SavedItemType.fromDbString(itemType).toDbString();
    return _items.any((item) => 
      item.itemId == itemId && 
      SavedItemType.fromDbString(item.itemType).toDbString() == normalizedType
    );
  }

  /// Get saved item count for badges
  int get count => _items.length;

  /// Retrieve all saved items
  List<SavedItem> getSavedItems() {
    return List.unmodifiable(_items);
  }

  /// Filter saved items by centralized SavedItemType
  List<SavedItem> getSavedItemsByType(SavedItemType type) {
    if (type == SavedItemType.all) {
      return List.unmodifiable(_items);
    }
    return _items.where((item) => item.typeEnum == type).toList();
  }

  /// Initialize and load saved items from repository / Supabase
  Future<void> init() async {
    await refresh();
  }

  /// Refresh saved items from the remote database
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchSavedItems();
      _items.clear();
      _items.addAll(fetched);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Save or bookmark an item across any module
  Future<void> saveItem(SavedItem item) async {
    final normalizedType = item.typeEnum.toDbString();
    
    // Prevent duplicate saves in local state
    final exists = isItemSaved(normalizedType, item.itemId);
    if (!exists) {
      _items.insert(0, item);
      notifyListeners();
    }

    try {
      final userId = _getEffectiveUserId();
      await _repository.saveItemRecord(item, userId);
    } catch (e) {
      // Rollback local state on remote failure
      _items.removeWhere((i) => i.itemId == item.itemId && i.typeEnum == item.typeEnum);
      notifyListeners();
      rethrow;
    }
  }

  /// Unsave / remove a saved item
  Future<void> unsaveItem(String itemType, String itemId) async {
    final normalizedType = SavedItemType.fromDbString(itemType).toDbString();
    _items.removeWhere((i) => 
      i.itemId == itemId && 
      SavedItemType.fromDbString(i.itemType).toDbString() == normalizedType
    );
    notifyListeners();

    try {
      final userId = _getEffectiveUserId();
      await _repository.deleteSavedItem(normalizedType, itemId, userId);
    } catch (e) {
      // Technically should rollback, but for now just rethrow
      rethrow;
    }
  }

  /// Toggle saved state easily
  Future<bool> toggleSave(SavedItem item) async {
    final normalizedType = item.typeEnum.toDbString();
    if (isItemSaved(normalizedType, item.itemId)) {
      await unsaveItem(normalizedType, item.itemId);
      return false;
    } else {
      await saveItem(item);
      return true;
    }
  }

  String _getEffectiveUserId() {
    if (_db.isInitialized) {
      final user = _db.client.auth.currentUser;
      if (user != null) return user.id;
    }
    throw StateError('User not authenticated. Cannot save items.');
  }
}
