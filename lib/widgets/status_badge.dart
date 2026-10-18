import 'package:flutter/material.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.large = false});

  final ReportStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (status) {
      ReportStatus.draft => (
          AppColors.warningBg,
          AppColors.warningText,
          Icons.refresh_rounded,
          'Menunggu Sinyal',
        ),
      ReportStatus.synced => (
          AppColors.successBg,
          AppColors.successText,
          Icons.check_circle_outline,
          'Terkirim',
        ),
      ReportStatus.failed => (
          AppColors.dangerBg,
          AppColors.dangerText,
          Icons.error_outline,
          'Gagal Kirim',
        ),
    };

    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(large ? 8 : 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: large ? 14 : 12, color: fg),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
