import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/auth_module.dart';
import 'package:aspal/routes/app_routes.dart';
import 'package:aspal/screens/register_screen.dart';

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
      initialRoute: AppRoutes.register,
      routes: {
        AppRoutes.register: (_) => RegisterScreen(controller: authController),
        AppRoutes.home: (_) => const Scaffold(body: Text('Home Screen')),
        AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
      },
    );
  }

  group('RegisterScreen Widget Tests (FR-01)', () {
    testWidgets('Tampilan form registrasi awal lengkap', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register-name')), findsOneWidget);
      expect(find.byKey(const Key('register-email')), findsOneWidget);
      expect(find.byKey(const Key('register-password')), findsOneWidget);
      expect(find.byKey(const Key('register-confirm-password')), findsOneWidget);
      expect(find.byKey(const Key('register-submit')), findsOneWidget);
    });

    testWidgets('Validasi form: konfirmasi password tidak cocok memunculkan error',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('register-name')),
        'Daffa Valiant',
      );
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'daffa@aspal.id',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm-password')),
        'berbeda123',
      );

      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi password tidak cocok'), findsOneWidget);
      expect(find.text('Home Screen'), findsNothing);
      expect(authController.isAuthenticated, isFalse);
    });

    testWidgets('Registrasi berhasil dan langsung bernavigasi ke Home',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('register-name')),
        'Daffa Valiant',
      );
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'daffa@aspal.id',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm-password')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
      expect(authController.isAuthenticated, isTrue);
      expect(authController.currentUser?.displayName, equals('Daffa Valiant'));
      expect(authController.currentUser?.email, equals('daffa@aspal.id'));
    });

    testWidgets('Registrasi gagal saat email sudah terdaftar (duplikat)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Email zaki@aspal.id sudah terdaftar di mock
      await tester.enterText(
        find.byKey(const Key('register-name')),
        'Zaki Kloning',
      );
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'zaki@aspal.id',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm-password')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Email sudah terdaftar'), findsOneWidget);
    });

    testWidgets('Navigasi kembali dari registrasi ke login', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('to-login-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
