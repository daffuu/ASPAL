import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_scope.dart';
import '../features/reports/domain/models/report.dart';
import '../features/reports/domain/models/sync_status.dart';
import '../features/reports/domain/repositories/report_repository.dart';
import '../features/reports/presentation/report_presentation.dart';
import '../features/reports/presentation/report_location_map.dart';
import '../features/reports/report_form_service.dart';
import '../widgets/state_views.dart';
import 'offline_geotagging_camera.dart';

class MyReportDetail extends StatefulWidget {
  const MyReportDetail({
    super.key,
    required this.reportId,
    required this.repository,
  });
  final String reportId;
  final ReportRepository repository;
  @override
  State<MyReportDetail> createState() => _MyReportDetailState();
}

class _MyReportDetailState extends State<MyReportDetail> {
  Future<Report?>? _report;
  String? _account;
  void _load() {
    _report = widget.repository.getReportById(widget.reportId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.maybeAuthController?.currentUser?.userId;
    if (_report == null || _account != id) {
      _account = id;
      _load();
    }
  }

  @override
  void didUpdateWidget(MyReportDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reportId != oldWidget.reportId ||
        widget.repository != oldWidget.repository) {
      _load();
    }
  }

  Future<void> _manage(Report report) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Kelola laporan')),
          body: OfflineGeotaggingCamera(
            initialReport: report,
            service: ReportFormService(widget.repository),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (deleted == true) {
      Navigator.pop(context);
    } else {
      setState(_load);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail laporan')),
    body: FutureBuilder<Report?>(
      future: _report,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: 'Detail laporan belum dapat dibaca.',
            onRetry: () => setState(_load),
          );
        }
        final report = snapshot.data;
        if (report == null) {
          return const EmptyView(
            message: 'Laporan tidak tersedia untuk akun ini.',
          );
        }
        final data = report.content;
        final error = report.lastErrorMessage?.trim();
        final fields = <String, String>{
          'Kategori': data.category ?? 'Kategori belum dipilih',
          'Tingkat keparahan': data.severity ?? 'Belum diisi',
          'Deskripsi': data.description ?? 'Belum diisi',
          'Latitude': data.latitude?.toString() ?? 'Belum tersedia',
          'Longitude': data.longitude?.toString() ?? 'Belum tersedia',
          if (data.gpsSource != null)
            'Sumber lokasi': switch (data.gpsSource) {
              'camera' => 'GPS kamera',
              'manual' => 'Koordinat manual',
              _ => 'Sumber lain',
            },
          if (data.gpsAccuracy != null) 'Akurasi GPS': '${data.gpsAccuracy} m',
          'Dilaporkan': reportTime(report.createdAt),
          'Diperbarui': reportTime(report.updatedAt),
        };
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ReportPhoto(data),
            const SizedBox(height: 12),
            ReportStatusLabel(report.syncStatus),
            ReportLocationMap(
              latitude: data.latitude,
              longitude: data.longitude,
            ),
            if (report.syncStatus == SyncStatus.gagalTerkirim &&
                error != null &&
                error.isNotEmpty)
              ErrorBanner(
                message:
                    RegExp(
                      r'Exception|StackTrace|#\d+\s|package:|https?://',
                      caseSensitive: false,
                    ).hasMatch(error)
                    ? 'Pengiriman gagal.'
                    : 'Gagal dikirim: ${error.split('\n').first}',
              ),
            for (final entry in fields.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                subtitle: Text(entry.value),
              ),
            if (report.syncStatus.editable)
              OutlinedButton.icon(
                onPressed: () => _manage(report),
                icon: const Icon(Icons.edit_note),
                label: const Text('Edit atau hapus laporan'),
              ),
          ],
        );
      },
    ),
  );
}
