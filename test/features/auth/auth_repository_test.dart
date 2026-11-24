import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aspal/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:aspal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aspal/features/auth/data/services/profile_cache_service.dart';
import 'package:aspal/features/auth/data/services/secure_storage_service.dart';
import 'package:aspal/features/auth/domain/models/auth_session.dart';
import 'package:aspal/features/auth/domain/repositories/auth_repository.dart';
import 'package:aspal/features/auth/domain/repositories/token_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository & TokenProvider Test', () {
    late AuthRepository authRepository;
    late AuthLocalDataSource localDataSource;
    late MockAuthRemoteDataSource remoteDataSource;
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

      remoteDataSource = MockAuthRemoteDataSource(
        networkDelay: Duration.zero,
      );

      authRepository = AuthRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
        offlineSessionDuration: const Duration(days: 30),
      );
    });

    test('Registrasi berhasil melalui Mock API dan sesi tersimpan di lokal',
        () async {
      final session = await authRepository.register(
        name: 'M. Ikhsan Pratama',
        email: 'ikhsan@aspal.id',
        password: 'password123',
      );

      expect(session.displayName, equals('M. Ikhsan Pratama'));
      expect(session.email, equals('ikhsan@aspal.id'));

      // Verifikasi sesi tersimpan di secure storage
      final storedSession = await localDataSource.getSession();
      expect(storedSession, isNotNull);
      expect(storedSession!.email, equals('ikhsan@aspal.id'));

      // Verifikasi cache profil tersimpan di SharedPreferences
      final cachedProfile = await localDataSource.getCachedProfile();
      expect(cachedProfile, isNotNull);
      expect(cachedProfile!.displayName, equals('M. Ikhsan Pratama'));
    });

    test('Login berhasil melalui Mock API dan sesi tersimpan di lokal',
        () async {
      final session = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      expect(session.email, equals('zaki@aspal.id'));
      expect(session.accessToken, isNotEmpty);

      // Verifikasi sesi tersimpan
      final storedSession = await localDataSource.getSession();
      expect(storedSession, isNotNull);
      expect(storedSession!.userId, equals(session.userId));
    });

    test('Restore session saat sesi masih aktif dan token belum kedaluwarsa',
        () async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      final restored = await authRepository.restoreSession();
      expect(restored, isNotNull);
      expect(restored!.email, equals('zaki@aspal.id'));
    });

    test('Masa berlaku sesi offline 30 hari: sesi kedaluwarsa dibersihkan',
        () async {
      final now = DateTime.now();
      // Simpan sesi manual yang sudah kedaluwarsa sesi offline-nya (31 hari lalu)
      final expiredOfflineSession = AuthSession(
        userId: 'usr-expired',
        displayName: 'User Expired',
        email: 'expired@aspal.id',
        accessToken: 'access-old',
        refreshToken: 'refresh-old',
        tokenExpiresAt: now.subtract(const Duration(days: 31)),
        loggedInAt: now.subtract(const Duration(days: 32)),
        offlineSessionExpiresAt: now.subtract(const Duration(days: 1)),
      );

      await localDataSource.saveSession(expiredOfflineSession);

      // restoreSession mendeteksi sesi offline lewat dari batas 30 hari
      final restored = await authRepository.restoreSession();
      expect(restored, isNull);

      // Sesi lokal telah dibersihkan
      final sessionAfter = await localDataSource.getSession();
      expect(sessionAfter, isNull);
    });

    test(
        'Refresh token otomatis saat access token kedaluwarsa tetapi online',
        () async {
      final loginSession = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      // Simulasikan access token kedaluwarsa, tapi sesi offline (30 hari) masih valid
      final now = DateTime.now();
      final expiredAccessTokenSession = loginSession.copyWith(
        tokenExpiresAt: now.subtract(const Duration(minutes: 5)),
        offlineSessionExpiresAt: now.add(const Duration(days: 25)),
      );
      await localDataSource.saveSession(expiredAccessTokenSession);

      // restoreSession mendeteksi access token kedaluwarsa lalu otomatis me-refresh token
      final restored = await authRepository.restoreSession();
      expect(restored, isNotNull);
      expect(restored!.accessToken, isNot(equals(loginSession.accessToken)));
      expect(restored.tokenExpiresAt.isAfter(DateTime.now()), isTrue);
    });

    test(
        'Error jaringan saat refresh: sesi lokal tetap dipertahankan untuk penggunaan offline',
        () async {
      final loginSession = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      // Access token kedaluwarsa, offline session masih valid
      final now = DateTime.now();
      final expiredAccessTokenSession = loginSession.copyWith(
        tokenExpiresAt: now.subtract(const Duration(minutes: 5)),
        offlineSessionExpiresAt: now.add(const Duration(days: 20)),
      );
      await localDataSource.saveSession(expiredAccessTokenSession);

      // Simulasikan perangkat sedang offline / gangguan jaringan
      remoteDataSource.simulateNetworkError = true;
      expect(await authRepository.getAccessToken(), isNull);

      // restoreSession mencoba refresh, gagal jaringan, tapi sesi offline tetap valid!
      final restored = await authRepository.restoreSession();
      expect(restored, isNotNull);
      expect(restored!.userId, equals(loginSession.userId));

      // Sesi lokal tidak dihapus
      final localSession = await localDataSource.getSession();
      expect(localSession, isNotNull);
    });

    test(
        'Refresh token ditolak server: status autentikasi menjadi tidak valid dan sesi dibersihkan',
        () async {
      final loginSession = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      final now = DateTime.now();
      final expiredAccessTokenSession = loginSession.copyWith(
        tokenExpiresAt: now.subtract(const Duration(minutes: 5)),
        offlineSessionExpiresAt: now.add(const Duration(days: 20)),
      );
      await localDataSource.saveSession(expiredAccessTokenSession);

      // Simulasikan server menolak refresh token (misal token dicabut dari web/admin)
      remoteDataSource.simulateInvalidRefreshToken = true;

      // restoreSession mendeteksi refresh token ditolak server -> sesi dibersihkan
      final restored = await authRepository.restoreSession();
      expect(restored, isNull);

      final localSession = await localDataSource.getSession();
      expect(localSession, isNull);
    });

    test('Token yang ditolak tidak dikembalikan ke API client', () async {
      final session = await authRepository.login(
        email: 'zaki@aspal.id', password: 'password123',
      );
      await localDataSource.saveSession(session.copyWith(tokenExpiresAt: DateTime.now()));
      remoteDataSource.simulateInvalidRefreshToken = true;
      expect(await authRepository.getAccessToken(), isNull);
      expect(await authRepository.isSessionValid(), isFalse);
    });

    test('Permintaan bersamaan memperbarui token hampir kedaluwarsa sekali', () async {
      final session = await authRepository.login(
        email: 'zaki@aspal.id', password: 'password123',
      );
      await localDataSource.saveSession(session.copyWith(
        tokenExpiresAt: DateTime.now().add(const Duration(seconds: 30)),
      ));
      final tokens = await Future.wait([
        authRepository.getAccessToken(), authRepository.getAccessToken(),
      ]);
      expect(tokens.first, isNotNull);
      expect(tokens.first, isNot(session.accessToken));
      expect(tokens.last, tokens.first);
      expect(await authRepository.getAccessToken(), tokens.first);
    });

    test('Implementasi TokenProvider untuk API Client dan Background Sync',
        () async {
      expect(authRepository, isA<TokenProvider>());
      final tokenProvider = authRepository as TokenProvider;

      // Sebelum login
      expect(await tokenProvider.getAccessToken(), isNull);
      expect(await tokenProvider.getRefreshToken(), isNull);
      expect(await tokenProvider.getUserId(), isNull);
      expect(await tokenProvider.isSessionValid(), isFalse);

      // Setelah login
      final session = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      expect(await tokenProvider.getAccessToken(), equals(session.accessToken));
      expect(await tokenProvider.getRefreshToken(), equals(session.refreshToken));
      expect(await tokenProvider.getUserId(), equals(session.userId));
      expect(await tokenProvider.isSessionValid(), isTrue);

      // Memanggil refreshToken() melalui TokenProvider
      final newToken = await tokenProvider.refreshToken();
      expect(newToken, isNotNull);
      expect(newToken, isNot(equals(session.accessToken)));
    });
  });
}
