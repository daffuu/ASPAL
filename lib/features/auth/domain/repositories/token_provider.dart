/// Interface penyedia token dan status sesi untuk kebutuhan modul lain.
///
/// Modul seperti API Client (Ikhsan) dan Background Sync dapat menggunakan
/// interface ini untuk memperoleh header Authorization Bearer token, refresh token,
/// user_id aktif, serta mengecek apakah sesi lokal masih berlaku tanpa perlu
/// bergantung langsung pada implementasi UI atau repositori autentikasi konkret.
abstract interface class TokenProvider {
  /// Mendapatkan access token aktif.
  ///
  /// Mengembalikan `null` jika tidak ada sesi aktif.
  Future<String?> getAccessToken();

  /// Mendapatkan refresh token aktif.
  ///
  /// Mengembalikan `null` jika tidak ada sesi aktif.
  Future<String?> getRefreshToken();

  /// Mendapatkan ID pengguna yang sedang login saat ini.
  ///
  /// Digunakan oleh modul laporan (Hasyfi) dan tindak lanjut (Daffa)
  /// untuk mengikat data ke akun yang sedang aktif.
  Future<String?> getUserId();

  /// Memeriksa apakah sesi autentikasi masih sah digunakan.
  ///
  /// Bernilai `true` selama sesi offline (30 hari) belum kedaluwarsa.
  Future<bool> isSessionValid();

  /// Memperbarui access token melalui refresh token.
  ///
  /// Mengembalikan access token baru jika berhasil, atau `null` jika gagal/ditolak.
  Future<String?> refreshToken();
}
