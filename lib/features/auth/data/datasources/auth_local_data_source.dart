import '../../domain/models/auth_session.dart';
import '../../domain/models/user.dart';
import '../services/profile_cache_service.dart';
import '../services/secure_storage_service.dart';

abstract interface class AuthLocalDataSource {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> getSession();
  Future<void> clearSession();
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiresAt,
    DateTime? offlineSessionExpiresAt,
  });
  Future<void> updateDisplayName(String displayName);
  Future<User?> getCachedProfile();
  Future<void> saveProfileCache(User user);
  Future<void> clearProfileCache();
  Future<bool> hasValidOfflineSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({
    required SecureStorageService secureStorageService,
    required ProfileCacheService profileCacheService,
  })  : _secureStorage = secureStorageService,
        _profileCache = profileCacheService;

  final SecureStorageService _secureStorage;
  final ProfileCacheService _profileCache;

  @override
  Future<void> saveSession(AuthSession session) async {
    await _secureStorage.saveAuthSession(session);
    // Simpan juga cache profil non-sensitif ke SharedPreferences
    await _profileCache.saveProfile(session.toUser());
  }

  @override
  Future<AuthSession?> getSession() async {
    return _secureStorage.readAuthSession();
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.clearAuthSession();
    await _profileCache.clearProfile();
  }

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiresAt,
    DateTime? offlineSessionExpiresAt,
  }) async {
    await _secureStorage.updateTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiresAt: tokenExpiresAt,
      offlineSessionExpiresAt: offlineSessionExpiresAt,
    );
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await _secureStorage.updateDisplayName(displayName);
    final current = await _profileCache.getProfile();
    if (current != null) {
      await _profileCache.saveProfile(
        current.copyWith(
          displayName: displayName,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<User?> getCachedProfile() async {
    return _profileCache.getProfile();
  }

  @override
  Future<void> saveProfileCache(User user) async {
    await _profileCache.saveProfile(user);
  }

  @override
  Future<void> clearProfileCache() async {
    await _profileCache.clearProfile();
  }

  @override
  Future<bool> hasValidOfflineSession() async {
    final session = await _secureStorage.readAuthSession();
    if (session == null) return false;
    return session.isOfflineSessionValid();
  }
}
