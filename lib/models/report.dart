/// Status pengiriman laporan sesuai siklus PRD.
enum ReportStatus {
  draft('Draft'),
  menungguSinyal('Menunggu Sinyal'),
  mengirim('Mengirim'),
  gagalTerkirim('Gagal Terkirim'),
  terkirim('Terkirim');

  const ReportStatus(this.label);
  final String label;

  /// Laporan yang sudah terkirim atau sedang mengirim/menunggu sinyal
  /// tidak boleh diedit (dikunci selama proses sinkronisasi).
  bool get canEdit =>
      this == ReportStatus.draft || this == ReportStatus.gagalTerkirim;

  /// Hanya draft dan gagal terkirim yang boleh dihapus.
  bool get canDelete =>
      this == ReportStatus.draft || this == ReportStatus.gagalTerkirim;
}

/// Model data utama aplikasi ASPAL: satu laporan kerusakan jalan.
class Report {
  final String id;
  final ReportStatus status;
  final String coordinates;
  final String address;
  final String time;
  final String imageUrl;
  final String type; // kategori kerusakan
  final int severity; // 0 = Ringan ... 3 = Sangat Parah
  final String notes;
  final String? photoLocalPath;
  final double? latitude;
  final double? longitude;
  final String? gpsSource;
  final String? lastErrorMessage;
  final int retryCount;

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
    this.photoLocalPath,
    this.latitude,
    this.longitude,
    this.gpsSource,
    this.lastErrorMessage,
    this.retryCount = 0,
  });

  /// Buat salinan baru dengan data yang diubah.
  /// id, coordinates, dan time sengaja tidak bisa diubah lewat sini.
  Report copyWith({
    ReportStatus? status,
    String? address,
    String? imageUrl,
    String? type,
    int? severity,
    String? notes,
    String? photoLocalPath,
    double? latitude,
    double? longitude,
    String? gpsSource,
    String? lastErrorMessage,
    int? retryCount,
  }) {
    return Report(
      id: id,
      status: status ?? this.status,
      coordinates: coordinates,
      address: address ?? this.address,
      time: time,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      photoLocalPath: photoLocalPath ?? this.photoLocalPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsSource: gpsSource ?? this.gpsSource,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
