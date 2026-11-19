import 'user.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiresAt,
    required this.loggedInAt,
    required this.offlineSessionExpiresAt,
  });

  final String userId;
  final String displayName;
  final String email;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiresAt;
  final DateTime loggedInAt;
  final DateTime offlineSessionExpiresAt;

  /// Memeriksa apakah access token telah melewati batas masa berlaku.
  bool isAccessTokenExpired({DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.isAfter(tokenExpiresAt);
  }

  /// Memeriksa apakah sesi offline (30 hari) telah kedaluwarsa.
  bool isOfflineSessionExpired({DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.isAfter(offlineSessionExpiresAt);
  }

  /// Sesi offline masih sah jika belum kedaluwarsa.
  bool isOfflineSessionValid({DateTime? now}) {
    return !isOfflineSessionExpired(now: now);
  }

  User toUser() {
    return User(
      userId: userId,
      displayName: displayName,
      email: email,
    );
  }

  AuthSession copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    DateTime? loggedInAt,
    DateTime? offlineSessionExpiresAt,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      loggedInAt: loggedInAt ?? this.loggedInAt,
      offlineSessionExpiresAt:
          offlineSessionExpiresAt ?? this.offlineSessionExpiresAt,
    );
  }

  Map<String, String> toStorageMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'email': email,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expires_at': tokenExpiresAt.toIso8601String(),
      'logged_in_at': loggedInAt.toIso8601String(),
      'offline_session_expires_at': offlineSessionExpiresAt.toIso8601String(),
    };
  }

  factory AuthSession.fromStorageMap(Map<String, String?> map) {
    final userId = map['user_id'];
    final accessToken = map['access_token'];
    final refreshToken = map['refresh_token'];
    final tokenExpiresAtStr = map['token_expires_at'];
    final loggedInAtStr = map['logged_in_at'];
    final offlineSessionExpiresAtStr = map['offline_session_expires_at'];

    if (userId == null ||
        accessToken == null ||
        refreshToken == null ||
        tokenExpiresAtStr == null ||
        loggedInAtStr == null ||
        offlineSessionExpiresAtStr == null) {
      throw const FormatException('Data sesi di secure storage tidak lengkap');
    }

    return AuthSession(
      userId: userId,
      displayName: map['display_name'] ?? '',
      email: map['email'] ?? '',
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiresAt: DateTime.parse(tokenExpiresAtStr),
      loggedInAt: DateTime.parse(loggedInAtStr),
      offlineSessionExpiresAt: DateTime.parse(offlineSessionExpiresAtStr),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          tokenExpiresAt == other.tokenExpiresAt &&
          offlineSessionExpiresAt == other.offlineSessionExpiresAt;

  @override
  int get hashCode =>
      userId.hashCode ^
      accessToken.hashCode ^
      refreshToken.hashCode ^
      tokenExpiresAt.hashCode ^
      offlineSessionExpiresAt.hashCode;

  @override
  String toString() =>
      'AuthSession(userId: $userId, email: $email, tokenExpiresAt: $tokenExpiresAt, offlineExpiresAt: $offlineSessionExpiresAt)';
}
