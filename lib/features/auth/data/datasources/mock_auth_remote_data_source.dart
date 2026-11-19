import 'dart:math';

import '../../domain/models/user.dart';
import 'auth_remote_data_source.dart';

class _MockUserRecord {
  _MockUserRecord({
    required this.user,
    required this.password,
  });

  User user;
  String password;
}

/// Implementasi Mock API untuk modul autentikasi ASPAL.
///
/// Menyediakan simulasi in-memory untuk kebutuhan pengembangan dan pengujian
/// sebelum API backend sesungguhnya diintegrasikan dengan HTTP client bersama.
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  MockAuthRemoteDataSource({
    Duration networkDelay = const Duration(milliseconds: 50),
  }) : _delay = networkDelay {
    _seedDefaultUsers();
  }

  final Duration _delay;

  // Kontrol simulasi untuk testing
  bool simulateNetworkError = false;
  bool simulateServerError = false;
  bool simulateInvalidRefreshToken = false;

  final Map<String, _MockUserRecord> _usersByEmail = {};
  final Map<String, String> _userIdByAccessToken = {};
  final Map<String, String> _userIdByRefreshToken = {};

  void _seedDefaultUsers() {
    final defaultUser = User(
      userId: 'usr-default-001',
      displayName: 'Zaki Alfurqani',
      email: 'zaki@aspal.id',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    );
    _usersByEmail['zaki@aspal.id'] = _MockUserRecord(
      user: defaultUser,
      password: 'password123',
    );
  }

  Future<void> _maybeThrowSimulatedErrors() async {
    if (_delay > Duration.zero) {
      await Future.delayed(_delay);
    }
    if (simulateNetworkError) {
      throw const NetworkException('Jaringan terputus (simulasi)');
    }
    if (simulateServerError) {
      throw const ServerException('Server internal error 500 (simulasi)');
    }
  }

  String _generateToken(String prefix, String userId) {
    final rand = Random().nextInt(9999999).toString().padLeft(7, '0');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$userId-$timestamp-$rand';
  }

  @override
  Future<AuthRemoteResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _maybeThrowSimulatedErrors();

    final normalizedEmail = email.trim().toLowerCase();
    if (_usersByEmail.containsKey(normalizedEmail)) {
      throw const DuplicateEmailException();
    }

    final userId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final newUser = User(
      userId: userId,
      displayName: name.trim(),
      email: normalizedEmail,
      createdAt: now,
      updatedAt: now,
    );

    _usersByEmail[normalizedEmail] = _MockUserRecord(
      user: newUser,
      password: password,
    );

    final accessToken = _generateToken('access', userId);
    final refreshToken = _generateToken('refresh', userId);

    _userIdByAccessToken[accessToken] = userId;
    _userIdByRefreshToken[refreshToken] = userId;

    return AuthRemoteResponse(
      user: newUser,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiresAt: now.add(const Duration(hours: 1)),
      offlineSessionExpiresAt: now.add(const Duration(days: 30)),
    );
  }

  @override
  Future<AuthRemoteResponse> login({
    required String email,
    required String password,
  }) async {
    await _maybeThrowSimulatedErrors();

    final normalizedEmail = email.trim().toLowerCase();
    final record = _usersByEmail[normalizedEmail];

    if (record == null || record.password != password) {
      throw const InvalidCredentialsException();
    }

    final now = DateTime.now();
    final accessToken = _generateToken('access', record.user.userId);
    final refreshToken = _generateToken('refresh', record.user.userId);

    _userIdByAccessToken[accessToken] = record.user.userId;
    _userIdByRefreshToken[refreshToken] = record.user.userId;

    return AuthRemoteResponse(
      user: record.user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiresAt: now.add(const Duration(hours: 1)),
      offlineSessionExpiresAt: now.add(const Duration(days: 30)),
    );
  }

  @override
  Future<AuthRemoteResponse> refreshToken({
    required String refreshToken,
  }) async {
    await _maybeThrowSimulatedErrors();

    if (simulateInvalidRefreshToken) {
      throw const InvalidTokenException('Refresh token ditolak server');
    }

    final userId = _userIdByRefreshToken[refreshToken];
    if (userId == null) {
      throw const InvalidTokenException('Refresh token tidak dikenali');
    }

    // Cari user
    _MockUserRecord? foundRecord;
    for (final record in _usersByEmail.values) {
      if (record.user.userId == userId) {
        foundRecord = record;
        break;
      }
    }

    if (foundRecord == null) {
      throw const InvalidTokenException('Pengguna tidak ditemukan');
    }

    // Buat token baru (token rotation)
    final now = DateTime.now();
    final newAccessToken = _generateToken('access', userId);
    final newRefreshToken = _generateToken('refresh', userId);

    _userIdByAccessToken.removeWhere((k, v) => v == userId);
    _userIdByRefreshToken.remove(refreshToken);

    _userIdByAccessToken[newAccessToken] = userId;
    _userIdByRefreshToken[newRefreshToken] = userId;

    return AuthRemoteResponse(
      user: foundRecord.user,
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      tokenExpiresAt: now.add(const Duration(hours: 1)),
      offlineSessionExpiresAt: now.add(const Duration(days: 30)),
    );
  }

  @override
  Future<User> getProfile({required String accessToken}) async {
    await _maybeThrowSimulatedErrors();

    final userId = _userIdByAccessToken[accessToken];
    if (userId == null) {
      throw const InvalidTokenException();
    }

    for (final record in _usersByEmail.values) {
      if (record.user.userId == userId) {
        return record.user;
      }
    }

    throw const InvalidTokenException('Pengguna tidak ditemukan');
  }

  @override
  Future<User> updateProfile({
    required String accessToken,
    required String displayName,
  }) async {
    await _maybeThrowSimulatedErrors();

    final userId = _userIdByAccessToken[accessToken];
    if (userId == null) {
      throw const InvalidTokenException();
    }

    for (final record in _usersByEmail.values) {
      if (record.user.userId == userId) {
        final updated = record.user.copyWith(
          displayName: displayName.trim(),
          updatedAt: DateTime.now(),
        );
        record.user = updated;
        return updated;
      }
    }

    throw const InvalidTokenException('Pengguna tidak ditemukan');
  }

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _maybeThrowSimulatedErrors();

    final userId = _userIdByAccessToken[accessToken];
    if (userId == null) {
      throw const InvalidTokenException();
    }

    for (final record in _usersByEmail.values) {
      if (record.user.userId == userId) {
        if (record.password != currentPassword) {
          throw const InvalidCurrentPasswordException();
        }
        record.password = newPassword;
        record.user = record.user.copyWith(updatedAt: DateTime.now());
        return;
      }
    }

    throw const InvalidTokenException('Pengguna tidak ditemukan');
  }

  @override
  Future<void> logout({required String accessToken}) async {
    await _maybeThrowSimulatedErrors();

    final userId = _userIdByAccessToken.remove(accessToken);
    if (userId != null) {
      _userIdByRefreshToken.removeWhere((k, v) => v == userId);
    }
  }

  /// Helper untuk reset state mock pada saat unit test.
  void reset({bool keepDefaultUsers = true}) {
    simulateNetworkError = false;
    simulateServerError = false;
    simulateInvalidRefreshToken = false;
    _usersByEmail.clear();
    _userIdByAccessToken.clear();
    _userIdByRefreshToken.clear();
    if (keepDefaultUsers) {
      _seedDefaultUsers();
    }
  }
}
