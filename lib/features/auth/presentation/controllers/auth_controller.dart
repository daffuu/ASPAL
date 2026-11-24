import 'package:flutter/foundation.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/logout_result.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/account_local_data_gateway.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  offlineAuthenticated,
  unauthenticated,
}

/// Controller pengelola status autentikasi dan siklus sesi pengguna.
///
/// Berbasis `ChangeNotifier` agar mudah diobservasi oleh antarmuka Flutter
/// atau framework state management lain tanpa ketergantungan paket luar.
class AuthController extends ChangeNotifier {
  AuthController({
    required this.authRepository,
    this.accountLocalDataGateway,
  });

  final AuthRepository authRepository;
  final AccountLocalDataGateway? accountLocalDataGateway;

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  AuthSession? _currentSession;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  AuthSession? get currentSession => _currentSession;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated ||
      _status == AuthStatus.offlineAuthenticated;

  bool get isOffline => _status == AuthStatus.offlineAuthenticated;
  bool get isLoading => _status == AuthStatus.authenticating;

  /// Inisialisasi awal saat aplikasi dibuka: memeriksa dan memulihkan sesi lokal.
  Future<void> initialize() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await authRepository.restoreSession();
      if (session != null) {
        _currentSession = session;
        final cached = await authRepository.getCachedProfile();
        _currentUser = cached?.userId == session.userId ? cached : session.toUser();

        // Tentukan apakah sesi berjalan dalam mode online penuh atau offline
        if (session.isAccessTokenExpired()) {
          _status = AuthStatus.offlineAuthenticated;
        } else {
          _status = AuthStatus.authenticated;
        }
      } else {
        _currentSession = null;
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Melakukan login menggunakan email dan password.
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await authRepository.login(
        email: email,
        password: password,
      );
      _currentSession = session;
      _currentUser = session.toUser();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Terjadi kesalahan saat masuk: $e';
      notifyListeners();
      return false;
    }
  }

  /// Melakukan registrasi akun baru.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      _currentSession = session;
      _currentUser = session.toUser();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Terjadi kesalahan saat pendaftaran: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mengambil profil terbaru dari backend / cache.
  Future<void> refreshProfile() async {
    final session = _currentSession;
    try {
      final user = await authRepository.getProfile();
      if (session == null ||
          !identical(session, _currentSession) ||
          session.userId != user.userId ||
          !isAuthenticated) {
        return;
      }
      _currentUser = user;
      notifyListeners();
    } catch (_) {
      // Jika refresh profil gagal karena jaringan, pertahankan data cache
    }
  }

  /// Memperbarui nama tampilan profil.
  Future<bool> updateProfile(String displayName) async {
    _errorMessage = null;
    try {
      final updatedUser = await authRepository.updateProfile(
        displayName: displayName,
      );
      _currentUser = updatedUser;
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(displayName: displayName);
      }
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mengubah password akun.
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    try {
      await authRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengubah kata sandi: $e';
      notifyListeners();
      return false;
    }
  }

  /// Memeriksa jumlah laporan dan tindak lanjut milik pengguna aktif yang belum terkirim.
  ///
  /// Menghitung status: DRAFT, MENUNGGU_SINYAL, MENGIRIM, dan GAGAL_TERKIRIM.
  /// Status TERKIRIM tidak dihitung.
  Future<int> getUnsentItemCount() async {
    final userId = _currentUser?.userId ?? _currentSession?.userId;
    if (userId == null || userId.isEmpty || accountLocalDataGateway == null) {
      return 0;
    }
    return accountLocalDataGateway!.getUnsentItemCount(userId);
  }

  /// Melakukan logout dan membersihkan sesi serta data lokal akun.
  ///
  /// Jika pengguna mengonfirmasi logout atau antrean kosong:
  /// 1. Beritahu server jika online.
  /// 2. Hapus sesi di Secure Storage.
  /// 3. Hapus cache profil di SharedPreferences.
  /// 4. Panggil gateway untuk membersihkan draft & data lokal terikat akun.
  Future<LogoutResult> logout() async {
    final previousStatus = _status;
    _status = AuthStatus.authenticating;
    notifyListeners();

    final userId = _currentUser?.userId ?? _currentSession?.userId;

    // Bersihkan data lokal akun melalui gateway jika userId valid
    final LogoutResult result;
    try {
      if (userId != null && userId.isNotEmpty) {
        await accountLocalDataGateway?.clearUserData(userId);
      }
      result = await authRepository.logout();
    } catch (_) {
      _status = previousStatus;
      notifyListeners();
      rethrow;
    }
    _currentSession = null;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();

    return result;
  }

  /// Membersihkan pesan error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
