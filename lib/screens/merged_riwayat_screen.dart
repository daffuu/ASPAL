import 'package:flutter/material.dart';

import '../data/report_repository.dart';
import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widgets/severity.dart';
import '../widgets/status_badge.dart';

// ============================================================
// KONSTANTA
// ============================================================
const List<String> _kCategories = ['Lubang', 'Retak', 'Amblas', 'Genangan'];

// ============================================================
// HALAMAN UTAMA: RIWAYAT LAPORAN (FR-13, FR-14, FR-16)
// ============================================================
class MergedRiwayatScreen extends StatefulWidget {
  const MergedRiwayatScreen({super.key});

  @override
  State<MergedRiwayatScreen> createState() => _MergedRiwayatScreenState();
}

class _MergedRiwayatScreenState extends State<MergedRiwayatScreen> {
  String _selectedFilter = 'Semua';

  List<Report> get _reports => ReportRepository.reports;

  // --- GETTER STATISTIK (FR-16) ---
  int get _countDraft =>
      _reports.where((e) => e.status == ReportStatus.draft).length;
  int get _countMenunggu =>
      _reports.where((e) => e.status == ReportStatus.menungguSinyal).length;
  int get _countGagal =>
      _reports.where((e) => e.status == ReportStatus.gagalTerkirim).length;
  int get _countTerkirim =>
      _reports.where((e) => e.status == ReportStatus.terkirim).length;

  // --- FILTER (FR-14) ---
  List<Report> get _filteredReports {
    switch (_selectedFilter) {
      case 'Draft':
        return _reports
            .where((e) => e.status == ReportStatus.draft)
            .toList();
      case 'Menunggu':
        return _reports
            .where((e) => e.status == ReportStatus.menungguSinyal)
            .toList();
      case 'Gagal':
        return _reports
            .where((e) => e.status == ReportStatus.gagalTerkirim)
            .toList();
      case 'Terkirim':
        return _reports
            .where((e) => e.status == ReportStatus.terkirim)
            .toList();
      default:
        return _reports;
    }
  }

