enum HelpType {
  flood,
  trapped,
  medical,
  fire,
  roadBlocked,
  other,
}

enum HelpSeverity {
  low,
  medium,
  high,
  critical,
}

enum HelpReportStatus {
  created,
  pending,
  syncing,
  synced,
  syncFailed,
}

extension HelpTypeExtension on HelpType {
  String get value {
    switch (this) {
      case HelpType.flood:
        return 'FLOOD';
      case HelpType.trapped:
        return 'TRAPPED';
      case HelpType.medical:
        return 'MEDICAL';
      case HelpType.fire:
        return 'FIRE';
      case HelpType.roadBlocked:
        return 'ROAD_BLOCKED';
      case HelpType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case HelpType.flood:
        return 'Flood';
      case HelpType.trapped:
        return 'Trapped';
      case HelpType.medical:
        return 'Medical';
      case HelpType.fire:
        return 'Fire';
      case HelpType.roadBlocked:
        return 'Road blocked';
      case HelpType.other:
        return 'Other';
    }
  }
}

extension HelpSeverityExtension on HelpSeverity {
  String get value {
    switch (this) {
      case HelpSeverity.low:
        return 'LOW';
      case HelpSeverity.medium:
        return 'MEDIUM';
      case HelpSeverity.high:
        return 'HIGH';
      case HelpSeverity.critical:
        return 'CRITICAL';
    }
  }

  String get label {
    switch (this) {
      case HelpSeverity.low:
        return 'Low';
      case HelpSeverity.medium:
        return 'Medium';
      case HelpSeverity.high:
        return 'High';
      case HelpSeverity.critical:
        return 'Critical';
    }
  }
}

extension HelpReportStatusExtension on HelpReportStatus {
  String get value {
    switch (this) {
      case HelpReportStatus.created:
        return 'CREATED';
      case HelpReportStatus.pending:
        return 'PENDING';
      case HelpReportStatus.syncing:
        return 'SYNCING';
      case HelpReportStatus.synced:
        return 'SYNCED';
      case HelpReportStatus.syncFailed:
        return 'SYNC_FAILED';
    }
  }
}

class HelpReport {
  final String id;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final double? accuracyM;
  final HelpType type;
  final HelpSeverity severity;
  final String description;
  final HelpReportStatus status;

  const HelpReport({
    required this.id,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.type,
    required this.severity,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_m': accuracyM,
      'type': type.value,
      'severity': severity.value,
      'description': description,
      'status': status.value,
    };
  }
}