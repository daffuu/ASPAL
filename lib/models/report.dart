/// Status pengiriman laporan.
enum ReportStatus { draft, synced, failed }

/// Model data utama aplikasi ASPAL: satu laporan kerusakan jalan.
class Report {
  final String id;
  final ReportStatus status;
  final String coordinates;
  final String address;
  final String time;
  final String imageUrl;
  final String type;
  final int severity; // 0 = Ringan ... 3 = Sangat Parah
  final String notes;

  const Report({
    required this.id,
    required this.status,
    required this.coordinates,
    required this.address,
    required this.time,
    required this.imageUrl,
    required this.type,
    required this.severity,
    required this.notes,
  });
}
