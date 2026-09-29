import 'package:flutter/material.dart';

import '../data/report_repository.dart';
import '../models/report.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import '../widgets/state_views.dart';

// (1) status tampilan
enum ViewStatus { loading, success, error }

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // (2) variabel state
  final _repository = ReportRepository();
  ViewStatus _status = ViewStatus.loading;
  List<Report> _reports = [];
  String _errorMessage = '';
  bool _simulateError = false; // ubah ke true untuk menguji error state

  // (3) ambil data saat layar pertama kali dibuka
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // (4) mengambil data + menangani error
  Future<void> _loadReports() async {
    if (_status != ViewStatus.loading) {
      setState(() => _status = ViewStatus.loading);
    }
    try {
      final reports =
          await _repository.fetchReports(simulateError: _simulateError);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _status = ViewStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _status = ViewStatus.error;
      });
    }
  }

  // (5) isi layar tergantung status
  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  // (6) memilih tampilan: loading / error / empty / daftar data
  Widget _buildContent() {
    return switch (_status) {
      ViewStatus.loading => const LoadingView(),
      ViewStatus.error =>
        ErrorView(message: _errorMessage, onRetry: _loadReports),
      ViewStatus.success => _buildList(),
    };
  }

  Widget _buildList() {
    if (_reports.isEmpty) {
      return const EmptyView(message: 'Belum ada data.');
    }
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
          const SizedBox(height: 16),
          for (final r in _reports) ...[
            ReportCard(
              location: r.coordinates,
              time: r.time,
              imageUrl: r.imageUrl,
              status: r.status,
              // (7) kirim laporan yang dipilih ke layar Detail
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.detail,
                arguments: r,
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
