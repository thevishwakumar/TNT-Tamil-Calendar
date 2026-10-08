import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_models.dart';
import '../services/supabase_service.dart';

class LocationRepository {
  final SupabaseClient? _client;

  // Memory Caches
  static List<TNTCountry>? _countriesCache;
  static final Map<String, List<TNTState>> _statesCache = {};
  static final Map<String, List<TNTDistrict>> _districtsCache = {};

  LocationRepository({SupabaseClient? client})
      : _client = client;

  Future<List<TNTCountry>> getCountries() async {
    if (_countriesCache != null) return _countriesCache!;
    
    final client = _client ?? SupabaseService().client;
    final res = await client
        .from('countries')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);
    
    _countriesCache = (res as List).map((e) => TNTCountry.fromJson(e)).toList();
    return _countriesCache!;
  }

  Future<List<TNTState>> getStates(String countryId) async {
    if (_statesCache.containsKey(countryId)) return _statesCache[countryId]!;

    final client = _client ?? SupabaseService().client;
    final res = await client
        .from('states')
        .select()
        .eq('country_id', countryId)
        .eq('is_active', true)
        .order('name', ascending: true);
        
    final list = (res as List).map((e) => TNTState.fromJson(e)).toList();
    _statesCache[countryId] = list;
    return list;
  }

  Future<List<TNTDistrict>> getDistricts(String stateId) async {
    if (_districtsCache.containsKey(stateId)) return _districtsCache[stateId]!;

    final client = _client ?? SupabaseService().client;
    final res = await client
        .from('districts')
        .select()
        .eq('state_id', stateId)
        .eq('is_active', true)
        .order('name', ascending: true);
        
    final list = (res as List).map((e) => TNTDistrict.fromJson(e)).toList();
    _districtsCache[stateId] = list;
    return list;
  }

  /// Implements Phase 39: Server-side search with limit
  Future<List<TNTCity>> searchCities(String query, {String? districtId, int limit = 50}) async {
    final client = _client ?? SupabaseService().client;
    
    var request = client
        .from('cities')
        .select()
        .eq('is_active', true);
        
    if (districtId != null && districtId.isNotEmpty) {
      request = request.eq('district_id', districtId);
    }
    
    if (query.isNotEmpty) {
      request = request.ilike('name', '%$query%');
    }
    
    final res = await request.order('name', ascending: true).limit(limit);
        
    return (res as List).map((e) => TNTCity.fromJson(e)).toList();
  }
  
  Future<TNTCity?> getCityById(String cityId) async {
    final client = _client ?? SupabaseService().client;
    try {
      final res = await client
          .from('cities')
          .select()
          .eq('id', cityId)
          .single();
      return TNTCity.fromJson(res);
    } catch (_) {
      return null;
    }
  }
}
