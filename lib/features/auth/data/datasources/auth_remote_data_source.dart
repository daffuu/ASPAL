import '../../domain/models/user.dart';

/// DTO untuk respons autentikasi remote (login / register / refresh).
class AuthRemoteResponse {
  const AuthRemoteResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiresAt,
    required this.offlineSessionExpiresAt,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiresAt;
  final DateTime offlineSessionExpiresAt;
}

/// Base exception untuk seluruh kegagalan modul autentikasi.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class DuplicateEmailException extends AuthException {
  const DuplicateEmailException([super.message = 'Email sudah terdaftar'])
      : super(code: 'DUPLICATE_EMAIL');
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException(
      [super.message = 'Email atau kata sandi tidak sesuai'])
      : super(code: 'INVALID_CREDENTIALS');
}

class InvalidTokenException extends AuthException {
  const InvalidTokenException(
      [super.message = 'Sesi atau token tidak valid'])
      : super(code: 'INVALID_TOKEN');
}

class NetworkException extends AuthException {
  const NetworkException(
      [super.message = 'Tidak ada koneksi internet atau jaringan terganggu'])
      : super(code: 'NETWORK_ERROR');
}

class ServerException extends AuthException {
  const ServerException(
      [super.message = 'Terjadi kesalahan pada server, silakan coba lagi'])
      : super(code: 'SERVER_ERROR');
}

class InvalidCurrentPasswordException extends AuthException {
  const InvalidCurrentPasswordException(
      [super.message = 'Kata sandi lama tidak sesuai'])
      : super(code: 'INVALID_CURRENT_PASSWORD');
}

/// Abstraksi komunikasi dengan remote backend/API autentikasi.
///
/// Interface ini nantinya digantikan oleh integrasi HTTP client bersama
/// (yang dikoordinasikan dengan Ikhsan) tanpa mengubah controller atau UI.
abstract interface class AuthRemoteDataSource {
  /// Registrasi akun baru.
  Future<AuthRemoteResponse> register({
    required String name,
    required String email,
    required String password,
  });

  /// Login dengan email dan password.
  Future<AuthRemoteResponse> login({
    required String email,
    required String password,
  });

  /// Memperbarui token menggunakan refresh token.
  Future<AuthRemoteResponse> refreshToken({
    required String refreshToken,
  });

  /// Mengambil profil terkini dari backend.
  Future<User> getProfile({
    required String accessToken,
  });

  /// Mengubah nama tampilan profil.
  Future<User> updateProfile({
    required String accessToken,
    required String displayName,
  });

  /// Mengubah password akun.
  Future<void> updatePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  });

  /// Memberitahu server bahwa sesi telah logout.
  Future<void> logout({
    required String accessToken,
  });
}
