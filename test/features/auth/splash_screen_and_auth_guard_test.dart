import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/auth_module.dart';
import 'package:aspal/routes/app_routes.dart';
import 'package:aspal/screens/login_screen.dart';
import 'package:aspal/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController authController;
  late AuthRepository authRepository;
  late AuthLocalDataSource localDataSource;
  late MockAuthRemoteDataSource mockRemote;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    AppRoutes.authChecker = null;

    final secureStorage = SecureStorageService();
    final profileCache = ProfileCacheService();
    localDataSource = AuthLocalDataSourceImpl(
      secureStorageService: secureStorage,
      profileCacheService: profileCache,
    );
    mockRemote = MockAuthRemoteDataSource(networkDelay: Duration.zero);
    authRepository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemote,
    );
    authController = AuthController(authRepository: authRepository);
    AuthModule.init(
      customRepository: authRepository,
      customController: authController,
    );
  });

  Widget buildAppWithSplash() {
    return MaterialApp(
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.splash) {
          return MaterialPageRoute(
            builder: (_) => SplashScreen(controller: authController),
          );
        }
        if (settings.name == AppRoutes.login) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Login Screen Displayed')),
          );
        }
        if (settings.name == AppRoutes.home) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Home Screen Displayed')),
          );
        }
        return null;
      },
    );
  }

  group('SplashScreen & Startup Auth Check (FR-02)', () {
    testWidgets('Startup tanpa sesi mengarahkan ke Login', (tester) async {
      await tester.pumpWidget(buildAppWithSplash());
      await tester.pumpAndSettle();

      expect(find.text('Login Screen Displayed'), findsOneWidget);
      expect(find.text('Home Screen Displayed'), findsNothing);
    });

    testWidgets('Startup dengan sesi tersimpan mengarahkan ke Home',
        (tester) async {
      // Simulasikan pengguna pernah login sebelumnya
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      await tester.pumpWidget(buildAppWithSplash());
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Displayed'), findsOneWidget);
      expect(find.text('Login Screen Displayed'), findsNothing);
    });

    testWidgets(
        'Startup saat offline dengan sesi lokal 30 hari valid tetap mengarahkan ke Home',
        (tester) async {
      final session = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      // Access token expired, tapi sesi 30 hari masih berlaku
      final now = DateTime.now();
      final offlineSession = session.copyWith(
        tokenExpiresAt: now.subtract(const Duration(minutes: 5)),
        offlineSessionExpiresAt: now.add(const Duration(days: 20)),
      );
      await localDataSource.saveSession(offlineSession);

      // Matikan jaringan (simulasi offline)
      mockRemote.simulateNetworkError = true;

      await tester.pumpWidget(buildAppWithSplash());
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Displayed'), findsOneWidget);
      expect(authController.isOffline, isTrue);
    });

    testWidgets(
        'Startup saat server menolak refresh token mengarahkan ke Login',
        (tester) async {
      final session = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      final now = DateTime.now();
      final expiredAccessSession = session.copyWith(
        tokenExpiresAt: now.subtract(const Duration(minutes: 5)),
        offlineSessionExpiresAt: now.add(const Duration(days: 20)),
      );
      await localDataSource.saveSession(expiredAccessSession);

      // Server menolak refresh token
      mockRemote.simulateInvalidRefreshToken = true;

      await tester.pumpWidget(buildAppWithSplash());
      await tester.pumpAndSettle();

      expect(find.text('Login Screen Displayed'), findsOneWidget);
      expect(find.text('Home Screen Displayed'), findsNothing);
      expect(authController.isAuthenticated, isFalse);
    });
  });

  group('Auth Guard Route Protection (FR-02)', () {
    testWidgets(
        'Akses ke route terproteksi (/home) tanpa login dialihkan ke LoginScreen',
        (tester) async {
      final app = MaterialApp(
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Karena belum login, dialihkan ke LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Route publik (/login, /register, /) dapat dibuka tanpa login',
        (tester) async {
      expect(AppRoutes.isPublicRoute(AppRoutes.login), isTrue);
      expect(AppRoutes.isPublicRoute(AppRoutes.register), isTrue);
      expect(AppRoutes.isPublicRoute(AppRoutes.splash), isTrue);
      expect(AppRoutes.isPublicRoute(AppRoutes.home), isFalse);
      expect(AppRoutes.isPublicRoute(AppRoutes.editProfile), isFalse);
      expect(AppRoutes.isPublicRoute(AppRoutes.changePassword), isFalse);
    });
  });
}
