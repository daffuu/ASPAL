/// Hasil eksekusi alur logout lokal dan remote.
class LogoutResult {
  const LogoutResult({
    required this.isLocalCleared,
    required this.isServerNotified,
    this.serverError,
  });

  /// Menunjukkan apakah Secure Storage dan cache profil SharedPreferences berhasil dibersihkan.
  final bool isLocalCleared;

  /// Menunjukkan apakah endpoint logout remote berhasil dihubungi.
  final bool isServerNotified;

  /// Pesan error server jika pemanggilan remote gagal (misal sedang offline).
  final String? serverError;

  /// True jika server belum mengonfirmasi pencabutan token (misal karena offline/gangguan jaringan).
  bool get hasUnconfirmedServerRevocation => !isServerNotified;
}
