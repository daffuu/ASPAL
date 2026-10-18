import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_theme.dart';
import '../data/report_repository.dart';
import '../models/report.dart';

// ==========================================
// HALAMAN UTAMA: KAMERA + GEO-TAGGING (FR-01, FR-02, FR-03)
// ==========================================
class OfflineGeotaggingCamera extends StatefulWidget {
  const OfflineGeotaggingCamera({super.key});

  @override
  State<OfflineGeotaggingCamera> createState() =>
      _OfflineGeotaggingCameraState();
}

class _OfflineGeotaggingCameraState extends State<OfflineGeotaggingCamera> {
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  double? _latitude;
  double? _longitude;
  String _gpsSource = '';
  bool _isLoadingGps = false;

  // --- GPS ---
  Future<void> _getGeoLocation() async {
    setState(() => _isLoadingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Layanan GPS/Lokasi belum aktif!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Izin lokasi ditolak permanen. Aktifkan di pengaturan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoadingGps = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _gpsSource = 'camera';
        _isLoadingGps = false;
      });
    } catch (e) {
      debugPrint('GPS Error: $e');
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
          _gpsSource = 'manual';
        });
      }
    }
  }

  // --- IMAGE PICKER (FR-01, FR-02) ---
  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // NFR-03: kompresi
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imagePath = pickedFile.path;
          if (!kIsWeb) {
            _imageFile = File(pickedFile.path);
          }
        });

        if (source == ImageSource.camera) {
          // FR-01: otomatis mengunci GPS saat foto diambil
          await _getGeoLocation();
        } else {
          // FR-02: foto dari galeri => manual GPS
          setState(() {
            _latitude = null;
            _longitude = null;
            _gpsSource = 'manual';
          });
        }
      }
    } catch (e) {
      debugPrint('Image Picker Error: $e');
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
  void _validateAndNext() {
    if (_imageBytes == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Harap unggah foto kerusakan terlebih dahulu!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_gpsSource == 'camera' && (_latitude == null || _longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Tunggu sebentar, titik GPS masih dikunci...'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DetailLaporanForm(
          imageFile: _imageFile,
          imageBytes: _imageBytes,
          imagePath: _imagePath ?? _imageFile?.path ?? '',
          latitude: _latitude,
          longitude: _longitude,
          gpsSource: _gpsSource,
        ),
      ),
    );
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

          // Photo picker area
          GestureDetector(
            onTap: () => _showPickerOptions(context),
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
                            Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            )
                          else if (_imageFile != null)
                            Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          // Overlay gradient
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [
                                  Color(0x66000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0x80000000),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 12, color: Colors.white),
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
          if (_imageFile != null) ...[
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
                              ? 'Koordinat GPS Terkunci (Otomatis)'
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
                  if (_isLoadingGps)
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
                      'Latitude : ${_latitude ?? "Isi manual di form berikutnya"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Longitude: ${_longitude ?? "Isi manual di form berikutnya"}',
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
                    _imagePath = null;
                    _latitude = null;
                    _longitude = null;
                    _gpsSource = '';
                  });
                },
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 16),
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
              onPressed: _validateAndNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Selanjutnya (Isi Detail Laporan)'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textMuted),
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
  final String imagePath;
  final double? latitude;
  final double? longitude;
  final String gpsSource;

  const _DetailLaporanForm({
    this.imageFile,
    this.imageBytes,
    required this.imagePath,
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

  String _category = kCategories[0];
  int _severity = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null) {
      _latController.text = widget.latitude!.toStringAsFixed(6);
    }
    if (widget.longitude != null) {
      _longController.text = widget.longitude!.toStringAsFixed(6);
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Simulasi penulisan ke database lokal
    await Future.delayed(const Duration(seconds: 1));

    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_longController.text);
    final coordStr = lat != null && lng != null
        ? 'Lat: ${lat.toStringAsFixed(4)}, Long: ${lng.toStringAsFixed(4)}'
        : 'Belum ada koordinat';

    // FR-04, FR-05: validasi dan simpan
    final status =
        sendToQueue ? ReportStatus.menungguSinyal : ReportStatus.draft;

    // Buat ID baru
    final newId = 'RPT-${(ReportRepository.reports.length + 1).toString().padLeft(3, '0')}';
    final photoPath = widget.imagePath;
    final imageUrl = kIsWeb ? photoPath : '';

    final newReport = Report(
      id: newId,
      status: status,
      coordinates: coordStr,
      address: 'Lokasi Baru',
      time: 'Baru saja',
      imageUrl: imageUrl,
      type: _category,
      severity: _severity,
      notes: _descController.text.trim(),
      photoLocalPath: photoPath,
      latitude: lat,
      longitude: lng,
      gpsSource: widget.gpsSource,
    );

    // Tambah ke repository
    ReportRepository.reports.insert(0, newReport);

    if (!mounted) return;

    final message = sendToQueue
        ? '📡 Laporan masuk antrean sinkronisasi (Menunggu Sinyal)'
        : '💾 Laporan berhasil disimpan sebagai Draft Lokal';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: sendToQueue ? AppColors.warning : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Kembali ke halaman sebelumnya (camera tab)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isManualGps = widget.gpsSource == 'manual';

    return Scaffold(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: 160,
                            color: AppColors.surfaceDim,
                            child: const Icon(Icons.image,
                                size: 48, color: AppColors.textMuted),
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
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    if (!isManualGps) ...[
                      Text(
                        'Lat: ${widget.latitude?.toStringAsFixed(6) ?? "-"} · Long: ${widget.longitude?.toStringAsFixed(6) ?? "-"}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
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
                            decimal: true, signed: true),
                        decoration: _inputDecoration('Latitude'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Format salah';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: _inputDecoration('Longitude'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Wajib diisi';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Format salah';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Kategori
              const _FormLabel('KATEGORI KERUSAKAN'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration('Pilih kategori'),
                items: [
                  for (final c in kCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged:
                    _isSaving ? null : (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Keparahan
              const _FormLabel('TINGKAT KEPARAHAN'),
              DropdownButtonFormField<int>(
                initialValue: _severity,
                decoration: _inputDecoration('Pilih tingkat'),
                items: [
                  for (var i = 0; i < kSeverityLabels.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text('$i - ${kSeverityLabels[i]}'),
                    ),
                ],
                onChanged:
                    _isSaving ? null : (v) => setState(() => _severity = v!),
              ),
              const SizedBox(height: 16),

              // Deskripsi
              const _FormLabel('DESKRIPSI LAPORAN'),
              TextFormField(
                controller: _descController,
                enabled: !_isSaving,
                maxLines: 3,
                maxLength: 300,
                decoration: _inputDecoration('Deskripsikan kondisi kerusakan jalan...'),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Deskripsi wajib diisi';
                  if (text.length < 10) {
                    return 'Minimal 10 karakter (kurang ${10 - text.length})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSaving ? null : () => _saveDraft(sendToQueue: false),
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: const Text('Simpan Draft'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
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
                          _isSaving ? null : () => _saveDraft(sendToQueue: true),
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
                            fontWeight: FontWeight.w700, fontSize: 14),
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
