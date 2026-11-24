import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/models/report.dart';
import '../domain/models/sync_status.dart';

extension ReportStatusPresentation on SyncStatus {
  String get label => switch (this) {
    SyncStatus.draft => 'Draft',
    SyncStatus.menungguSinyal => 'Menunggu Sinyal',
    SyncStatus.mengirim => 'Mengirim',
    SyncStatus.gagalTerkirim => 'Gagal Terkirim',
    SyncStatus.terkirim => 'Terkirim',
  };
  IconData get icon => switch (this) {
    SyncStatus.draft => Icons.edit_note,
    SyncStatus.menungguSinyal => Icons.schedule,
    SyncStatus.mengirim => Icons.cloud_upload_outlined,
    SyncStatus.gagalTerkirim => Icons.error_outline,
    SyncStatus.terkirim => Icons.check_circle_outline,
  };
  bool get editable =>
      this == SyncStatus.draft || this == SyncStatus.gagalTerkirim;
}

String reportTime(DateTime value) {
  final t = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} · ${two(t.hour)}:${two(t.minute)}';
}

class ReportPhoto extends StatelessWidget {
  const ReportPhoto(this.content, {super.key, this.small = false});
  final ReportContent content;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Center(
        child: small
            ? const Icon(Icons.image_not_supported_outlined)
            : const Text('Foto belum tersedia'),
      ),
    );
    Widget image(String? name, Widget fallback) {
      if (name == null || name.trim().isEmpty) return fallback;
      return Image.file(
        File(name),
        fit: BoxFit.cover,
        cacheWidth: small ? 160 : 960,
        errorBuilder: (_, error, stack) => fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: small ? 64 : double.infinity,
        height: small ? 70 : 200,
        child: image(
          content.photoLocalPath,
          image(content.thumbnailPath, placeholder),
        ),
      ),
    );
  }
}

class ReportStatusLabel extends StatelessWidget {
  const ReportStatusLabel(this.status, {super.key});
  final SyncStatus status;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(status.icon, size: 16),
      const SizedBox(width: 4),
      Text(status.label),
    ],
  );
}
