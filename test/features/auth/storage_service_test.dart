import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aspal/features/auth/data/services/profile_cache_service.dart';
import 'package:aspal/features/auth/data/services/secure_storage_service.dart';
import 'package:aspal/features/auth/domain/models/auth_session.dart';
import 'package:aspal/features/auth/domain/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService Test', () {
    late SecureStorageService secureStorageService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      secureStorageService = SecureStorageService();
    });

    final testSession = AuthSession(
      userId: 'usr-123',
      displayName: 'Zaki Alfurqani',
      email: 'zaki@aspal.id',
      accessToken: 'access-token-xyz',
      refreshToken: 'refresh-token-abc',
      tokenExpiresAt: DateTime.parse('2026-11-20T10:00:00.000Z'),
      loggedInAt: DateTime.parse('2026-11-19T10:00:00.000Z'),
      offlineSessionExpiresAt: DateTime.parse('2026-12-19T10:00:00.000Z'),
    );

    test('Menyimpan dan membaca sesi dari secure storage', () async {
      await secureStorageService.saveAuthSession(testSession);

      final readSession = await secureStorageService.readAuthSession();
      expect(readSession, isNotNull);
      expect(readSession!.userId, equals('usr-123'));
      expect(readSession.displayName, equals('Zaki Alfurqani'));
      expect(readSession.email, equals('zaki@aspal.id'));
      expect(readSession.accessToken, equals('access-token-xyz'));
      expect(readSession.refreshToken, equals('refresh-token-abc'));
      expect(readSession.tokenExpiresAt, equals(testSession.tokenExpiresAt));
      expect(readSession.loggedInAt, equals(testSession.loggedInAt));
      expect(readSession.offlineSessionExpiresAt,
          equals(testSession.offlineSessionExpiresAt));
    });

    test('Menghapus sesi dari secure storage', () async {
      await secureStorageService.saveAuthSession(testSession);
      expect(await secureStorageService.readAuthSession(), isNotNull);

      await secureStorageService.clearAuthSession();
      expect(await secureStorageService.readAuthSession(), isNull);
      expect(await secureStorageService.readAccessToken(), isNull);
      expect(await secureStorageService.readRefreshToken(), isNull);
      expect(await secureStorageService.readUserId(), isNull);
    });

    test('Memperbarui token di secure storage', () async {
      await secureStorageService.saveAuthSession(testSession);

      final newExpiresAt = DateTime.parse('2026-11-20T12:00:00.000Z');
      await secureStorageService.updateTokens(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        tokenExpiresAt: newExpiresAt,
      );

      final updated = await secureStorageService.readAuthSession();
      expect(updated, isNotNull);
      expect(updated!.accessToken, equals('new-access-token'));
      expect(updated.refreshToken, equals('new-refresh-token'));
      expect(updated.tokenExpiresAt, equals(newExpiresAt));
      // User ID dan offline session tetap utuh
      expect(updated.userId, equals('usr-123'));
      expect(updated.offlineSessionExpiresAt,
          equals(testSession.offlineSessionExpiresAt));
    });
  });

  group('ProfileCacheService Test (SharedPreferences)', () {
    late ProfileCacheService profileCacheService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      profileCacheService = ProfileCacheService();
    });

    test('Menyimpan dan membaca cache profil non-sensitif dalam format JSON',
        () async {
      final now = DateTime.parse('2026-11-19T12:00:00.000Z');
      final user = User(
        userId: 'usr-456',
        displayName: 'Daffa Valiant',
        email: 'daffa@aspal.id',
        updatedAt: now,
      );

      await profileCacheService.saveProfile(user);

      final cached = await profileCacheService.getProfile();
      expect(cached, isNotNull);
      expect(cached!.userId, equals('usr-456'));
      expect(cached.displayName, equals('Daffa Valiant'));
      expect(cached.email, equals('daffa@aspal.id'));
      expect(cached.updatedAt, equals(now));
    });

    test('Menghapus cache profil dari SharedPreferences', () async {
      final user = const User(
        userId: 'usr-456',
        displayName: 'Daffa Valiant',
        email: 'daffa@aspal.id',
      );

      await profileCacheService.saveProfile(user);
      expect(await profileCacheService.getProfile(), isNotNull);

      await profileCacheService.clearProfile();
      expect(await profileCacheService.getProfile(), isNull);
    });
  });

  group('AuthLocalDataSource Test', () {
    late AuthLocalDataSource localDataSource;
    late SecureStorageService secureStorageService;
    late ProfileCacheService profileCacheService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      secureStorageService = SecureStorageService();
      profileCacheService = ProfileCacheService();
      localDataSource = AuthLocalDataSourceImpl(
        secureStorageService: secureStorageService,
        profileCacheService: profileCacheService,
      );
    });

    final now = DateTime.now();
    final validSession = AuthSession(
      userId: 'usr-999',
      displayName: 'Hasyfi Zharfan',
      email: 'hasyfi@aspal.id',
      accessToken: 'access-token-123',
      refreshToken: 'refresh-token-123',
      tokenExpiresAt: now.add(const Duration(hours: 1)),
      loggedInAt: now,
      offlineSessionExpiresAt: now.add(const Duration(days: 30)),
    );

    test('Menyimpan sesi sekaligus membuat cache profil non-sensitif', () async {
      await localDataSource.saveSession(validSession);

      final session = await localDataSource.getSession();
      expect(session, isNotNull);
      expect(session!.userId, equals('usr-999'));

      final cachedProfile = await localDataSource.getCachedProfile();
      expect(cachedProfile, isNotNull);
      expect(cachedProfile!.displayName, equals('Hasyfi Zharfan'));
      expect(cachedProfile.email, equals('hasyfi@aspal.id'));
    });

    test('Menghapus sesi membersihkan secure storage dan cache profil', () async {
      await localDataSource.saveSession(validSession);
      expect(await localDataSource.getSession(), isNotNull);
      expect(await localDataSource.getCachedProfile(), isNotNull);

      await localDataSource.clearSession();
      expect(await localDataSource.getSession(), isNull);
      expect(await localDataSource.getCachedProfile(), isNull);
    });

    test('hasValidOfflineSession mengecek validitas batas 30 hari', () async {
      // Sesi masih berlaku
      await localDataSource.saveSession(validSession);
      expect(await localDataSource.hasValidOfflineSession(), isTrue);

      // Sesi kedaluwarsa 31 hari lalu
      final expiredSession = validSession.copyWith(
        offlineSessionExpiresAt: now.subtract(const Duration(days: 1)),
      );
      await localDataSource.saveSession(expiredSession);
      expect(await localDataSource.hasValidOfflineSession(), isFalse);
    });
  });
}
