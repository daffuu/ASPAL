import 'report.dart';

double? parseCoordinate(String text, int bound, String label) {
  if (text.trim().isEmpty) return null;
  final value = double.tryParse(text.trim());
  if (value == null || !value.isFinite || value.abs() > bound) {
    throw FormatException(
      '$label harus berupa angka dari -$bound sampai $bound.',
    );
  }
  return value;
}

void validateSubmission(ReportContent content) {
  if (content.photoLocalPath == null ||
      (content.photoSizeBytes ?? 0) <= 0 ||
      content.photoSizeBytes! > 2 * 1024 * 1024) {
    throw const FormatException('Pilih foto maksimal 2 MB sebelum Kirim.');
  }
  if (content.latitude == null ||
      content.longitude == null ||
      !content.latitude!.isFinite ||
      content.latitude!.abs() > 90 ||
      !content.longitude!.isFinite ||
      content.longitude!.abs() > 180) {
    throw const FormatException(
      'Lengkapi koordinat lokasi yang valid sebelum Kirim.',
    );
  }
  if (content.category?.trim().isNotEmpty != true) {
    throw const FormatException('Pilih kategori sebelum Kirim.');
  }
}
