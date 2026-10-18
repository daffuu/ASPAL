import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import '../widgets/severity.dart';

class ReportFormTab extends StatefulWidget {
  const ReportFormTab({super.key, required this.isOnline});

  final bool isOnline;

  @override
  State<ReportFormTab> createState() => _ReportFormTabState();
}

class _ReportFormTabState extends State<ReportFormTab> {
  static const _photoA =
      'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=600&h=400&fit=crop&auto=format';
  static const _photoB =
      'https://images.unsplash.com/photo-1621501503460-705284897f1a?w=600&h=400&fit=crop&auto=format';

  static const _types = [
    (label: 'Lubang', icon: Icons.remove_circle_outline),
    (label: 'Retak', icon: Icons.warning_amber_rounded),
    (label: 'Amblas', icon: Icons.layers_outlined),
    (label: 'Genangan', icon: Icons.water_drop_outlined),
  ];

  final _notes = TextEditingController();
  String? _photo = _photoA;
  int _type = 0;
  int _severity = 1;
  bool _submitted = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _submitted = false;
      _photo = null;
      _notes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessView(isOnline: widget.isOnline, onReset: _reset);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Foto Kerusakan'),
          _photoSection(),
          const SizedBox(height: 20),
          const _Label('Lokasi'),
          _locationRow(),
          const SizedBox(height: 20),
          const _Label('Jenis Kerusakan'),
          Row(
            children: [
              for (var i = 0; i < _types.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _typeChip(i)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Label('Tingkat Keparahan', bottom: 0),
              SeverityChip(severity: _severity),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < severityLabels.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _severity = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 10,
                      decoration: BoxDecoration(
                        color: i <= _severity
                            ? severityBarColors[i]
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const _Label('Catatan Tambahan'),
          TextField(
            controller: _notes,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Deskripsikan kondisi kerusakan jalan...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8, bottom: 40),
                child: Icon(Icons.description_outlined,
                    size: 16, color: AppColors.textMuted),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _submitted = true),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(widget.isOnline ? 'Kirim Laporan' : 'Simpan Lokal'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoSection() {
    if (_photo == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _photo = _photoB),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 32, color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                'Ambil / Pilih Foto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 192,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(url: _photo!),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _photo = null),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0x80000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x80000000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Foto terpilih',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jl. Sudirman No.12, Padang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Lat: -0.9471 · Long: 100.3543',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location, size: 12, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Perbarui',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(int i) {
    final selected = _type == i;
    final t = _types[i];
    return GestureDetector(
      onTap: () => setState(() => _type = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              t.icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              t.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.bottom = 8});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.isOnline, required this.onReset});

  final bool isOnline;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            const Text(
              'Laporan Tersimpan!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isOnline
                  ? 'Laporan berhasil dikirim ke server.'
                  : 'Laporan disimpan lokal dan akan dikirim saat online.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onReset,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text('Buat Laporan Baru',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
