import 'package:flutter/material.dart';

import '../models/road_report.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.location,
    required this.time,
    required this.imageUrl,
    required this.status,
    required this.onTap,
  });

  final String location;
  final String time;
  final String imageUrl;
  final ReportStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: NetworkPhoto(url: imageUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetaRow(icon: Icons.place_outlined, text: location),
                          const SizedBox(height: 6),
                          _MetaRow(icon: Icons.schedule, text: time),
                        ],
                      ),
                      StatusBadge(status: status),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Foto dari URL dengan placeholder kalau gagal load (offline / URL mati).
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceDim,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined,
            color: AppColors.textMuted),
      ),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(color: AppColors.surfaceDim),
    );
  }
}