  // --- HAPUS LAPORAN (FR-07) ---
  void _handleHapus(Report report) {
    // Validasi: menunggu sinyal / mengirim / terkirim TIDAK BISA dihapus
    if (!report.status.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Laporan dengan status ini tidak dapat dihapus'),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Laporan?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${report.id}" dari penyimpanan lokal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                ReportRepository.reports
                    .removeWhere((e) => e.id == report.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Laporan "${report.id}" berhasil dihapus'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- KIRIM ULANG (FR-10) ---
  void _handleKirimUlang(Report report) {
    final i = _reports.indexWhere((e) => e.id == report.id);
    if (i == -1) return;
    setState(() {
      ReportRepository.reports[i] =
          report.copyWith(status: ReportStatus.menungguSinyal, retryCount: 0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.sync, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Laporan masuk kembali ke antrean sinkronisasi'),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- BUKA DETAIL (FR-15) ---
  Future<void> _openDetail(Report report) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(report: report),
      ),
    );
    if (mounted) setState(() {}); // refresh setelah kembali
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final reports = _filteredReports;

    return Column(
      children: [
        // Summary counters
        _buildSummaryCounter(),
        // Filter chips (FR-14)
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              'Semua',
              'Draft',
              'Menunggu',
              'Gagal',
              'Terkirim',
            ].map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (_) =>
                      setState(() => _selectedFilter = filter),
                  selectedColor: const Color(0xFFDBEAFE),
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: _selectedFilter == filter
                        ? const Color(0xFF93C5FD)
                        : AppColors.border,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Report list
        Expanded(
          child: reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: AppColors.textMuted.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada laporan pada kategori ini',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) =>
                      _buildReportCard(reports[index]),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // SUMMARY COUNTER (FR-16)
  // ==========================================
  Widget _buildSummaryCounter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CounterItem(
              count: '$_countDraft',
              label: 'DRAFT',
              color: const Color(0xFF475569)),
          _divider(),
          _CounterItem(
              count: '$_countMenunggu',
              label: 'MENUNGGU',
              color: const Color(0xFFD97706)),
          _divider(),
          _CounterItem(
              count: '$_countGagal',
              label: 'GAGAL',
              color: AppColors.danger),
          _divider(),
          _CounterItem(
              count: '$_countTerkirim',
              label: 'TERKIRIM',
              color: AppColors.success),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(height: 32, width: 1, color: AppColors.border);

  // ==========================================
  // REPORT CARD
  // ==========================================
  Widget _buildReportCard(Report report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetail(report),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Top row: thumbnail + info + badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    Stack(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: report.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    report.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                        Icons.image,
                                        color: AppColors.textMuted,
                                        size: 24),
                                  ),
                                )
                              : const Icon(Icons.image,
                                  color: AppColors.textMuted, size: 24),
                        ),
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2),
                              ],
                            ),
                            child: _statusIcon(report.status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Title, coords, time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report.id} · ${report.type}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  report.coordinates,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 12,
                                  color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                report.time,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                // Bottom row: info + actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sub info
                    Expanded(
                      child: Text(
                        _getSubInfo(report),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getSubInfoColor(report.status),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Action buttons
                    _buildActions(report),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _statusIcon(ReportStatus status) {
    return switch (status) {
      ReportStatus.draft =>
        const Icon(Icons.edit_note, size: 12, color: Color(0xFF475569)),
      ReportStatus.menungguSinyal =>
        const Icon(Icons.sync, size: 12, color: Color(0xFFD97706)),
      ReportStatus.mengirim =>
        const Icon(Icons.cloud_upload, size: 12, color: Color(0xFF1E40AF)),
      ReportStatus.gagalTerkirim =>
        const Icon(Icons.priority_high, size: 12, color: Color(0xFFDC2626)),
      ReportStatus.terkirim =>
        const Icon(Icons.check, size: 12, color: Color(0xFF16A34A)),
    };
  }

  String _getSubInfo(Report report) {
    return switch (report.status) {
      ReportStatus.draft => 'Tersimpan di perangkat',
      ReportStatus.menungguSinyal => 'Dalam antrean sinkronisasi',
      ReportStatus.mengirim => 'Sedang mengirim...',
      ReportStatus.gagalTerkirim =>
        report.lastErrorMessage ?? 'Gagal setelah ${report.retryCount}x percobaan',
      ReportStatus.terkirim => 'Berhasil tersinkron ke server',
    };
  }

  Color _getSubInfoColor(ReportStatus status) {
    return switch (status) {
      ReportStatus.draft => AppColors.textMuted,
      ReportStatus.menungguSinyal => const Color(0xFFB45309),
      ReportStatus.mengirim => AppColors.primary,
      ReportStatus.gagalTerkirim => AppColors.danger,
      ReportStatus.terkirim => const Color(0xFF15803D),
    };
  }

  Widget _buildActions(Report report) {
    switch (report.status) {
      case ReportStatus.draft:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionChip(
              icon: Icons.edit,
              label: 'Edit',
              color: AppColors.primary,
              borderColor: const Color(0xFFBFDBFE),
              onTap: () => _openDetail(report),
            ),
            const SizedBox(width: 6),
            _ActionChip(
              icon: Icons.delete_outline,
              label: 'Hapus',
              color: AppColors.danger,
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              onTap: () => _handleHapus(report),
            ),
          ],
        );
      case ReportStatus.menungguSinyal:
      case ReportStatus.mengirim:
        return _ActionChip(
          icon: Icons.lock_outline,
          label: 'Dikunci',
          color: AppColors.textMuted,
          bgColor: AppColors.surfaceDim,
          borderColor: AppColors.border,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Laporan dikunci selama proses sinkronisasi'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        );
      case ReportStatus.gagalTerkirim:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionChip(
              icon: Icons.refresh,
              label: 'Kirim ulang',
              color: const Color(0xFF0D9488),
              borderColor: const Color(0xFF99F6E4),
              onTap: () => _handleKirimUlang(report),
            ),
            const SizedBox(width: 6),
            _ActionChip(
              icon: Icons.delete_outline,
              label: 'Hapus',
              color: AppColors.danger,
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              onTap: () => _handleHapus(report),
            ),
          ],
        );
      case ReportStatus.terkirim:
        return _ActionChip(
          icon: Icons.visibility_outlined,
          label: 'Lihat',
          color: AppColors.primary,
          borderColor: const Color(0xFFBFDBFE),
          onTap: () => _openDetail(report),
        );
    }
  }
}

// ==========================================
// COUNTER ITEM WIDGET
// ==========================================
class _CounterItem extends StatelessWidget {
  const _CounterItem({
    required this.count,
    required this.label,
    required this.color,
  });
  final String count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// ACTION CHIP BUTTON
// ==========================================
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

// ============================================================
// LAYAR 2: DETAIL LAPORAN (FR-15)
// ============================================================
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.report});
  final Report report;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Report _report;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openEdit() async {
    // FR-06: validasi sebelum form dibuka
    if (!_report.status.canEdit) {
      _showSnack(
        'Laporan dengan status "${_report.status.label}" tidak bisa diedit.',
        isError: true,
      );
      return;
    }

    final before = _report.status;

    final result = await Navigator.push<Report>(
      context,
      MaterialPageRoute(
        builder: (_) => EditReportScreen(report: _report),
      ),
    );
    if (!mounted || result == null) return;

    setState(() => _report = result);
    _showSnack(
      before == ReportStatus.gagalTerkirim
          ? 'Perubahan disimpan. Laporan kembali ke antrean (Draft).'
          : 'Perubahan berhasil disimpan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final canEdit = r.status.canEdit;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Detail ${r.id}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _statusBannerBg(r.status),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusBannerBorder(r.status)),
            ),
            child: Row(
              children: [
                StatusBadge(status: r.status, large: true),
                if (r.lastErrorMessage != null &&
                    r.status == ReportStatus.gagalTerkirim) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.lastErrorMessage!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.danger),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info grid
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Kategori',
                  value: r.type,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'Keparahan',
                  value: '${r.severity} - ${severityLabels[r.severity]}',
                  icon: Icons.speed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Waktu',
                  value: r.time,
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'GPS Source',
                  value: r.gpsSource ?? '-',
                  icon: Icons.gps_fixed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Koordinat
          _InfoTile(
            label: 'Koordinat',
            value: r.coordinates,
            icon: Icons.place_outlined,
          ),
          const SizedBox(height: 16),

          // Deskripsi
          if (r.notes.isNotEmpty) ...[
            const _SectionLabel('Deskripsi'),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                r.notes,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: AppColors.text),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Edit button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor:
                  canEdit ? AppColors.primary : AppColors.textMuted,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(canEdit ? Icons.edit : Icons.lock_outline, size: 18),
            label: Text(canEdit ? 'Edit Laporan' : 'Tidak Dapat Diedit'),
            onPressed: _openEdit,
          ),
        ],
      ),
    );
  }

  Color _statusBannerBg(ReportStatus s) => switch (s) {
        ReportStatus.draft => AppColors.surfaceDim,
        ReportStatus.menungguSinyal => AppColors.warningBg,
        ReportStatus.mengirim => const Color(0xFFDBEAFE),
        ReportStatus.gagalTerkirim => AppColors.dangerBg,
        ReportStatus.terkirim => AppColors.successBg,
      };

  Color _statusBannerBorder(ReportStatus s) => switch (s) {
        ReportStatus.draft => AppColors.border,
        ReportStatus.menungguSinyal => const Color(0xFFFDE68A),
        ReportStatus.mengirim => const Color(0xFF93C5FD),
        ReportStatus.gagalTerkirim => const Color(0xFFFECACA),
        ReportStatus.terkirim => const Color(0xFFBBF7D0),
      };
}

