import 'dart:io';
import 'dart:typed_data';

import 'data/report_photos.dart';
import 'domain/models/report.dart';
import 'domain/models/report_validation.dart';
import 'domain/repositories/report_repository.dart';

class ReportFormService {
  const ReportFormService(
    this.repository, {
    this.photos = const ReportPhotos(),
  });
  final ReportRepository repository;
  final ReportPhotos photos;

  Future<void> save({
    Report? editing,
    Uint8List? newPhoto,
    String? existingPath,
    String? source,
    double? accuracy,
    String latitude = '',
    String longitude = '',
    String? category,
    String? severity,
    String description = '',
    bool send = false,
  }) async {
    final lat = parseCoordinate(latitude, 90, 'Latitude');
    final lng = parseCoordinate(longitude, 180, 'Longitude');
    File? staged;
    try {
      if (newPhoto != null) staged = await photos.persist(newPhoto);
      final file = staged ?? (existingPath == null ? null : File(existingPath));
      final size = await file?.length();
      if (size != null && (size <= 0 || size > ReportPhotos.limit)) {
        throw const FormatException('Ganti foto dengan foto maksimal 2 MB.');
      }
      final content = ReportContent(
        category: category,
        severity: severity,
        description: description.trim().isEmpty ? null : description.trim(),
        latitude: lat,
        longitude: lng,
        gpsAccuracy: accuracy,
        gpsSource: source,
        photoLocalPath: file?.path,
        photoSizeBytes: size,
        thumbnailPath: newPhoto == null && existingPath != null
            ? editing?.content.thumbnailPath
            : null,
      );
      if (send) {
        await repository.submitReport(content, reportId: editing?.reportId);
      } else if (editing == null) {
        await repository.createReport(content);
      } else if (!await repository.updateReport(editing.reportId, content)) {
        throw StateError(
          'Laporan terkunci atau tidak tersedia untuk akun ini.',
        );
      }
    } catch (_) {
      await photos.discard(staged?.path);
      rethrow;
    }
  }
}
