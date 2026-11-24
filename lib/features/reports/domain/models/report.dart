import 'sync_status.dart';

/// Editable fields of a draft. A null value clears that field on save.
class ReportContent {
  const ReportContent({
    this.category,
    this.severity,
    this.description,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.gpsSource,
    this.photoLocalPath,
    this.thumbnailPath,
    this.photoSizeBytes,
  });
  final String? category;
  final String? severity;
  final String? description;
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;
  final String? gpsSource;
  final String? photoLocalPath;
  final String? thumbnailPath;
  final int? photoSizeBytes;
}

class Report {
  final ReportContent content;
  final String reportId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final int retryCount;
  final String? serverReportId;
  final String? roadCondition;
  final String? photoRemoteUrl;
  final DateTime? syncedAt;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final String? lastErrorMessage;

  const Report({
    this.content = const ReportContent(),
    required this.reportId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.draft,
    this.retryCount = 0,
    this.serverReportId,
    this.roadCondition,
    this.photoRemoteUrl,
    this.syncedAt,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.lastErrorMessage,
  });
}
