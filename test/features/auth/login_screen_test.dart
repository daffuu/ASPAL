import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/auth_module.dart';
import 'package:aspal/routes/app_routes.dart';
import 'package:aspal/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController authController;
  late MockAuthRemoteDataSource mockRemote;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    final secureStorage = SecureStorageService();
    final profileCache = ProfileCacheService();
    final localDataSource = AuthLocalDataSourceImpl(
      secureStorageService: secureStorage,
      profileCacheService: profileCache,
    );
    mockRemote = MockAuthRemoteDataSource(networkDelay: Duration.zero);
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemote,
    );
    authController = AuthController(authRepository: repository);
    AuthModule.init(
      customRepository: repository,
      customController: authController,
    );
  });

  Widget buildTestWidget() {
    return MaterialApp(
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => LoginScreen(controller: authController),
        AppRoutes.home: (_) => const Scaffold(body: Text('Home Screen')),
        AppRoutes.register: (_) => const Scaffold(body: Text('Register Screen')),
      },
    );
  }

  group('LoginScreen Widget Tests (FR-02)', () {
    testWidgets('Tampilan form login awal dan tidak ada tombol Guest maupun Tes 404',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('login-password')), findsOneWidget);
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
      expect(find.byKey(const Key('to-register-btn')), findsOneWidget);

      // Pastikan tombol guest dan tes 404 telah dihapus
      expect(find.text('Masuk sebagai Tamu (Guest)'), findsNothing);
      expect(find.text('Tes 404'), findsNothing);
    });

    testWidgets('Login berhasil dengan kredensial benar dan berpindah ke Home',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'zaki@aspal.id',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      // Berpindah ke Home Screen
      expect(find.text('Home Screen'), findsOneWidget);
      expect(authController.isAuthenticated, isTrue);
      expect(authController.currentUser?.email, equals('zaki@aspal.id'));
    });

    testWidgets('Login gagal dengan kredensial salah dan menampilkan SnackBar',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'zaki@aspal.id',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'wrongpassword',
      );

      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      // Tetap di Login dan SnackBar error muncul
      expect(find.text('Home Screen'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('tidak sesuai'), findsOneWidget);
      expect(authController.isAuthenticated, isFalse);
    });

    testWidgets('Navigasi dari LoginScreen ke RegisterScreen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final toRegisterBtn = find.byKey(const Key('to-register-btn'));
      await tester.ensureVisible(toRegisterBtn);
      await tester.pumpAndSettle();

      await tester.tap(toRegisterBtn);
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });
  });
}
