import 'package:flutter/material.dart';

// ==========================================
// 1. MODEL DATA LAPORAN & ENUM STATUS
// ==========================================
enum StatusLaporan { draft, menungguSinyal, gagalKirim, terkirim }

class LaporanModel {
  final String id;
  final String judul;
  final String lokasi;
  final String waktu;
  final String? keterangan;
  StatusLaporan status;

  LaporanModel({
    required this.id,
    required this.judul,
    required this.lokasi,
    required this.waktu,
    this.keterangan,
    required this.status,
  });
}

// ==========================================
// 2. STATEFUL WIDGET UTAMA
// ==========================================
class RiwayatLaporanPage extends StatefulWidget {
  const RiwayatLaporanPage({super.key});

  @override
  State<RiwayatLaporanPage> createState() => _RiwayatLaporanPageState();
}

class _RiwayatLaporanPageState extends State<RiwayatLaporanPage> {
  // 10 Data Dummy Sesuai Initial State
  late List<LaporanModel> dummyReports;
  String selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    dummyReports = [
      LaporanModel(
        id: '1',
        judul: 'Laporan Jalan Berlubang KM 14',
        lokasi: 'Lat: -0.9471, Long: 100.3543',
        waktu: 'Hari ini, 10:42 WIB',
        keterangan: 'Tersimpan di Perangkat',
        status: StatusLaporan.draft,
      ),
      LaporanModel(
        id: '2',
        judul: 'Laporan Aspal Amblas Padang-Bukittinggi',
        lokasi: 'Lat: -0.9388, Long: 100.3455',
        waktu: 'Hari ini, 09:15 WIB',
        keterangan: 'Dalam Antrean Sinkron',
        status: StatusLaporan.menungguSinyal,
      ),
      LaporanModel(
        id: '3',
        judul: 'Laporan Retak Buaya Ruas KM 22',
        lokasi: 'Lat: -0.9512, Long: 100.3601',
        waktu: 'Kemarin, 16:30 WIB',
        keterangan: 'Batas Waktu Habis',
        status: StatusLaporan.gagalKirim,
      ),
      LaporanModel(
        id: '4',
        judul: 'Laporan Jalan Tertutup Longsor',
        lokasi: 'Lat: -0.9602, Long: 100.3290',
        waktu: 'Kemarin, 14:20 WIB',
        keterangan: 'Tersinkron ke Cloud',
        status: StatusLaporan.terkirim,
      ),
      LaporanModel(
        id: '5',
        judul: 'Laporan Oprit Jembatan Rusak',
        lokasi: 'Lat: -0.9240, Long: 100.3112',
        waktu: 'Kemarin, 11:05 WIB',
        keterangan: 'Tersimpan di Perangkat',
        status: StatusLaporan.draft,
      ),
      LaporanModel(
        id: '6',
        judul: 'Laporan Penurunan Bahu Jalan KM 08',
        lokasi: 'Lat: -0.9150, Long: 100.3780',
        waktu: 'Kemarin, 08:45 WIB',
        keterangan: 'Dalam Antrean Sinkron',
        status: StatusLaporan.menungguSinyal,
      ),
      LaporanModel(
        id: '7',
        judul: 'Laporan Drainase Jalan Tersumbat',
        lokasi: 'Lat: -0.9721, Long: 100.3892',
        waktu: '24 Okt, 15:10 WIB',
        keterangan: 'Tersinkron ke Cloud',
        status: StatusLaporan.terkirim,
      ),
      LaporanModel(
        id: '8',
        judul: 'Laporan Kerusakan Rambu Lalu Lintas',
        lokasi: 'Lat: -0.9810, Long: 100.3650',
        waktu: '24 Okt, 13:40 WIB',
        keterangan: 'Koneksi Terputus',
        status: StatusLaporan.gagalKirim,
      ),
      LaporanModel(
        id: '9',
        judul: 'Laporan Erosi Tanggul Jalan Sungai',
        lokasi: 'Lat: -0.9332, Long: 100.3421',
        waktu: '23 Okt, 17:25 WIB',
        keterangan: 'Dalam Antrean Sinkron',
        status: StatusLaporan.menungguSinyal,
      ),
      LaporanModel(
        id: '10',
        judul: 'Laporan Paving Trotoar Ambles',
        lokasi: 'Lat: -0.9554, Long: 100.3588',
        waktu: '23 Okt, 10:00 WIB',
        keterangan: 'Tersinkron ke Cloud',
        status: StatusLaporan.terkirim,
      ),
    ];
  }

  // --- GETTER SINKRONISASI STATISTIK SECARA OTOMATIS ---
  int get countDraft => dummyReports.where((e) => e.status == StatusLaporan.draft).length;
  int get countMenunggu => dummyReports.where((e) => e.status == StatusLaporan.menungguSinyal).length;
  int get countGagal => dummyReports.where((e) => e.status == StatusLaporan.gagalKirim).length;
  int get countTerkirim => dummyReports.where((e) => e.status == StatusLaporan.terkirim).length;

  List<LaporanModel> get filteredReports {
    if (selectedFilter == 'Draft') {
      return dummyReports.where((e) => e.status == StatusLaporan.draft).toList();
    } else if (selectedFilter == 'Menunggu') {
      return dummyReports.where((e) => e.status == StatusLaporan.menungguSinyal).toList();
    } else if (selectedFilter == 'Gagal') {
      return dummyReports.where((e) => e.status == StatusLaporan.gagalKirim).toList();
    }
    return dummyReports;
  }

  // --- LOGIKA AKSI WORKFLOW & VALIDASI ATURAN PRD FR-07 ---
  void handleHapusLaporan(LaporanModel item) {
    // Validasi Sesuai PRD: Menunggu Sinyal & Terkirim TIDAK BISA dihapus
    if (item.status == StatusLaporan.menungguSinyal || item.status == StatusLaporan.terkirim) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Gagal: Laporan yang sedang antre/dikirim tidak dapat dihapus'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Jika Draft atau Gagal Kirim -> Dialog Konfirmasi Hapus
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Laporan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('Apakah Anda yakin ingin menghapus "${item.judul}" dari penyimpanan lokal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                dummyReports.removeWhere((element) => element.id == item.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Laporan berhasil dihapus'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void handleKirimUlang(LaporanModel item) {
    setState(() {
      item.status = StatusLaporan.menungguSinyal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.sync, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Laporan dimasukkan kembali ke antrean sinkronisasi'),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================
  // 3. WIDGET _buildSummaryCounter
  // ==========================================
  Widget _buildSummaryCounter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCounterItem('$countDraft', 'DRAFT', const Color(0xFF334155)),
          _buildDivider(),
          _buildCounterItem('$countMenunggu', 'MENUNGGU', const Color(0xFFD97706)),
          _buildDivider(),
          _buildCounterItem('$countGagal', 'GAGAL', const Color(0xFFDC2626)),
          _buildDivider(),
          _buildCounterItem('$countTerkirim', 'TERKIRIM', const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildCounterItem(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. WIDGET _buildReportCard
  // ==========================================
  Widget _buildReportCard(LaporanModel report) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Bagian Atas: Thumbnail, Detail Laporan, dan Badge Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Gambar dengan Icon Status Kecil di Sudut
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image, color: Color(0xFF94A3B8), size: 28),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
                          ],
                        ),
                        child: _getSmallStatusIcon(report.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Judul, Koordinat, dan Waktu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.judul,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              report.lokasi,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            report.waktu,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge Status
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            // Bagian Bawah: Keterangan Status & Tombol Aksi Sesuai Role PRD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Keterangan / Sub-info
                Expanded(
                  child: Text(
                    report.keterangan ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getKeteranganColor(report.status),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Action Buttons
                _buildActionButtons(report),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER COMPONENT UNTUK STATUS & TOMBOL AKSI ---
  Widget _getSmallStatusIcon(StatusLaporan status) {
    switch (status) {
      case StatusLaporan.draft:
        return const Icon(Icons.edit_note, size: 13, color: Color(0xFF475569));
      case StatusLaporan.menungguSinyal:
        return const Icon(Icons.sync, size: 13, color: Color(0xFFD97706));
      case StatusLaporan.gagalKirim:
        return const Icon(Icons.priority_high, size: 13, color: Color(0xFFDC2626));
      case StatusLaporan.terkirim:
        return const Icon(Icons.check, size: 13, color: Color(0xFF16A34A));
    }
  }

  Color _getKeteranganColor(StatusLaporan status) {
    switch (status) {
      case StatusLaporan.draft:
        return const Color(0xFF64748B);
      case StatusLaporan.menungguSinyal:
        return const Color(0xFFB45309);
      case StatusLaporan.gagalKirim:
        return const Color(0xFFDC2626);
      case StatusLaporan.terkirim:
        return const Color(0xFF15803D);
    }
  }

  Widget _buildStatusBadge(StatusLaporan status) {
    String text;
    Color textColor;
    Color bgColor;

    switch (status) {
      case StatusLaporan.draft:
        text = 'DRAFT';
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
        break;
      case StatusLaporan.menungguSinyal:
        text = 'MENUNGGU SINYAL';
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case StatusLaporan.gagalKirim:
        text = 'GAGAL KIRIM';
        textColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case StatusLaporan.terkirim:
        text = 'TERKIRIM';
        textColor = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Widget _buildActionButtons(LaporanModel report) {
    switch (report.status) {
      case StatusLaporan.draft:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 13, color: Color(0xFF1E3A8A)),
              label: const Text('Edit', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => handleHapusLaporan(report),
              icon: const Icon(Icons.delete_outline, size: 13, color: Color(0xFFDC2626)),
              label: const Text('Hapus', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        );
      case StatusLaporan.menungguSinyal:
        return OutlinedButton.icon(
          onPressed: () => handleHapusLaporan(report), // Memicu SnackBar Error Validasi PRD
          icon: const Icon(Icons.lock_outline, size: 13, color: Color(0xFF94A3B8)),
          label: const Text('Hapus', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            backgroundColor: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        );
      case StatusLaporan.gagalKirim:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => handleKirimUlang(report),
              icon: const Icon(Icons.refresh, size: 13, color: Colors.white),
              label: const Text('Kirim Ulang', style: TextStyle(fontSize: 11, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () => handleHapusLaporan(report),
              icon: const Icon(Icons.delete_outline, size: 13, color: Color(0xFFDC2626)),
              label: const Text('Hapus', style: TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        );
      case StatusLaporan.terkirim:
        return OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF334155)),
          label: const Text('Detail', style: TextStyle(fontSize: 11, color: Color(0xFF334155))),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            backgroundColor: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        );
    }
  }

  // ==========================================
  // 5. ROOT BUILD METHOD (HEADER & LISTVIEW)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final listToShow = filteredReports;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ASPAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(4)),
                  child: const Text('SIPIL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const Text('Budi Santoso', style: TextStyle(fontSize: 12, color: Color(0xFFBFDBFE))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.wifi, size: 14, color: Color(0xFF86EFAC)),
                SizedBox(width: 4),
                Text('Online', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2563EB),
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 1. Ringkasan Counter Statistik Reaktif
          _buildSummaryCounter(),

          // 2. Bar Judul Riwayat Laporan + Total Counter Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Laporan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    'Total ${dummyReports.length} Laporan',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),

          // 3. Filter Chip Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Semua', '(${dummyReports.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('Draft', '($countDraft)'),
                const SizedBox(width: 8),
                _buildFilterChip('Menunggu', '($countMenunggu)'),
                const SizedBox(width: 8),
                _buildFilterChip('Gagal', '($countGagal)'),
              ],
            ),
          ),

          // 4. Daftar Kartu Laporan
          Expanded(
            child: listToShow.isEmpty
                ? const Center(
                    child: Text('Tidak ada laporan di kategori ini', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: listToShow.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      return _buildReportCard(listToShow[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFF97316),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String countText) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '$label $countText',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}