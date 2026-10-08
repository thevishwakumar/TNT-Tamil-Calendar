class CateringEnquiry {
  final String id;
  final String? userId;
  final String referenceCode;
  final String fullName;
  final String mobileNumber;
  final String eventType;
  final String? otherEventType;
  final DateTime eventDate;
  final int? guestCount;
  final String? eventLocation;
  final String? message;
  final String status;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? contactedAt;
  final String? notes;
  final String? assignedTo;

  CateringEnquiry({
    this.id = '',
    this.userId,
    required this.referenceCode,
    required this.fullName,
    required this.mobileNumber,
    required this.eventType,
    this.otherEventType,
    required this.eventDate,
    this.guestCount,
    this.eventLocation,
    this.message,
    this.status = 'new',
    this.source = 'tnt_app',
    required this.createdAt,
    required this.updatedAt,
    this.contactedAt,
    this.notes,
    this.assignedTo,
  });

  factory CateringEnquiry.fromJson(Map<String, dynamic> json) {
    return CateringEnquiry(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      referenceCode: json['reference_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      otherEventType: json['other_event_type']?.toString(),
      eventDate: json['event_date'] != null ? (DateTime.tryParse(json['event_date'].toString()) ?? DateTime.now()) : DateTime.now(),
      guestCount: json['guest_count'] != null ? int.tryParse(json['guest_count'].toString()) : null,
      eventLocation: json['event_location']?.toString(),
      message: json['message']?.toString(),
      status: json['status']?.toString() ?? 'new',
      source: json['source']?.toString() ?? 'tnt_app',
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      contactedAt: json['contacted_at'] != null ? DateTime.tryParse(json['contacted_at'].toString()) : null,
      notes: json['notes']?.toString(),
      assignedTo: json['assigned_to']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (userId != null) 'user_id': userId,
      'reference_code': referenceCode,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'event_type': eventType,
      'other_event_type': otherEventType,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'guest_count': guestCount,
      'event_location': eventLocation,
      'message': message,
      'status': status,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'contacted_at': contactedAt?.toIso8601String(),
      'notes': notes,
      'assigned_to': assignedTo,
    };
  }
}
