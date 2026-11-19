import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/auth_session.dart';

/// Layanan penyimpanan aman berbasis `flutter_secure_storage`.
///
/// Digunakan sebagai sumber utama kebenaran (single source of truth) status autentikasi.
/// Menyimpan token dan parameter sesi sensitif secara terenkripsi di keychain / Keystore.
/// Password akun tidak pernah disimpan di sini maupun di penyimpanan lokal mana pun.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String keyUserId = 'user_id';
  static const String keyDisplayName = 'display_name';
  static const String keyEmail = 'email';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyTokenExpiresAt = 'token_expires_at';
  static const String keyLoggedInAt = 'logged_in_at';
  static const String keyOfflineSessionExpiresAt =
      'offline_session_expires_at';

  static const List<String> allSessionKeys = [
    keyUserId,
    keyDisplayName,
    keyEmail,
    keyAccessToken,
    keyRefreshToken,
    keyTokenExpiresAt,
    keyLoggedInAt,
    keyOfflineSessionExpiresAt,
  ];

  /// Menyimpan seluruh informasi sesi ke secure storage.
  Future<void> saveAuthSession(AuthSession session) async {
    final map = session.toStorageMap();
    for (final entry in map.entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }

  /// Membaca sesi dari secure storage.
  ///
  /// Mengembalikan `null` jika tidak ada token atau data sesi belum tersimpan.
  Future<AuthSession?> readAuthSession() async {
    final userId = await _storage.read(key: keyUserId);
    final accessToken = await _storage.read(key: keyAccessToken);
    final refreshToken = await _storage.read(key: keyRefreshToken);
    final tokenExpiresAt = await _storage.read(key: keyTokenExpiresAt);
    final loggedInAt = await _storage.read(key: keyLoggedInAt);
    final offlineSessionExpiresAt =
        await _storage.read(key: keyOfflineSessionExpiresAt);

    if (userId == null ||
        accessToken == null ||
        refreshToken == null ||
        tokenExpiresAt == null ||
        loggedInAt == null ||
        offlineSessionExpiresAt == null) {
      return null;
    }

    final displayName = await _storage.read(key: keyDisplayName) ?? '';
    final email = await _storage.read(key: keyEmail) ?? '';

    return AuthSession(
      userId: userId,
      displayName: displayName,
      email: email,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiresAt: DateTime.parse(tokenExpiresAt),
      loggedInAt: DateTime.parse(loggedInAt),
      offlineSessionExpiresAt: DateTime.parse(offlineSessionExpiresAt),
    );
  }

  /// Memperbarui token access dan refresh setelah refresh berhasil.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiresAt,
    DateTime? offlineSessionExpiresAt,
  }) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    await _storage.write(key: keyRefreshToken, value: refreshToken);
    await _storage.write(
      key: keyTokenExpiresAt,
      value: tokenExpiresAt.toIso8601String(),
    );
    if (offlineSessionExpiresAt != null) {
      await _storage.write(
        key: keyOfflineSessionExpiresAt,
        value: offlineSessionExpiresAt.toIso8601String(),
      );
    }
  }

  /// Memperbarui nama profil di secure storage jika profil diubah.
  Future<void> updateDisplayName(String displayName) async {
    await _storage.write(key: keyDisplayName, value: displayName);
  }

  /// Menghapus seluruh data sesi di secure storage.
  Future<void> clearAuthSession() async {
    for (final key in allSessionKeys) {
      await _storage.delete(key: key);
    }
  }

  /// Helper untuk membaca token access langsung.
  Future<String?> readAccessToken() async {
    return _storage.read(key: keyAccessToken);
  }

  /// Helper untuk membaca refresh token langsung.
  Future<String?> readRefreshToken() async {
    return _storage.read(key: keyRefreshToken);
  }

  /// Helper untuk membaca ID pengguna langsung.
  Future<String?> readUserId() async {
    return _storage.read(key: keyUserId);
  }
}
