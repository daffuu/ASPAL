import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aspal/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:aspal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aspal/features/auth/data/services/profile_cache_service.dart';
import 'package:aspal/features/auth/data/services/secure_storage_service.dart';
import 'package:aspal/features/auth/domain/repositories/auth_repository.dart';
import 'package:aspal/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController Test', () {
    late AuthController authController;
    late AuthRepository authRepository;
    late AuthLocalDataSource localDataSource;
    late MockAuthRemoteDataSource remoteDataSource;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});

      final secureStorage = SecureStorageService();
      final profileCache = ProfileCacheService();

      localDataSource = AuthLocalDataSourceImpl(
        secureStorageService: secureStorage,
        profileCacheService: profileCache,
      );

      remoteDataSource = MockAuthRemoteDataSource(
        networkDelay: Duration.zero,
      );

      authRepository = AuthRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
      );

      authController = AuthController(authRepository: authRepository);
    });

    test('Inisialisasi awal saat belum ada sesi: status unauthenticated', () async {
      expect(authController.status, equals(AuthStatus.initial));

      await authController.initialize();

      expect(authController.status, equals(AuthStatus.unauthenticated));
      expect(authController.isAuthenticated, isFalse);
      expect(authController.currentUser, isNull);
    });

    test('Inisialisasi awal saat ada sesi aktif: status authenticated', () async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      // Buat controller baru (seperti simulasi restart aplikasi)
      final newController = AuthController(authRepository: authRepository);
      await newController.initialize();

      expect(newController.status, equals(AuthStatus.authenticated));
      expect(newController.isAuthenticated, isTrue);
      expect(newController.isOffline, isFalse);
      expect(newController.currentUser, isNotNull);
      expect(newController.currentUser!.email, equals('zaki@aspal.id'));
    });

    test('Inisialisasi awal saat offline dengan token expired: status offlineAuthenticated',
        () async {
      final session = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      // Access token expired, tapi offline 30 hari masih berlaku
      final now = DateTime.now();
      final expiredAccessSession = session.copyWith(
        tokenExpiresAt: now.subtract(const Duration(minutes: 10)),
        offlineSessionExpiresAt: now.add(const Duration(days: 20)),
      );
      await localDataSource.saveSession(expiredAccessSession);

      // Simulasikan offline
      remoteDataSource.simulateNetworkError = true;

      final offlineController = AuthController(authRepository: authRepository);
      await offlineController.initialize();

      expect(offlineController.status, equals(AuthStatus.offlineAuthenticated));
      expect(offlineController.isAuthenticated, isTrue);
      expect(offlineController.isOffline, isTrue);
    });

    test('Alur login berhasil dan gagal', () async {
      // Login gagal kredensial salah
      final fail = await authController.login('zaki@aspal.id', 'salah');
      expect(fail, isFalse);
      expect(authController.status, equals(AuthStatus.unauthenticated));
      expect(authController.errorMessage, isNotNull);

      // Login berhasil
      final success = await authController.login('zaki@aspal.id', 'password123');
      expect(success, isTrue);
      expect(authController.status, equals(AuthStatus.authenticated));
      expect(authController.currentUser?.email, equals('zaki@aspal.id'));
      expect(authController.errorMessage, isNull);
    });

    test('Alur registrasi berhasil dan gagal', () async {
      // Registrasi berhasil
      final success = await authController.register(
        name: 'Member Baru',
        email: 'member@aspal.id',
        password: 'password123',
      );
      expect(success, isTrue);
      expect(authController.status, equals(AuthStatus.authenticated));
      expect(authController.currentUser?.displayName, equals('Member Baru'));

      // Registrasi gagal email duplikat
      final duplicate = await authController.register(
        name: 'Member Lain',
        email: 'member@aspal.id',
        password: 'password123',
      );
      expect(duplicate, isFalse);
      expect(authController.status, equals(AuthStatus.unauthenticated));
      expect(authController.errorMessage, contains('sudah terdaftar'));
    });

    test('Logout membersihkan status dan sesi', () async {
      await authController.login('zaki@aspal.id', 'password123');
      expect(authController.isAuthenticated, isTrue);

      await authController.logout();
      expect(authController.status, equals(AuthStatus.unauthenticated));
      expect(authController.isAuthenticated, isFalse);
      expect(authController.currentUser, isNull);
      expect(authController.currentSession, isNull);
    });

    test('Update profil dan password melalui controller', () async {
      await authController.login('zaki@aspal.id', 'password123');

      final updatedProfile = await authController.updateProfile('Zaki Mod');
      expect(updatedProfile, isTrue);
      expect(authController.currentUser?.displayName, equals('Zaki Mod'));

      final updatedPass = await authController.updatePassword(
        currentPassword: 'password123',
        newPassword: 'newpass12345',
      );
      expect(updatedPass, isTrue);
    });
  });
}
