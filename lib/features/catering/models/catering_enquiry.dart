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
      id: json['id'] ?? '',
      userId: json['user_id'],
      referenceCode: json['reference_code'] ?? '',
      fullName: json['full_name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      eventType: json['event_type'] ?? '',
      otherEventType: json['other_event_type'],
      eventDate: DateTime.parse(json['event_date']),
      guestCount: json['guest_count'],
      eventLocation: json['event_location'],
      message: json['message'],
      status: json['status'] ?? 'new',
      source: json['source'] ?? 'tnt_app',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      contactedAt: json['contacted_at'] != null ? DateTime.parse(json['contacted_at']) : null,
      notes: json['notes'],
      assignedTo: json['assigned_to'],
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
