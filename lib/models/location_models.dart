/// TNT Standard Location Models
/// Supports hierarchical selection: Country -> State -> District -> City
/// Data must be fetched from Supabase, not hardcoded.
library;

class TNTCountry {
  final String id;
  final String name;
  final String nameTa;
  final String isoCode;

  const TNTCountry({
    required this.id,
    required this.name,
    required this.nameTa,
    required this.isoCode,
  });

  factory TNTCountry.fromJson(Map<String, dynamic> json) {
    return TNTCountry(
      id: json['id'] as String,
      name: json['name'] as String,
      nameTa: json['name_ta'] as String? ?? json['name'] as String,
      isoCode: json['iso_code'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ta': nameTa,
    'iso_code': isoCode,
  };
}

class TNTState {
  final String id;
  final String countryId;
  final String name;
  final String nameTa;
  final String code;

  const TNTState({
    required this.id,
    required this.countryId,
    required this.name,
    required this.nameTa,
    required this.code,
  });

  factory TNTState.fromJson(Map<String, dynamic> json) {
    return TNTState(
      id: json['id'] as String,
      countryId: json['country_id'] as String,
      name: json['name'] as String,
      nameTa: json['name_ta'] as String? ?? json['name'] as String,
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'country_id': countryId,
    'name': name,
    'name_ta': nameTa,
    'code': code,
  };
}

class TNTDistrict {
  final String id;
  final String stateId;
  final String name;
  final String nameTa;

  const TNTDistrict({
    required this.id,
    required this.stateId,
    required this.name,
    required this.nameTa,
  });

  factory TNTDistrict.fromJson(Map<String, dynamic> json) {
    return TNTDistrict(
      id: json['id'] as String,
      stateId: json['state_id'] as String,
      name: json['name'] as String,
      nameTa: json['name_ta'] as String? ?? json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'state_id': stateId,
    'name': name,
    'name_ta': nameTa,
  };
}

class TNTCity {
  final String id;
  final String districtId;
  final String stateId;
  final String countryId;
  final String name;
  final String nameTa;
  final double latitude;
  final double longitude;
  final String timezone;

  const TNTCity({
    required this.id,
    required this.districtId,
    required this.stateId,
    required this.countryId,
    required this.name,
    required this.nameTa,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  factory TNTCity.fromJson(Map<String, dynamic> json) {
    return TNTCity(
      id: json['id'] as String,
      districtId: json['district_id'] as String? ?? '',
      stateId: json['state_id'] as String? ?? '',
      countryId: json['country_id'] as String? ?? '',
      name: json['name'] as String,
      nameTa: json['name_ta'] as String? ?? json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'district_id': districtId,
    'state_id': stateId,
    'country_id': countryId,
    'name': name,
    'name_ta': nameTa,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
  };
}
