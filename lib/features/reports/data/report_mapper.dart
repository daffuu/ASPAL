import '../domain/models/report.dart';
import '../domain/models/sync_status.dart';

Map<String, Object?> contentToRow(ReportContent content) => {
  'category': content.category,
  'severity': content.severity,
  'description': content.description,
  'latitude': content.latitude,
  'longitude': content.longitude,
  'gps_accuracy': content.gpsAccuracy,
  'gps_source': content.gpsSource,
  'photo_local_path': content.photoLocalPath,
  'thumbnail_path': content.thumbnailPath,
  'photo_size_bytes': content.photoSizeBytes,
};

Map<String, Object?> reportToRow(Report report) => {
  ...contentToRow(report.content),
  'report_id': report.reportId,
  'user_id': report.userId,
  'created_at': report.createdAt.toUtc().toIso8601String(),
  'updated_at': report.updatedAt.toUtc().toIso8601String(),
  'sync_status': report.syncStatus.databaseValue,
  'retry_count': report.retryCount,
  'server_report_id': report.serverReportId,
  'road_condition': report.roadCondition,
  'photo_remote_url': report.photoRemoteUrl,
  'synced_at': report.syncedAt?.toUtc().toIso8601String(),
  'last_attempt_at': report.lastAttemptAt?.toUtc().toIso8601String(),
  'next_retry_at': report.nextRetryAt?.toUtc().toIso8601String(),
  'last_error_message': report.lastErrorMessage,
};

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toUtc();

Report reportFromRow(Map<String, Object?> row) => Report(
  reportId: row['report_id'] as String,
  userId: row['user_id'] as String,
  createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
  updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
  syncStatus: SyncStatus.fromDatabase(row['sync_status'] as String),
  retryCount: row['retry_count'] as int,
  serverReportId: row['server_report_id'] as String?,
  roadCondition: row['road_condition'] as String?,
  photoRemoteUrl: row['photo_remote_url'] as String?,
  syncedAt: _optionalDate(row['synced_at']),
  lastAttemptAt: _optionalDate(row['last_attempt_at']),
  nextRetryAt: _optionalDate(row['next_retry_at']),
  lastErrorMessage: row['last_error_message'] as String?,
  content: ReportContent(
    category: row['category'] as String?,
    severity: row['severity'] as String?,
    description: row['description'] as String?,
    latitude: row['latitude'] as double?,
    longitude: row['longitude'] as double?,
    gpsAccuracy: row['gps_accuracy'] as double?,
    gpsSource: row['gps_source'] as String?,
    photoLocalPath: row['photo_local_path'] as String?,
    thumbnailPath: row['thumbnail_path'] as String?,
    photoSizeBytes: row['photo_size_bytes'] as int?,
  ),
);