// ============================================================
// LAYAR 3: FORM EDIT (FR-06)
// ============================================================
class EditReportScreen extends StatefulWidget {
  const EditReportScreen({super.key, required this.report});
  final Report report;

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descController;
  late String _category;
  late int _severity;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.report.type;
    _severity = widget.report.severity;
    _descController = TextEditingController(text: widget.report.notes);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _category != widget.report.type ||
      _severity != widget.report.severity ||
      _descController.text.trim() != widget.report.notes.trim();

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Simulasi tulis database
      await Future.delayed(const Duration(seconds: 2));

      // FR-06: Gagal Terkirim yang diedit kembali jadi Draft
      final updated = widget.report.copyWith(
        type: _category,
        severity: _severity,
        notes: _descController.text.trim(),
        status: ReportStatus.draft,
        retryCount: 0,
        lastErrorMessage: null,
      );

      // Update di repository
      final i =
          ReportRepository.reports.indexWhere((r) => r.id == updated.id);
      if (i != -1) {
        ReportRepository.reports[i] = updated;
      }

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan perubahan. Coba lagi.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty && !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Buang perubahan?',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content:
                const Text('Data yang belum disimpan akan hilang.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Lanjut edit'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Buang',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Edit ${widget.report.id}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Locked info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATA TERKUNCI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _lockedRow(
                        Icons.place_outlined, widget.report.coordinates),
                    const SizedBox(height: 4),
                    _lockedRow(Icons.schedule, widget.report.time),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration('Kategori'),
                items: [
                  for (final c in _kCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: _isSaving
                    ? null
                    : (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Severity dropdown
              DropdownButtonFormField<int>(
                initialValue: _severity,
                decoration: _inputDecoration('Keparahan'),
                items: [
                  for (var i = 0; i < severityLabels.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text('$i - ${severityLabels[i]}'),
                    ),
                ],
                onChanged: _isSaving
                    ? null
                    : (v) => setState(() => _severity = v!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                enabled: !_isSaving,
                maxLines: 4,
                maxLength: 300,
                decoration: _inputDecoration('Deskripsi'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Deskripsi wajib diisi';
                  if (text.length < 10) {
                    return 'Minimal 10 karakter (kurang ${10 - text.length})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Save button
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed:
                    (_isDirty && !_isSaving) ? _handleSave : null,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),

              if (!_isDirty && !_isSaving)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Ubah minimal satu data untuk bisa menyimpan.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lockedRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
