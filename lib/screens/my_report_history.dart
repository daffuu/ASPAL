import 'package:flutter/material.dart';

import '../features/reports/domain/models/report.dart';
import '../features/reports/domain/models/sync_status.dart';
import '../features/reports/domain/repositories/report_repository.dart';
import '../features/reports/presentation/report_presentation.dart';
import '../widgets/state_views.dart';
import 'my_report_detail.dart';

class MyReportHistory extends StatefulWidget {
  const MyReportHistory({
    super.key,
    required this.repository,
    this.active = true,
  });
  final ReportRepository repository;
  final bool active;
  @override
  State<MyReportHistory> createState() => _MyReportHistoryState();
}

class _MyReportHistoryState extends State<MyReportHistory> {
  SyncStatus? _filter;
  Future<List<Report>>? _rows;
  void _load() {
    final status = _filter;
    _rows = status == null
        ? widget.repository.getReportsByUser()
        : widget.repository.getReportsByStatus(status);
  }

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(MyReportHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active || widget.repository != oldWidget.repository)) {
      _load();
    }
  }

  Future<void> _open(String id) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MyReportDetail(reportId: id, repository: widget.repository),
      ),
    );
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final status in <SyncStatus?>[null, ...SyncStatus.values])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status?.label ?? 'Semua'),
                  selected: _filter == status,
                  onSelected: (_) {
                    if (_filter != status) {
                      setState(() {
                        _filter = status;
                        _load();
                      });
                    }
                  },
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Report>>(
          future: _rows,
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return widget.active
                  ? const LoadingView(message: 'Memuat riwayat…')
                  : const SizedBox.shrink();
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: 'Riwayat belum dapat dibaca dari perangkat.',
                onRetry: () => setState(_load),
              );
            }
            final rows = snapshot.requireData;
            if (rows.isEmpty) {
              return EmptyView(
                message: _filter == null
                    ? 'Belum ada laporan.'
                    : 'Tidak ada laporan dengan status ${_filter!.label}.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (_, index) {
                final report = rows[index];
                final data = report.content;
                return Card(
                  key: ValueKey(report.reportId),
                  child: ListTile(
                    leading: ReportPhoto(data, small: true),
                    title: Text(data.category ?? 'Kategori belum dipilih'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.severity != null) Text(data.severity!),
                        if (data.description != null)
                          Text(
                            data.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(reportTime(report.createdAt)),
                        ReportStatusLabel(report.syncStatus),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(report.reportId),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
