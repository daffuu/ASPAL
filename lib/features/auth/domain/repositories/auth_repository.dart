import '../models/auth_session.dart';
import '../models/logout_result.dart';
import '../models/user.dart';
import 'token_provider.dart';

abstract interface class AuthRepository implements TokenProvider {
  /// Melakukan pendaftaran akun baru di server (online).
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  });

  /// Melakukan login akun menggunakan email dan password (online).
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  /// Mengeluarkan akun dan membersihkan sesi lokal pada perangkat.
  ///
  /// Mengembalikan [LogoutResult] yang menginformasikan status pembersihan lokal
  /// serta apakah pencabutan token di server berhasil dikonfirmasi.
  Future<LogoutResult> logout();

  /// Memulihkan sesi lokal saat aplikasi dibuka ulang.
  ///
  /// Mengembalikan `null` jika tidak ada sesi yang tersimpan atau sesi offline telah berakhir.
  Future<AuthSession?> restoreSession();

  /// Memperbarui sesi autentikasi dan token dari server.
  Future<AuthSession> refreshSession();

  /// Mengambil profil terkini dari remote jika online, atau dari cache lokal jika offline.
  Future<User> getProfile();

  /// Memperbarui nama tampilan profil.
  Future<User> updateProfile({
    required String displayName,
  });

  /// Mengubah kata sandi akun (memerlukan password saat ini dan password baru).
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Mengambil cache profil dari SharedPreferences (offline fast read).
  Future<User?> getCachedProfile();
}
