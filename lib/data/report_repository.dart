import '../models/report.dart';

/// Sumber data sementara (dummy).
class ReportRepository {
  static const List<Report> _reports = [
    Report(
      id: 'RPT-PDG-2015',
      status: ReportStatus.draft,
      coordinates: 'Lat: -0.9145, Long: 100.3621',
      address: 'Jl. Prof. Dr. Hamka No.45, Air Tawar, Padang',
      time: 'Hari ini, 08:30 WIB',
      imageUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=600&h=400&fit=crop&auto=format',
      type: 'Lubang',
      severity: 2,
      notes: 'Lubang berdiameter ±40cm di jalur kiri menuju arah kampus, rawan genangan air saat hujan deras.',
    ),
    Report(
      id: 'RPT-PDG-2016',
      status: ReportStatus.failed,
      coordinates: 'Lat: -0.9234, Long: 100.4128',
      address: 'Jl. Kampus Unand, Limau Manis, Padang',
      time: 'Kemarin, 16:45 WIB',
      imageUrl: 'https://images.unsplash.com/photo-1621501503460-705284897f1a?w=600&h=400&fit=crop&auto=format',
      type: 'Retak',
      severity: 1,
      notes: 'Retak buaya di tanjakan setelah gerbang utama, perlu penambalan dini sebelum meluas.',
    ),
    Report(
      id: 'RPT-PDG-2017',
      status: ReportStatus.synced,
      coordinates: 'Lat: -0.9388, Long: 100.3582',
      address: 'Jl. Khatib Sulaiman No.18, Padang Utara',
      time: '14 Okt, 11:20 WIB',
      imageUrl: 'https://images.unsplash.com/photo-1534346853755-e7bb523efec7?w=600&h=400&fit=crop&auto=format',
      type: 'Amblas',
      severity: 3,
      notes: 'Badan jalan amblas sekitar 15cm akibat saluran drainase tersumbat, membahayakan pengendara motor.',
    ),
  ];

  /// Mengambil daftar laporan.
  /// simulateError: true -> sengaja dibuat gagal untuk menguji error state.
  Future<List<Report>> fetchReports({bool simulateError = false}) async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // simulasi waktu tunggu server
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return _reports;
  }
}
