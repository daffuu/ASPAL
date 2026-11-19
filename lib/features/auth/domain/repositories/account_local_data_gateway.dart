/// Interface gateway data lokal pengguna untuk koordinasi pembersihan data akun
/// dan penghitungan item yang belum terkirim saat alur logout (FR-03).
///
/// Interface ini diimplementasikan secara terpisah oleh:
/// - Hasyfi Zharfan Caniago: untuk entitas laporan (reports).
/// - Daffa Valiant Hansen: untuk entitas tindak lanjut (followups).
abstract interface class AccountLocalDataGateway {
  /// Mengembalikan jumlah item milik [userId] yang belum terkirim ke server.
  ///
  /// Status yang dihitung mencakup:
  /// - DRAFT
  /// - MENUNGGU_SINYAL
  /// - MENGIRIM
  /// - GAGAL_TERKIRIM
  ///
  /// Item dengan status TERKIRIM tidak dihitung karena sudah aman di server.
  Future<int> getUnsentItemCount(String userId);

  /// Membersihkan seluruh data lokal (draft, antrean, foto lokal) milik [userId].
  ///
  /// PERHATIAN: Pembersihan data HARUS diisolasi hanya untuk [userId] yang logout,
  /// dan tidak boleh menghapus data milik akun lain di perangkat bersama.
  Future<void> clearUserData(String userId);
}
