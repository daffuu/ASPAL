import '../models/report.dart';

/// Kategori kerusakan (konstanta PRD).
const List<String> kCategories = ['Lubang', 'Retak', 'Amblas', 'Genangan'];

/// Label keparahan (konstanta PRD).
const List<String> kSeverityLabels = [
  'Ringan',
  'Sedang',
  'Parah',
  'Sangat Parah',
];

/// Sumber data sementara (dummy) — mutable supaya bisa diedit/dihapus.
class ReportRepository {
  static final List<Report> reports = [
    const Report(
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
      latitude: -0.9471,
      longitude: 100.3543,
      gpsSource: 'camera',
    ),
    const Report(
      id: 'RPT-002',
      status: ReportStatus.gagalTerkirim,
      coordinates: 'Lat: -0.9512, Long: 100.3601',
      address: 'Jl. Ahmad Yani KM 3, Padang',
      time: 'Kemarin, 14:20 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1621501503460-705284897f1a?w=600&h=400&fit=crop&auto=format',
      type: 'Retak',
      severity: 1,
      notes: 'Retakan memanjang sepanjang sekitar 2 meter di sisi kiri jalan.',
      latitude: -0.9512,
      longitude: 100.3601,
      gpsSource: 'camera',
      lastErrorMessage: 'Koneksi terputus saat mengirim data',
      retryCount: 3,
    ),
    const Report(
      id: 'RPT-003',
      status: ReportStatus.terkirim,
      coordinates: 'Lat: -0.9388, Long: 100.3455',
      address: 'Jl. Khatib Sulaiman No.5, Padang',
      time: '12 Mei, 09:15 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1534346853755-e7bb523efec7?w=600&h=400&fit=crop&auto=format',
      type: 'Amblas',
      severity: 3,
      notes:
          'Jalan amblas cukup parah, truk besar tidak dapat melewati area ini.',
      latitude: -0.9388,
      longitude: 100.3455,
      gpsSource: 'camera',
    ),
    const Report(
      id: 'RPT-004',
      status: ReportStatus.menungguSinyal,
      coordinates: 'Lat: -0.9602, Long: 100.3290',
      address: 'Jl. Bypass Padang KM 8',
      time: 'Kemarin, 16:30 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=600&h=400&fit=crop&auto=format',
      type: 'Lubang',
      severity: 1,
      notes: 'Lubang kecil di sisi kanan jalan.',
      latitude: -0.9602,
      longitude: 100.3290,
      gpsSource: 'camera',
    ),
    const Report(
      id: 'RPT-005',
      status: ReportStatus.draft,
      coordinates: 'Lat: -0.9240, Long: 100.3112',
      address: 'Jl. Proklamasi No.22, Padang',
      time: 'Kemarin, 11:05 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1621501503460-705284897f1a?w=600&h=400&fit=crop&auto=format',
      type: 'Genangan',
      severity: 0,
      notes: 'Genangan air akibat drainase tersumbat.',
      latitude: -0.9240,
      longitude: 100.3112,
      gpsSource: 'manual',
    ),
    const Report(
      id: 'RPT-006',
      status: ReportStatus.menungguSinyal,
      coordinates: 'Lat: -0.9150, Long: 100.3780',
      address: 'Jl. Diponegoro KM 4, Padang',
      time: 'Kemarin, 08:45 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1534346853755-e7bb523efec7?w=600&h=400&fit=crop&auto=format',
      type: 'Amblas',
      severity: 2,
      notes: 'Bahu jalan turun 15cm.',
      latitude: -0.9150,
      longitude: 100.3780,
      gpsSource: 'camera',
    ),
    const Report(
      id: 'RPT-007',
      status: ReportStatus.terkirim,
      coordinates: 'Lat: -0.9721, Long: 100.3892',
      address: 'Jl. Veteran No.10, Padang',
      time: '24 Okt, 15:10 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=600&h=400&fit=crop&auto=format',
      type: 'Retak',
      severity: 1,
      notes: 'Retak rambut pada permukaan aspal.',
      latitude: -0.9721,
      longitude: 100.3892,
      gpsSource: 'camera',
    ),
    const Report(
      id: 'RPT-008',
      status: ReportStatus.gagalTerkirim,
      coordinates: 'Lat: -0.9810, Long: 100.3650',
      address: 'Jl. Gajah Mada KM 6, Padang',
      time: '24 Okt, 13:40 WIB',
      imageUrl:
          'https://images.unsplash.com/photo-1621501503460-705284897f1a?w=600&h=400&fit=crop&auto=format',
      type: 'Lubang',
      severity: 3,
      notes: 'Lubang besar sangat berbahaya.',
      latitude: -0.9810,
      longitude: 100.3650,
      gpsSource: 'camera',
      lastErrorMessage: 'Server tidak merespons (timeout)',
      retryCount: 3,
    ),
  ];

  /// Mengambil daftar laporan.
  /// simulateError: true -> sengaja dibuat gagal untuk menguji error state.
  Future<List<Report>> fetchReports({bool simulateError = false}) async {
    await Future.delayed(
        const Duration(seconds: 2)); // simulasi waktu tunggu server
    if (simulateError) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return reports;
  }
}
