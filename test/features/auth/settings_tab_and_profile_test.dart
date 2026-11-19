import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aspal/features/auth/auth_module.dart';
import 'package:aspal/screens/change_password_screen.dart';
import 'package:aspal/screens/edit_profile_screen.dart';
import 'package:aspal/screens/settings_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController authController;
  late AuthRepository authRepository;
  late AuthLocalDataSource localDataSource;
  late MockAuthRemoteDataSource mockRemote;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

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

  group('SettingsTab & Profil Pengguna (FR-04)', () {
    testWidgets('Tampilan profil aktual dari cache saat offline', (tester) async {
      // Simulasikan login
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();

      // Putus jaringan
      mockRemote.simulateNetworkError = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsTab(controller: authController),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memverifikasi nama dan email aktual dari cache tampil (bukan Budi Santoso)
      expect(find.textContaining('Zaki Alfurqani'), findsOneWidget);
      expect(find.textContaining('zaki@aspal.id'), findsOneWidget);
      expect(find.textContaining('Budi Santoso'), findsNothing);
    });

    testWidgets('Perubahan nama profil berhasil melalui EditProfileScreen',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfileScreen(controller: authController),
                      ),
                    );
                  },
                  child: const Text('Open Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      // Masukkan nama baru
      await tester.enterText(
        find.byKey(const Key('edit-name-field')),
        'Zaki Alfurqani ST',
      );

      await tester.tap(find.byKey(const Key('save-profile-btn')));
      await tester.pumpAndSettle();

      // Profil di controller dan cache terbarui
      expect(authController.currentUser?.displayName,
          equals('Zaki Alfurqani ST'));
      expect(find.text('Open Edit'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Profil berhasil diperbarui'), findsOneWidget);
    });
  });

  group('ChangePasswordScreen & Validasi (FR-04)', () {
    testWidgets('Validasi form ubah password: field kosong dan password < 8 karakter',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangePasswordScreen(controller: authController),
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit tanpa mengisi apapun
      await tester.tap(find.byKey(const Key('save-password-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Kata Sandi Saat Ini wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);

      // Isi password baru kurang dari 8 karakter
      await tester.enterText(
        find.byKey(const Key('current-password-field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('new-password-field')),
        'short',
      );
      await tester.enterText(
        find.byKey(const Key('confirm-password-field')),
        'short',
      );

      await tester.tap(find.byKey(const Key('save-password-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Password minimal 8 karakter'), findsOneWidget);
    });

    testWidgets('Ubah password gagal jika kata sandi lama tidak sesuai',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangePasswordScreen(controller: authController),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('current-password-field')),
        'salah-password',
      );
      await tester.enterText(
        find.byKey(const Key('new-password-field')),
        'newpass12345',
      );
      await tester.enterText(
        find.byKey(const Key('confirm-password-field')),
        'newpass12345',
      );

      await tester.tap(find.byKey(const Key('save-password-btn')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Kata sandi lama tidak sesuai'), findsOneWidget);
    });

    testWidgets('Ubah password berhasil dengan verifikasi mock backend',
        (tester) async {
      await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );
      await authController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangePasswordScreen(controller: authController),
                      ),
                    );
                  },
                  child: const Text('Open Change Pass'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Change Pass'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('current-password-field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('new-password-field')),
        'newpass12345',
      );
      await tester.enterText(
        find.byKey(const Key('confirm-password-field')),
        'newpass12345',
      );

      await tester.tap(find.byKey(const Key('save-password-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Open Change Pass'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Kata sandi berhasil diubah!'), findsOneWidget);

      // Verifikasi login dengan password baru berhasil
      final newLogin = await authRepository.login(
        email: 'zaki@aspal.id',
        password: 'newpass12345',
      );
      expect(newLogin.accessToken, isNotEmpty);
    });
  });
}
