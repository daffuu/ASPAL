import '../models/report.dart';
import '../models/sync_status.dart';

/// All operations use the active account from Auth.
abstract interface class ReportRepository {
  Future<Report> createReport([ReportContent content = const ReportContent()]);
  Future<void> submitReport(ReportContent content, {String? reportId});
  Future<Report?> getReportById(String reportId);
  Future<List<Report>> getReportsByUser();
  Future<List<Report>> getReportsByStatus(SyncStatus status);

  /// Replaces editable fields. Returns false for missing or locked records.
  Future<bool> updateReport(String reportId, ReportContent content);
  Future<bool> deleteReport(String reportId);
  Future<int> countUnsentReports();
  Future<void> clearUserData();
}
