import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../app_modules.dart';
import '../features/reports/data/report_capture.dart';
import '../features/reports/domain/models/report.dart';
import '../features/reports/domain/models/sync_status.dart';
import '../features/reports/report_form_service.dart';
import '../features/reports/presentation/report_location_map.dart';

import '../theme/app_theme.dart';
import '../data/report_repository.dart' show kCategories, kSeverityLabels;

// ==========================================
// HALAMAN UTAMA: KAMERA + GEO-TAGGING (FR-01, FR-02, FR-03)
// ==========================================
class OfflineGeotaggingCamera extends StatefulWidget {
  const OfflineGeotaggingCamera({
    super.key,
    this.service,
    this.capture,
    this.initialReport,
  });
  final Report? initialReport;
  final ReportFormService? service;
  final ReportCapture? capture;

  @override
  State<OfflineGeotaggingCamera> createState() =>
      _OfflineGeotaggingCameraState();
}

class _OfflineGeotaggingCameraState extends State<OfflineGeotaggingCamera> {
  File? _imageFile;
  Uint8List? _imageBytes;
  late final _service =
      widget.service ?? ReportFormService(reportsModule.repository);
  late final _capture = widget.capture ?? ReportCapture();
  Report? _editing;
  double? _latitude, _longitude, _accuracy;
  String _gpsSource = '';
  bool _busy = false;

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _getImage(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final photo = await _capture.capture(source);
      if (photo == null || !mounted) return;
      setState(() {
        _imageBytes = photo.bytes;
        _imageFile = null;
        _gpsSource = photo.source;
        _latitude = photo.location?.latitude;
        _longitude = photo.location?.longitude;
        _accuracy = photo.location?.accuracy;
      });
      if (photo.warning != null) {
        _message('${photo.warning} Foto dapat disimpan sebagai draft.');
      }
    } on PlatformException {
      if (mounted) {
        _message('Akses kamera atau galeri gagal. Periksa izin aplikasi.');
      }
    } catch (_) {
      if (mounted) {
        _message('Gagal membaca atau memperkecil foto. Pilih foto lain.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null) _load(widget.initialReport);
  }

  void _load(Report? report) {
    final data = report?.content;
    setState(() {
      _editing = report;
      _imageBytes = null;
      _imageFile = data?.photoLocalPath == null
          ? null
          : File(data!.photoLocalPath!);
      _latitude = data?.latitude;
      _longitude = data?.longitude;
      _accuracy = data?.gpsAccuracy;
      _gpsSource = data?.gpsSource ?? '';
    });
  }

  Future<void> _chooseDraft() async {
    setState(() => _busy = true);
    try {
      final rows = (await _service.repository.getReportsByUser())
          .where(
            (r) =>
                r.syncStatus == SyncStatus.draft ||
                r.syncStatus == SyncStatus.gagalTerkirim,
          )
          .toList();
      if (!mounted) return;
      if (rows.isEmpty) {
        _message('Belum ada laporan yang dapat diedit.');
        return;
      }
      setState(() => _busy = false);
      final selected = await showModalBottomSheet<Report>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rows.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(
                rows[i].content.description ??
                    rows[i].content.category ??
                    'Draft tanpa judul',
              ),
              subtitle: Text(
                '${rows[i].syncStatus.databaseValue} · ${rows[i].updatedAt.toLocal()}',
              ),
              onTap: () => Navigator.pop(ctx, rows[i]),
            ),
          ),
        ),
      );
      if (mounted && selected != null) _load(selected);
    } catch (error) {
      if (mounted) _message(_formError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final report = _editing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus laporan ini?'),
        content: const Text('Laporan dan salinan foto lokal akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      final deleted = await _service.repository.deleteReport(report.reportId);
      if (!mounted) return;
      if (deleted && widget.initialReport != null) {
        Navigator.pop(context, true);
        return;
      }
      _load(null);
      _message(
        deleted
            ? 'Laporan dihapus.'
            : 'Laporan terkunci atau tidak tersedia untuk akun ini.',
      );
    } catch (error) {
      if (mounted) _message(_formError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surface,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ambil foto langsung atau pilih dari galeri',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                _PickerOption(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppColors.primary,
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Ambil dari Kamera',
                  subtitle: 'GPS otomatis terkunci',
                  onTap: () {
                    Navigator.pop(ctx);
                    _getImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _PickerOption(
                  icon: Icons.photo_library_rounded,
                  iconColor: AppColors.success,
                  iconBg: const Color(0xFFECFDF5),
                  title: 'Pilih dari Galeri',
                  subtitle: 'Isi koordinat GPS secara manual',
                  onTap: () {
                    Navigator.pop(ctx);
                    _getImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- VALIDASI & NAVIGASI KE FORM DETAIL ---
  Future<void> _validateAndNext() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailLaporanForm(
          service: _service,
          editing: _editing,
          imageFile: _imageFile,
          imageBytes: _imageBytes,
          latitude: _latitude,
          longitude: _longitude,
          gpsSource: _gpsSource,
          accuracy: _accuracy,
        ),
      ),
    );
    if (saved != true || !mounted) return;
    if (widget.initialReport == null) {
      _load(null);
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '📸 OFFLINE GEO-TAGGING',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bukti Foto & Titik GPS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk kotak di bawah untuk mengambil foto kerusakan jalan.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (_busy) const LinearProgressIndicator(),
          if (_editing == null)
            TextButton.icon(
              onPressed: _busy ? null : _chooseDraft,
              icon: const Icon(Icons.edit_note),
              label: const Text('Buka laporan untuk diedit'),
            )
          else ...[
            Text(
              'Mengedit: ${_editing!.content.description ?? _editing!.reportId}',
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (widget.initialReport == null) {
                            _load(null);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                  child: const Text('Batal edit'),
                ),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  child: const Text('Hapus laporan'),
                ),
              ],
            ),
          ],
          // Photo picker area
          GestureDetector(
            onTap: _busy ? null : () => _showPickerOptions(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: (_imageBytes != null || _imageFile != null)
                    ? Colors.transparent
                    : const Color(0xFFEFF6FF).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_imageBytes != null || _imageFile != null)
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: (_imageBytes != null || _imageFile != null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_imageBytes != null)
                            Image.memory(_imageBytes!, fit: BoxFit.cover)
                          else if (_imageFile != null)
                            Image.file(
                              _imageFile!,
                              errorBuilder: (_, error, stack) => const Text(
                                'Foto tidak ditemukan. Pilih foto pengganti.',
                              ),
                              fit: BoxFit.cover,
                            ),
                          // Overlay gradient
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [Color(0x66000000), Color(0x00000000)],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x80000000),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Foto terpilih',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ambil / Pilih Foto',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kamera atau Galeri',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // GPS Info Card
          if (_imageFile != null || _imageBytes != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _gpsSource == 'camera'
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gpsSource == 'camera'
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFFED7AA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: _gpsSource == 'camera'
                            ? AppColors.primary
                            : AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsSource == 'camera'
                              ? (_latitude == null
                                    ? 'GPS belum tersedia'
                                    : 'Koordinat GPS Terkunci (Otomatis)')
                              : 'Koordinat GPS (Manual dari Galeri)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _gpsSource == 'camera'
                                ? AppColors.primary
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_busy)
                    const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Membaca titik satelit GPS...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      'Latitude : ${_latitude ?? "—"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Longitude: ${_longitude ?? "—"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Remove photo button
          if (_imageBytes != null || _imageFile != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _imageBytes = null;
                    _imageFile = null;
                    _accuracy = null;
                    _latitude = null;
                    _longitude = null;
                    _gpsSource = '';
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 16,
                ),
                label: const Text(
                  'Hapus Foto',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Next button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _validateAndNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Selanjutnya (Isi Detail Laporan)'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PICKER OPTION TILE (BOTTOM SHEET)
// ==========================================
class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN DETAIL LAPORAN / FORM DRAFT (FR-03, FR-04, FR-05)
// ==========================================
class _DetailLaporanForm extends StatefulWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final ReportFormService service;
  final Report? editing;
  final double? accuracy;
  final double? latitude;
  final double? longitude;
  final String gpsSource;

  const _DetailLaporanForm({
    this.imageFile,
    this.imageBytes,
    required this.service,
    this.editing,
    this.accuracy,
    this.latitude,
    this.longitude,
    required this.gpsSource,
  });

  @override
  State<_DetailLaporanForm> createState() => _DetailLaporanFormState();
}

class _DetailLaporanFormState extends State<_DetailLaporanForm> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  String? _category;
  String? _severity;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final content = widget.editing?.content;
    _descController.text = content?.description ?? '';
    _category = content?.category;
    _severity = content?.severity;
    if (widget.latitude != null) {
      _latController.text = widget.latitude!.toString();
    }
    if (widget.longitude != null) {
      _longController.text = widget.longitude!.toString();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft({bool sendToQueue = false}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.service.save(
        editing: widget.editing,
        existingPath: widget.imageFile?.path,
        newPhoto: widget.imageBytes,
        source: widget.gpsSource.isEmpty ? null : widget.gpsSource,
        latitude: _latController.text,
        longitude: _longController.text,
        accuracy: widget.accuracy,
        category: _category,
        severity: _severity,
        description: _descController.text,
        send: sendToQueue,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sendToQueue
                ? 'Laporan masuk antrean (Menunggu Sinyal).'
                : 'Laporan tersimpan di perangkat.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_formError(error))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManualGps = widget.gpsSource == 'manual';

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Detail Laporan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '📋 FORM DETAIL & DRAFT',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Konfirmasi Data Laporan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),

                // Thumbnail foto
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.imageBytes != null
                      ? Image.memory(
                          widget.imageBytes!,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        )
                      : widget.imageFile != null
                      ? Image.file(
                          widget.imageFile!,
                          errorBuilder: (_, error, stack) => const Text(
                            'Foto tidak ditemukan. Pilih foto pengganti.',
                          ),
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 160,
                          color: AppColors.surfaceDim,
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Info GPS
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
                        'Data Spasial:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sumber GPS: ${widget.gpsSource}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (!isManualGps) ...[
                        Text(
                          'Lat: ${widget.latitude?.toStringAsFixed(6) ?? "-"} · Long: ${widget.longitude?.toStringAsFixed(6) ?? "-"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Manual GPS fields (only shown for gallery photos)
                if (isManualGps) ...[
                  const _FormLabel('KOORDINAT GPS (MANUAL)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: _inputDecoration('Latitude'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: _inputDecoration('Longitude'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Kategori
                if (widget.gpsSource.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Pratinjau lokasi'),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ReportLocationMap(
                            latitude: double.tryParse(
                              _latController.text.trim(),
                            ),
                            longitude: double.tryParse(
                              _longController.text.trim(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const _FormLabel('KATEGORI KERUSAKAN'),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: _inputDecoration('Pilih kategori'),
                  items: [
                    for (final c in {...kCategories, ?_category})
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),

                // Keparahan
                const _FormLabel('TINGKAT KEPARAHAN'),
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: _inputDecoration('Pilih tingkat'),
                  items: [
                    for (final level in {...kSeverityLabels, ?_severity})
                      DropdownMenuItem(value: level, child: Text(level)),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (v) => setState(() => _severity = v!),
                ),
                const SizedBox(height: 16),

                // Deskripsi
                const _FormLabel('DESKRIPSI LAPORAN'),
                TextFormField(
                  controller: _descController,
                  enabled: !_isSaving,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: _inputDecoration(
                    'Deskripsikan kondisi kerusakan jalan...',
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveDraft(sendToQueue: false),
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: Text(
                          widget.editing == null
                              ? 'Simpan Draft'
                              : 'Simpan perubahan',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _isSaving ||
                                widget.editing?.syncStatus ==
                                    SyncStatus.gagalTerkirim
                            ? null
                            : () => _saveDraft(sendToQueue: true),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(_isSaving ? 'Menyimpan...' : 'Kirim'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
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

String _formError(Object error) {
  if (error is FormatException) return error.message;
  if (error is StateError && error.message == 'Tidak ada sesi aktif') {
    return 'Sesi berakhir. Silakan masuk kembali.';
  }
  if (error is StateError && error.message.startsWith('Laporan terkunci')) {
    return error.message;
  }
  if (error is FileSystemException) {
    return 'Foto tidak tersedia. Periksa penyimpanan atau pilih foto kembali.';
  }
  return 'Penyimpanan laporan tidak tersedia. Coba kembali pada perangkat yang didukung.';
}
