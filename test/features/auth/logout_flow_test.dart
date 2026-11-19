import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/auth_module.dart';
import 'package:aspal/routes/app_routes.dart';
import 'package:aspal/screens/settings_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController authController;
  late AuthRepository authRepository;
  late AuthLocalDataSource localDataSource;
  late MockAuthRemoteDataSource mockRemote;
  late MockAccountLocalDataGateway mockGateway;
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
    mockRemote = MockAuthRemoteDataSource(networkDelay: Duration.zero);
    authRepository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemote,
    );
    mockGateway = MockAccountLocalDataGateway();

    authController = AuthController(
      authRepository: authRepository,
      accountLocalDataGateway: mockGateway,
    );

    AuthModule.init(
      customRepository: authRepository,
      customController: authController,
      customGateway: mockGateway,
    );
  });

  Widget buildSettingsApp() {
    return MaterialApp(
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => Scaffold(
              body: SettingsTab(controller: authController),
            ),
        AppRoutes.login: (_) => const Scaffold(
              body: Text('Login Screen Returned'),
            ),
      },
    );
  }

  group('Logout & FR-03 Comprehensive Tests', () {
    testWidgets('Logout langsung ketika antrean laporan & tindak lanjut kosong (count = 0)',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();
      mockGateway.setUnsentCount('usr-default-001', 0);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      // Tap Keluar dari Akun
      await tester.tap(find.byKey(const Key('settings-logout-btn')));
      await tester.pumpAndSettle();

      // Karena antrean 0, langsung logout tanpa dialog peringatan
      expect(find.byKey(const Key('logout-warning-dialog')), findsNothing);
      expect(find.text('Login Screen Returned'), findsOneWidget);

      // Verifikasi status auth & pembersihan lokal
      expect(authController.isAuthenticated, isFalse);
      expect(await localDataSource.getSession(), isNull);
      expect(await localDataSource.getCachedProfile(), isNull);
    });

    testWidgets('Dialog peringatan muncul jika terdapat antrean data belum terkirim',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();
      mockGateway.setUnsentCount('usr-default-001', 3);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-logout-btn')));
      await tester.pumpAndSettle();

      // Dialog peringatan muncul menampilkan jumlah item belum terkirim
      expect(find.byKey(const Key('logout-warning-dialog')), findsOneWidget);
      expect(find.textContaining('Terdapat 3 laporan / tindak lanjut'), findsOneWidget);
    });

    testWidgets('Pengguna membatalkan logout: sesi dan data lokal tetap utuh',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();
      mockGateway.setUnsentCount('usr-default-001', 2);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-logout-btn')));
      await tester.pumpAndSettle();

      // Pilih Batal
      await tester.tap(find.byKey(const Key('cancel-logout-btn')));
      await tester.pumpAndSettle();

      // Dialog tertutup, tetap di settings, sesi tidak berubah
      expect(find.byKey(const Key('logout-warning-dialog')), findsNothing);
      expect(find.text('Login Screen Returned'), findsNothing);
      expect(authController.isAuthenticated, isTrue);
      expect(await localDataSource.getSession(), isNotNull);
      expect(mockGateway.clearedUsers.contains('usr-default-001'), isFalse);
    });

    testWidgets('Pengguna mengonfirmasi logout: data lokal akun dibersihkan dan kembali ke Login',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();
      mockGateway.setUnsentCount('usr-default-001', 5);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-logout-btn')));
      await tester.pumpAndSettle();

      // Pilih Tetap Keluar & Hapus
      await tester.tap(find.byKey(const Key('confirm-logout-btn')));
      await tester.pumpAndSettle();

      // Berpindah ke LoginScreen
      expect(find.text('Login Screen Returned'), findsOneWidget);
      expect(authController.isAuthenticated, isFalse);

      // Verifikasi pembersihan Secure Storage dan SharedPreferences
      expect(await secureStorageService.readAuthSession(), isNull);
      expect(await profileCacheService.getProfile(), isNull);

      // Verifikasi pembersihan data lokal akun pengguna aktif melalui gateway
      expect(mockGateway.clearedUsers.contains('usr-default-001'), isTrue);
    });

    testWidgets('Logout ketika offline atau server gagal: logout lokal tetap berhasil',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();
      mockGateway.setUnsentCount('usr-default-001', 0);

      // Simulasikan offline
      mockRemote.simulateNetworkError = true;

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-logout-btn')));
      await tester.pumpAndSettle();

      // Tetap berhasil keluar ke LoginScreen
      expect(find.text('Login Screen Returned'), findsOneWidget);
      expect(authController.isAuthenticated, isFalse);
      expect(await secureStorageService.readAuthSession(), isNull);
      expect(await profileCacheService.getProfile(), isNull);

      // Notifikasi informasi bahwa pencabutan di server belum terkonfirmasi tampil di SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Pencabutan token di server belum terkonfirmasi'),
        findsOneWidget,
      );
    });

    testWidgets('Isolasi pembersihan data: hanya data akun aktif yang dihapus, data akun lain aman',
        (tester) async {
      final gateway = MockAccountLocalDataGateway(initialUnsentCounts: {
        'user-A': 4,
        'user-B': 7,
      });

      final controller = AuthController(
        authRepository: authRepository,
        accountLocalDataGateway: gateway,
      );

      // Login sebagai user-A
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await controller.initialize();

      // Bersihkan data user-A via logout
      await controller.logout();

      // Verifikasi isolasi: hanya user-A yang dibersihkan, user-B tidak disentuh
      expect(gateway.clearedUsers.contains('usr-default-001'), isTrue);
      expect(gateway.clearedUsers.contains('user-B'), isFalse);
      expect(await gateway.getUnsentItemCount('user-B'), equals(7));
    });
  });
}
