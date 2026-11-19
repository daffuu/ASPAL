import 'package:flutter_test/flutter_test.dart';

import 'package:aspal/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:aspal/features/auth/data/datasources/mock_auth_remote_data_source.dart';

void main() {
  group('MockAuthRemoteDataSource Test', () {
    late MockAuthRemoteDataSource remoteDataSource;

    setUp(() {
      remoteDataSource = MockAuthRemoteDataSource(
        networkDelay: Duration.zero,
      );
    });

    test('Registrasi berhasil dengan data valid', () async {
      final res = await remoteDataSource.register(
        name: 'Daffa Valiant',
        email: 'daffa.new@aspal.id',
        password: 'password123',
      );

      expect(res.user.displayName, equals('Daffa Valiant'));
      expect(res.user.email, equals('daffa.new@aspal.id'));
      expect(res.accessToken, isNotEmpty);
      expect(res.refreshToken, isNotEmpty);
      expect(res.tokenExpiresAt.isAfter(DateTime.now()), isTrue);
      expect(res.offlineSessionExpiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('Registrasi gagal saat email duplikat', () async {
      // Email default yang sudah di-seed: zaki@aspal.id
      expect(
        () => remoteDataSource.register(
          name: 'Zaki Duplikat',
          email: 'zaki@aspal.id',
          password: 'password123',
        ),
        throwsA(isA<DuplicateEmailException>()),
      );
    });

    test('Login berhasil dengan kredensial yang tepat', () async {
      final res = await remoteDataSource.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      expect(res.user.email, equals('zaki@aspal.id'));
      expect(res.accessToken, isNotEmpty);
      expect(res.refreshToken, isNotEmpty);
    });

    test('Login gagal saat password salah atau email tidak terdaftar', () async {
      // Password salah
      expect(
        () => remoteDataSource.login(
          email: 'zaki@aspal.id',
          password: 'wrong_password',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );

      // Email tidak terdaftar
      expect(
        () => remoteDataSource.login(
          email: 'notfound@aspal.id',
          password: 'password123',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('Refresh token berhasil menghasilkan access token dan refresh token baru',
        () async {
      final loginRes = await remoteDataSource.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      final refreshRes = await remoteDataSource.refreshToken(
        refreshToken: loginRes.refreshToken,
      );

      expect(refreshRes.accessToken, isNotEmpty);
      expect(refreshRes.refreshToken, isNotEmpty);
      expect(refreshRes.accessToken, isNot(equals(loginRes.accessToken)));
    });

    test('Refresh token gagal saat token tidak valid atau ditolak server', () async {
      expect(
        () => remoteDataSource.refreshToken(refreshToken: 'invalid-token-xyz'),
        throwsA(isA<InvalidTokenException>()),
      );

      remoteDataSource.simulateInvalidRefreshToken = true;
      expect(
        () => remoteDataSource.refreshToken(refreshToken: 'any-token'),
        throwsA(isA<InvalidTokenException>()),
      );
    });

    test('Pengambilan profil dan perubahan nama tampil profil', () async {
      final loginRes = await remoteDataSource.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      final profile = await remoteDataSource.getProfile(
        accessToken: loginRes.accessToken,
      );
      expect(profile.email, equals('zaki@aspal.id'));

      final updatedProfile = await remoteDataSource.updateProfile(
        accessToken: loginRes.accessToken,
        displayName: 'Zaki Alfurqani Updated',
      );
      expect(updatedProfile.displayName, equals('Zaki Alfurqani Updated'));
    });

    test('Perubahan password: gagal jika password lama salah, berhasil jika benar',
        () async {
      final loginRes = await remoteDataSource.login(
        email: 'zaki@aspal.id',
        password: 'password123',
      );

      // Password lama salah
      expect(
        () => remoteDataSource.updatePassword(
          accessToken: loginRes.accessToken,
          currentPassword: 'salah-password',
          newPassword: 'new-password-123',
        ),
        throwsA(isA<InvalidCurrentPasswordException>()),
      );

      // Password lama benar
      await remoteDataSource.updatePassword(
        accessToken: loginRes.accessToken,
        currentPassword: 'password123',
        newPassword: 'new-password-123',
      );

      // Login dengan password baru berhasil
      final newLogin = await remoteDataSource.login(
        email: 'zaki@aspal.id',
        password: 'new-password-123',
      );
      expect(newLogin.user.email, equals('zaki@aspal.id'));
    });

    test('Simulasi gangguan jaringan (NetworkException) dan server (ServerException)',
        () async {
      remoteDataSource.simulateNetworkError = true;
      expect(
        () => remoteDataSource.login(
          email: 'zaki@aspal.id',
          password: 'password123',
        ),
        throwsA(isA<NetworkException>()),
      );

      remoteDataSource.simulateNetworkError = false;
      remoteDataSource.simulateServerError = true;
      expect(
        () => remoteDataSource.login(
          email: 'zaki@aspal.id',
          password: 'password123',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
