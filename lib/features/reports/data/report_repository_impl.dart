import 'package:uuid/uuid.dart';

import '../../auth/domain/repositories/token_provider.dart';
import '../domain/models/report.dart';
import '../domain/models/report_validation.dart';
import '../domain/models/sync_status.dart';
import '../domain/repositories/report_repository.dart';
import 'report_local_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._local, this._auth);
  final ReportLocalDataSource _local;
  final TokenProvider _auth;

  Future<String> _userId() async =>
      await _auth.getUserId() ?? (throw StateError('Tidak ada sesi aktif'));

  @override
  Future<Report> createReport([
    ReportContent content = const ReportContent(),
  ]) async {
    return _create(content, SyncStatus.draft);
  }

  @override
  Future<void> submitReport(ReportContent content, {String? reportId}) async {
    validateSubmission(content);
    if (reportId == null) {
      await _create(content, SyncStatus.menungguSinyal);
    } else if (!await _local.update(
      await _userId(),
      reportId,
      content,
      queue: true,
    )) {
      throw StateError("Laporan terkunci atau tidak tersedia untuk akun ini.");
    }
  }

  Future<Report> _create(ReportContent content, SyncStatus status) async {
    final userId = await _userId();
    final now = DateTime.now().toUtc();
    final report = Report(
      reportId: const Uuid().v4(),
      userId: userId,
      createdAt: now,
      updatedAt: now,
      content: content,
      syncStatus: status,
    );
    await _local.insert(report);
    return report;
  }

  @override
  Future<Report?> getReportById(String reportId) async =>
      _local.getById(await _userId(), reportId);

  @override
  Future<List<Report>> getReportsByUser() async => _local.list(await _userId());

  @override
  Future<List<Report>> getReportsByStatus(SyncStatus status) async =>
      _local.list(await _userId(), status: status);

  @override
  Future<bool> updateReport(String reportId, ReportContent content) async =>
      _local.update(await _userId(), reportId, content);

  @override
  Future<bool> deleteReport(String reportId) async =>
      _local.delete(await _userId(), reportId);

  @override
  Future<int> countUnsentReports() async => _local.countUnsent(await _userId());

  @override
  Future<void> clearUserData() async => _local.clearUserData(await _userId());
}
