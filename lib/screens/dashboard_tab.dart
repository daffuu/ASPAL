import 'package:flutter/material.dart';

import '../data/report_repository.dart';
import '../models/road_report.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.isOnline});

  final bool isOnline;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _repository = const ReportRepository();
  List<RoadReport> _reports = const [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  // ignore: prefer_final_fields
  bool _simulateError = false; // ubah ke true untuk menguji error state

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (_simulateError) {
        throw Exception('Simulasi error');
      }

      final reports = await _repository.fetchReports();
      if (!mounted) return;
      setState(() => _reports = reports);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Laporan gagal dimuat.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MetricsCard(),
          const SizedBox(height: 24),
          const Text(
            'Riwayat Laporan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.reportHistory),
              icon: const Icon(Icons.history),
              label: const Text('Lihat Riwayat Laporan'),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_hasError)
            Center(
              child: Column(
                children: [
                  Text(_errorMessage.isEmpty ? 'Laporan gagal dimuat.' : _errorMessage),
                  TextButton.icon(
                    onPressed: _loadReports,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (_reports.isEmpty)
            const Center(child: Text('Belum ada laporan.'))
          else
            for (final report in _reports) ...[
              ReportCard(
                location: report.coordinates,
                time: report.time,
                imageUrl: report.imageUrl,
                status: report.status,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.detail,
                  arguments: ReportDetailArguments(
                    report: report,
                    isOnline: widget.isOnline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _Metric(value: '3', label: 'Menunggu\nSinyal', color: AppColors.warning),
          Container(width: 1, height: 40, color: AppColors.border),
          const _Metric(value: '12', label: 'Terkirim', color: AppColors.success),
          Container(width: 1, height: 40, color: AppColors.border),
          const _Metric(value: '1', label: 'Gagal\nKirim', color: AppColors.danger),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
