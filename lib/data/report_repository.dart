import '../models/report.dart';

/// Sumber data sementara (dummy).
class ReportRepository {
  static const List<Report> _reports = [
    Report(
      id: 'RPT-001',
      status: ReportStatus.draft,
      coordinates: 'Lat: -0.9471, Long: 100.3543',
      address: 'Jl. Sudirman No.12, Padang',
      time: 'Hari ini, 10:42 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=600&h=400&fit=crop&auto=format',
      type: 'Lubang',
      severity: 2,
      notes:
          'Lubang cukup dalam, berbahaya saat hujan karena tidak terlihat. Diameter sekitar 50cm.',
    ),
    Report(
      id: 'RPT-002',
      status: ReportStatus.failed,
      coordinates: 'Lat: -0.9512, Long: 100.3601',
      address: 'Jl. Ahmad Yani KM 3, Padang',
      time: 'Kemarin, 14:20 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1621501503460-705284897f1a?w=600&h=400&fit=crop&auto=format',
      type: 'Retak',
      severity: 1,
      notes: 'Retakan memanjang sepanjang sekitar 2 meter di sisi kiri jalan.',
    ),
    Report(
      id: 'RPT-003',
      status: ReportStatus.synced,
      coordinates: 'Lat: -0.9388, Long: 100.3455',
      address: 'Jl. Khatib Sulaiman No.5, Padang',
      time: '12 Mei, 09:15 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1534346853755-e7bb523efec7?w=600&h=400&fit=crop&auto=format',
      type: 'Amblas',
      severity: 3,
      notes: 'Jalan amblas cukup parah, truk besar tidak dapat melewati area ini.',
    ),
  ];

  /// Mengambil daftar laporan.
  /// simulateError: true -> sengaja dibuat gagal untuk menguji error state.
  Future<List<Report>> fetchReports({bool simulateError = false}) async {
    await Future.delayed(const Duration(seconds: 2)); // simulasi waktu tunggu server
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return _reports;
  }
}
