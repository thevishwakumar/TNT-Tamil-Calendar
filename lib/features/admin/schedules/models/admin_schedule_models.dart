/// Operational internal admin schedule model
class AdminScheduleItem {
  final String id;
  final String title;
  final String? description;
  final String scheduleDate;
  final String startTime;
  final String endTime;
  final String category; // CONTENT_PREP, MANDAPAM, VERIFICATION, NOTIFICATIONS, MAINTENANCE, GENERAL
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final String status; // SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
  final String? mandapam;
  final String? eventType;
  final String? marriageDetails;
  final String? internalNotes; // Strictly confidential to ADMIN
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminScheduleItem({
    required this.id,
    required this.title,
    this.description,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.priority,
    required this.status,
    this.mandapam,
    this.eventType,
    this.marriageDetails,
    this.internalNotes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminScheduleItem.fromJson(Map<String, dynamic> json) {
    return AdminScheduleItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Internal Operational Task',
      description: json['description']?.toString(),
      scheduleDate: json['schedule_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '09:00 AM',
      endTime: json['end_time']?.toString() ?? '05:00 PM',
      category: json['category']?.toString() ?? 'GENERAL',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'SCHEDULED',
      mandapam: json['mandapam']?.toString(),
      eventType: json['event_type']?.toString(),
      marriageDetails: json['marriage_details']?.toString(),
      internalNotes: json['internal_notes']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'schedule_date': scheduleDate,
      'start_time': startTime,
      'end_time': endTime,
      'category': category,
      'priority': priority,
      'status': status,
      'mandapam': mandapam,
      'event_type': eventType,
      'marriage_details': marriageDetails,
      'internal_notes': internalNotes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Automated system cron job status model
class AutomatedCronJob {
  final String id;
  final String name;
  final String frequency;
  final String cronExpression;
  final String description;
  final String status; // IDLE, RUNNING, SUCCESS, FAILED
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
  final int? durationMs;
  final String? lastLogMessage;

  AutomatedCronJob({
    required this.id,
    required this.name,
    required this.frequency,
    required this.cronExpression,
    required this.description,
    required this.status,
    this.lastRunAt,
    this.nextRunAt,
    this.durationMs,
    this.lastLogMessage,
  });

  AutomatedCronJob copyWith({
    String? status,
    DateTime? lastRunAt,
    DateTime? nextRunAt,
    int? durationMs,
    String? lastLogMessage,
  }) {
    return AutomatedCronJob(
      id: id,
      name: name,
      frequency: frequency,
      cronExpression: cronExpression,
      description: description,
      status: status ?? this.status,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      durationMs: durationMs ?? this.durationMs,
      lastLogMessage: lastLogMessage ?? this.lastLogMessage,
    );
  }
}
