// Model untuk satu item laporan jalan.
enum ReportStatus { draft, synced, failed }

class RoadReport {
  const RoadReport({
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

  final String id;
  final ReportStatus status;
  final String coordinates;
  final String address;
  final String time;
  final String imageUrl;
  final String type;
  final int severity;
  final String notes;
}