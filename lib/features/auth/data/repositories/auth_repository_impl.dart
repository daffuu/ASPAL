import '../../domain/models/auth_session.dart';
import '../../domain/models/logout_result.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
    this.offlineSessionDuration = const Duration(days: 30),
  })  : _local = localDataSource,
        _remote = remoteDataSource;

  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;
  final Duration offlineSessionDuration;

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _remote.register(
      name: name,
      email: email,
      password: password,
    );

    final now = DateTime.now();
    final session = AuthSession(
      userId: response.user.userId,
      displayName: response.user.displayName,
      email: response.user.email,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      tokenExpiresAt: response.tokenExpiresAt,
      loggedInAt: now,
      offlineSessionExpiresAt: now.add(offlineSessionDuration),
    );

    await _local.saveSession(session);
    await _local.saveProfileCache(response.user);

    return session;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _remote.login(
      email: email,
      password: password,
    );

    final now = DateTime.now();
    final session = AuthSession(
      userId: response.user.userId,
      displayName: response.user.displayName,
      email: response.user.email,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      tokenExpiresAt: response.tokenExpiresAt,
      loggedInAt: now,
      offlineSessionExpiresAt: now.add(offlineSessionDuration),
    );

    await _local.saveSession(session);
    await _local.saveProfileCache(response.user);

    return session;
  }

  @override
  Future<LogoutResult> logout() async {
    final session = await _local.getSession();
    var isServerNotified = false;
    String? serverError;

    if (session != null) {
      try {
        await _remote.logout(accessToken: session.accessToken);
        isServerNotified = true;
      } catch (e) {
        // Gangguan jaringan saat logout ke server tidak boleh membatalkan
        // pembersihan sesi lokal di perangkat pengguna.
        serverError = e.toString();
      }
    }

    // Hapus sesi autentikasi dan cache profil
    await _local.clearSession();

    return LogoutResult(
      isLocalCleared: true,
      isServerNotified: isServerNotified,
      serverError: serverError,
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await _local.getSession();
    if (session == null) {
      return null;
    }

    // Periksa apakah masa berlaku sesi offline (30 hari) telah habis
    if (session.isOfflineSessionExpired()) {
      // Sesi habis: bersihkan sesi autentikasi lokal
      // CATATAN: Jangan menghapus draft laporan lokal (kewenangan modul laporan)
      await _local.clearSession();
      return null;
    }

    // Jika access token sudah kedaluwarsa tetapi sesi offline masih valid,
    // coba perbarui access token jika online.
    if (session.isAccessTokenExpired()) {
      try {
        final updatedSession = await refreshSession();
        return updatedSession;
      } on NetworkException {
        // Gangguan jaringan tidak otomatis dianggap sebagai sesi dicabut.
        // Pengguna tetap dapat menggunakan aplikasi secara offline.
        return session;
      } on ServerException {
        // Gangguan server sementara juga tidak membatalkan sesi lokal offline.
        return session;
      } on InvalidTokenException {
        // Refresh token ditolak oleh server -> sesi tidak valid.
        await _local.clearSession();
        return null;
      } catch (_) {
        return session;
      }
    }

    return session;
  }

  @override
  Future<AuthSession> refreshSession() async {
    final session = await _local.getSession();
    if (session == null) {
      throw const InvalidTokenException('Tidak ada sesi yang tersimpan');
    }

    if (session.isOfflineSessionExpired()) {
      await _local.clearSession();
      throw const InvalidTokenException(
          'Masa berlaku sesi offline 30 hari telah berakhir');
    }

    try {
      final response = await _remote.refreshToken(
        refreshToken: session.refreshToken,
      );

      final updatedSession = session.copyWith(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        tokenExpiresAt: response.tokenExpiresAt,
      );

      await _local.updateTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        tokenExpiresAt: response.tokenExpiresAt,
      );

      return updatedSession;
    } on InvalidTokenException {
      // Refresh token ditolak oleh server -> bersihkan sesi lokal
      await _local.clearSession();
      rethrow;
    }
  }

  @override
  Future<User> getProfile() async {
    final session = await _local.getSession();
    if (session == null) {
      throw const InvalidTokenException('Tidak ada sesi aktif');
    }

    try {
      final user = await _remote.getProfile(accessToken: session.accessToken);
      await _local.saveProfileCache(user);
      if (user.displayName != session.displayName) {
        await _local.updateDisplayName(user.displayName);
      }
      return user;
    } on NetworkException {
      // Offline fallback ke cache SharedPreferences
      final cached = await _local.getCachedProfile();
      if (cached != null) return cached;
      return session.toUser();
    }
  }

  @override
  Future<User> updateProfile({required String displayName}) async {
    final session = await _local.getSession();
    if (session == null) {
      throw const InvalidTokenException('Tidak ada sesi aktif');
    }

    final updated = await _remote.updateProfile(
      accessToken: session.accessToken,
      displayName: displayName,
    );

    await _local.updateDisplayName(displayName);
    return updated;
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = await _local.getSession();
    if (session == null) {
      throw const InvalidTokenException('Tidak ada sesi aktif');
    }

    await _remote.updatePassword(
      accessToken: session.accessToken,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<User?> getCachedProfile() async {
    return _local.getCachedProfile();
  }

  // --- Implementasi TokenProvider (untuk API Client Ikhsan & Sync) ---

  @override
  Future<String?> getAccessToken() async {
    final session = await _local.getSession();
    if (session == null) return null;

    if (session.isOfflineSessionExpired()) {
      await _local.clearSession();
      return null;
    }

    // Jika access token sudah expired, coba refresh jika memungkinkan
    if (session.isAccessTokenExpired()) {
      try {
        final refreshed = await refreshSession();
        return refreshed.accessToken;
      } catch (_) {
        // Jika offline, kembalikan access token yang tersimpan
        return session.accessToken;
      }
    }

    return session.accessToken;
  }

  @override
  Future<String?> refreshToken() async {
    try {
      final session = await refreshSession();
      return session.accessToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    final session = await _local.getSession();
    return session?.refreshToken;
  }

  @override
  Future<String?> getUserId() async {
    final session = await _local.getSession();
    return session?.userId;
  }

  @override
  Future<bool> isSessionValid() async {
    final session = await _local.getSession();
    if (session == null) return false;
    return session.isOfflineSessionValid();
  }
}
