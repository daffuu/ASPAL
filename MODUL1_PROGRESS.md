# MODUL 1 — AUTENTIKASI DAN MANAJEMEN AKUN
## Laporan Progress ASPAL

**Dikerjakan oleh:** Zaki (Modul 1)
**Terakhir diperbarui:** 2026-11-19
**Status keseluruhan:** ✅ Fase 1, 2, dan 3 selesai (Mode Mock — Backend belum tersedia)

---

## Ringkasan Status Fase

| Fase | Deskripsi | Status | Jumlah Test |
|------|-----------|--------|-------------|
| Fase 1 | Fondasi domain, repository, storage, mock datasource | ✅ Selesai | 32 unit tests |
| Fase 2 | UI screens, Auth Guard, routing, widget tests | ✅ Selesai | 20 widget tests |
| Fase 3 | FR-03 Logout, AccountLocalDataGateway, finalisasi TokenProvider | ✅ Selesai | 6 integration tests |
| **Total** | | | **58 tests, 0 failures** |

---

## Status Functional Requirements

| FR | Nama | Status | Catatan |
|----|------|--------|---------|
| FR-01 | Registrasi | ✅ SELESAI (Mode Mock) | Email duplikat disimulasikan |
| FR-02 | Login & Auth Guard | ✅ SELESAI (Mode Mock) | Splash screen, sesi offline 30 hari |
| FR-03 | Logout dengan konfirmasi antrean | ✅ SELESAI (Mode Mock) | Dialog peringatan, offline-safe |
| FR-04 | Profil dan Pengaturan Akun | ✅ SELESAI (Mode Mock) | Edit nama, ubah password |

---

## Inventaris File — Fase 1 (Domain & Data Layer)

### Domain Models
| File | Deskripsi |
|------|-----------|
| `lib/features/auth/domain/models/user.dart` | Model User (userId, displayName, email, createdAt, updatedAt) |
| `lib/features/auth/domain/models/auth_session.dart` | Model AuthSession + logika validitas sesi offline 30 hari |
| `lib/features/auth/domain/models/logout_result.dart` | Model LogoutResult (isLocalCleared, isServerNotified, hasUnconfirmedServerRevocation) |

### Domain Repositories / Interfaces
| File | Deskripsi |
|------|-----------|
| `lib/features/auth/domain/repositories/auth_repository.dart` | Interface AuthRepository (register, login, logout, getProfile, updateProfile, changePassword, refreshSession) |
| `lib/features/auth/domain/repositories/token_provider.dart` | Interface TokenProvider untuk Ikhsan — getAccessToken, getRefreshToken, getUserId, isSessionValid, refreshToken |
| `lib/features/auth/domain/repositories/account_local_data_gateway.dart` | Interface AccountLocalDataGateway untuk Hasyfi dan Daffa — getUnsentItemCount, clearUserData |

### Data — Services
| File | Deskripsi |
|------|-----------|
| `lib/features/auth/data/services/secure_storage_service.dart` | SecureStorageService — simpan/baca/hapus 8 kunci sensitif di flutter_secure_storage |
| `lib/features/auth/data/services/profile_cache_service.dart` | ProfileCacheService — cache profil non-sensitif di SharedPreferences (JSON) |

### Data — Datasources
| File | Deskripsi |
|------|-----------|
| `lib/features/auth/data/datasources/auth_local_data_source.dart` | AuthLocalDataSource — baca/tulis sesi dari SecureStorage |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | Interface AuthRemoteDataSource — abstraksi komunikasi backend |
| `lib/features/auth/data/datasources/mock_auth_remote_data_source.dart` | MockAuthRemoteDataSource — simulasi backend (delay, error, kasus duplikat) |
| `lib/features/auth/data/datasources/composite_account_local_data_gateway.dart` | CompositeAccountLocalDataGateway (agregasi) + MockAccountLocalDataGateway (testing) |

### Data — Repository Implementation
| File | Deskripsi |
|------|-----------|
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | AuthRepositoryImpl — implementasi AuthRepository + TokenProvider |

### Presentation — Controller & Scope
| File | Deskripsi |
|------|-----------|
| `lib/features/auth/presentation/controllers/auth_controller.dart` | AuthController (ChangeNotifier) — state autentikasi, getUnsentItemCount, logout |
| `lib/features/auth/presentation/auth_scope.dart` | AuthScope (InheritedNotifier) — context.authController |

### Module Entry Point
| File | Deskripsi |
|------|-----------|
| `lib/features/auth/auth_module.dart` | AuthModule.init() — inisialisasi semua dependensi; exposes controller, repository, gateway |

---

## Inventaris File — Fase 2 (UI Screens & Routing)

### Screens (Baru / Direfaktor)
| File | Status | Deskripsi |
|------|--------|-----------|
| `lib/screens/splash_screen.dart` | 🆕 Baru | Startup auth check, routing ke login/home/refresh |
| `lib/screens/login_screen.dart` | ♻️ Refaktor | Dihubungkan ke AuthController; hapus Guest & Tes 404 |
| `lib/screens/register_screen.dart` | 🆕 Baru | FR-01 Registrasi — validasi, loading, pesan error |
| `lib/screens/edit_profile_screen.dart` | 🆕 Baru | FR-04 Edit nama profil — perbarui cache setelah sukses |
| `lib/screens/change_password_screen.dart` | 🆕 Baru | FR-04 Ubah password — wajib online, verifikasi backend |
| `lib/screens/settings_tab.dart` | ♻️ Refaktor | Profil aktual dari cache; FR-03 logout handler lengkap |
| `lib/screens/home_shell.dart` | ♻️ Refaktor | Tampilkan displayName aktual dari AuthController |

### Routing & Utilities
| File | Status | Deskripsi |
|------|--------|-----------|
| `lib/routes/app_routes.dart` | ♻️ Refaktor | Auth Guard di onGenerateRoute; route baru ditambahkan |
| `lib/main.dart` | ♻️ Refaktor | AuthModule.init() + AuthScope; initialRoute = splash |
| `lib/utils/validators.dart` | ♻️ Refaktor | Tambah confirmPassword, validateEmail, validatePassword, validateNote |

---

## Inventaris File — Fase 3 (Logout, Gateway, Finalisasi)

### Perubahan Domain (Fase 3)
| File | Perubahan |
|------|-----------|
| `lib/features/auth/domain/models/logout_result.dart` | **Baru** — model hasil logout (lokal + server) |
| `lib/features/auth/domain/repositories/account_local_data_gateway.dart` | **Baru** — interface untuk Hasyfi dan Daffa |
| `lib/features/auth/domain/repositories/auth_repository.dart` | **Diperbarui** — logout() kini mengembalikan `Future<LogoutResult>` |

### Perubahan Data (Fase 3)
| File | Perubahan |
|------|-----------|
| `lib/features/auth/data/datasources/composite_account_local_data_gateway.dart` | **Baru** — CompositeGateway + MockAccountLocalDataGateway |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | **Diperbarui** — logout() mencoba remote terlebih dahulu, selalu bersihkan lokal |

### Perubahan Presentation (Fase 3)
| File | Perubahan |
|------|-----------|
| `lib/features/auth/presentation/controllers/auth_controller.dart` | **Diperbarui** — terima AccountLocalDataGateway; getUnsentItemCount(); logout() penuh |
| `lib/features/auth/auth_module.dart` | **Diperbarui** — ekspor CompositeGateway; gateway statis; init() terima customGateway |
| `lib/screens/settings_tab.dart` | **Diperbarui** — _handleLogout() lengkap dengan dialog dan SnackBar offline |

### Test (Fase 3)
| File | Deskripsi |
|------|-----------|
| `test/features/auth/logout_flow_test.dart` | 6 skenario: antrean kosong, dialog tampil, batal, konfirmasi, offline, isolasi akun |

---

## Inventaris File — Tests

| File | Fase | Jumlah Test |
|------|------|-------------|
| `test/features/auth/auth_session_test.dart` | 1 | Unit tests AuthSession |
| `test/features/auth/secure_storage_service_test.dart` | 1 | Unit tests SecureStorageService |
| `test/features/auth/profile_cache_service_test.dart` | 1 | Unit tests ProfileCacheService |
| `test/features/auth/mock_auth_remote_data_source_test.dart` | 1 | Unit tests MockAuthRemoteDataSource |
| `test/features/auth/auth_repository_impl_test.dart` | 1 | Unit tests AuthRepositoryImpl |
| `test/features/auth/auth_controller_test.dart` | 1 | Unit tests AuthController |
| `test/screens/login_screen_test.dart` | 2 | Widget tests LoginScreen |
| `test/screens/register_screen_test.dart` | 2 | Widget tests RegisterScreen |
| `test/screens/splash_screen_test.dart` | 2 | Widget tests SplashScreen |
| `test/screens/settings_tab_test.dart` | 2 | Widget tests SettingsTab |
| `test/screens/edit_profile_screen_test.dart` | 2 | Widget tests EditProfileScreen |
| `test/screens/change_password_screen_test.dart` | 2 | Widget tests ChangePasswordScreen |
| `test/features/auth/logout_flow_test.dart` | 3 | Integration tests logout flow |
| **Total** | | **58 tests** |

---

## Aturan Penyimpanan Data

### Secure Storage (`flutter_secure_storage`) — Sumber Utama Autentikasi
```
user_id                    → ID pengguna aktif
display_name               → Nama tampilan
email                      → Email pengguna
access_token               → Bearer token untuk API
refresh_token              → Token untuk memperbarui sesi
token_expires_at           → Waktu kedaluwarsa access token (ISO 8601)
logged_in_at               → Waktu login terakhir (ISO 8601)
offline_session_expires_at → Batas sesi offline 30 hari (ISO 8601)
```

### SharedPreferences — Cache Profil Tampilan (Non-Sensitif)
```
profile_cache → JSON: { user_id, display_name, email, updated_at }
```

### SQLite
> **Modul 1 tidak membuat database atau tabel SQLite.**
> Database laporan adalah tanggung jawab Hasyfi; tindak lanjut adalah tanggung jawab Daffa.

### Yang TIDAK Pernah Disimpan
- Password dalam bentuk apapun (plain text, hashed, atau terenkripsi)

---

## Kontrak Integrasi untuk Anggota Tim

### Untuk Hasyfi (Modul Laporan)

Implementasikan `AccountLocalDataGateway` untuk tabel laporan:

```dart
import 'package:aspal/features/auth/domain/repositories/account_local_data_gateway.dart';

class ReportLocalDataGateway implements AccountLocalDataGateway {
  final Database _db; // SQLite database milik Hasyfi

  ReportLocalDataGateway(this._db);

  @override
  Future<int> getUnsentItemCount(String userId) async {
    // Hitung laporan belum terkirim milik userId
    // Status yang dihitung: DRAFT, MENUNGGU_SINYAL, MENGIRIM, GAGAL_TERKIRIM
    // Status TERKIRIM tidak dihitung
    const statuses = ['DRAFT', 'MENUNGGU_SINYAL', 'MENGIRIM', 'GAGAL_TERKIRIM'];
    final placeholders = statuses.map((_) => '?').join(', ');
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM reports '
      'WHERE user_id = ? AND sync_status IN ($placeholders)',
      [userId, ...statuses],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> clearUserData(String userId) async {
    // Hapus data lokal milik userId saja
    // Jangan menghapus data milik user lain
    await _db.delete('reports', where: 'user_id = ?', whereArgs: [userId]);
    // Hapus sync_attempts jika ada
    await _db.delete(
      'sync_attempts',
      where: "entity_type = 'report' AND user_id = ?",
      whereArgs: [userId],
    );
  }
}

// Daftarkan di app startup (setelah database siap):
AuthModule.gateway.registerGateway(ReportLocalDataGateway(database));
```

### Untuk Daffa (Modul Tindak Lanjut)

Implementasikan `AccountLocalDataGateway` untuk tabel tindak lanjut:

```dart
import 'package:aspal/features/auth/domain/repositories/account_local_data_gateway.dart';

class FollowupLocalDataGateway implements AccountLocalDataGateway {
  final Database _db; // SQLite database milik Daffa

  FollowupLocalDataGateway(this._db);

  @override
  Future<int> getUnsentItemCount(String userId) async {
    const statuses = ['DRAFT', 'MENUNGGU_SINYAL', 'MENGIRIM', 'GAGAL_TERKIRIM'];
    final placeholders = statuses.map((_) => '?').join(', ');
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM followups '
      'WHERE user_id = ? AND sync_status IN ($placeholders)',
      [userId, ...statuses],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> clearUserData(String userId) async {
    await _db.delete('followups', where: 'user_id = ?', whereArgs: [userId]);
  }
}

// Daftarkan di app startup:
AuthModule.gateway.registerGateway(FollowupLocalDataGateway(database));
```

### Untuk Ikhsan (API Client & Background Sync)

Gunakan `TokenProvider` yang sudah diimplementasikan oleh `AuthRepositoryImpl`:

```dart
import 'package:aspal/features/auth/domain/repositories/token_provider.dart';
import 'package:aspal/features/auth/auth_module.dart';

// Dapatkan TokenProvider dari AuthModule:
final TokenProvider tokenProvider = AuthModule.repository;

// Penggunaan di API client:
class ApiClient {
  Future<Response> makeRequest(String endpoint) async {
    // 1. Periksa validitas sesi sebelum request
    if (!tokenProvider.isSessionValid()) {
      throw InvalidTokenException('Sesi tidak valid');
    }

    // 2. Dapatkan access token (auto-refresh jika hampir kedaluwarsa)
    final token = await tokenProvider.getAccessToken();
    if (token == null) throw InvalidTokenException('Token tidak tersedia');

    // 3. Buat HTTP request dengan Authorization header
    // return await http.get(endpoint, headers: {'Authorization': 'Bearer $token'});
  }

  // Tangani HTTP 401:
  Future<void> handleUnauthorized() async {
    final newToken = await tokenProvider.refreshToken();
    if (newToken == null) {
      // Token benar-benar tidak valid — JEDA sinkronisasi, JANGAN hapus antrean
      // Notify AuthController untuk invalidate session
      AuthModule.controller.handleRemoteSessionRevoked();
    }
    // Jika newToken ada, coba request ulang
  }
}
```

**Method yang tersedia di TokenProvider:**
| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `getAccessToken()` | `Future<String?>` | Token saat ini; null jika tidak ada sesi |
| `getRefreshToken()` | `Future<String?>` | Refresh token; null jika tidak ada sesi |
| `getUserId()` | `Future<String?>` | User ID aktif; null jika tidak ada sesi |
| `isSessionValid()` | `bool` | True jika sesi offline 30 hari masih berlaku |
| `refreshToken()` | `Future<String?>` | Access token baru; null jika gagal |

**Aturan penting untuk background sync:**
- Jika `refreshToken()` mengembalikan `null` karena jaringan → **JEDA sinkronisasi, JANGAN hapus antrean**
- Jika `refreshToken()` mengembalikan `null` karena server menolak (HTTP 401 pada refresh endpoint) → sesi dicabut, **JEDA sinkronisasi, JANGAN hapus antrean**
- Jangan menganggap kegagalan jaringan sebagai pencabutan sesi

---

## Aturan Sesi

| Kondisi | Perilaku |
|---------|----------|
| Online, token valid | Lanjutkan dengan token yang ada |
| Online, token hampir kedaluwarsa | Auto-refresh di background |
| Online, refresh token ditolak server | Invalidate sesi → paksa login ulang |
| Offline, sesi lokal ≤ 30 hari | Izinkan akses aplikasi tanpa online |
| Offline, sesi lokal > 30 hari | Arahkan ke halaman login |
| Logout saat offline | Logout lokal berhasil; server tidak terkonfirmasi |
| Sesi kedaluwarsa saat ada draft | **JANGAN hapus draft laporan** |

---

## Mock API — Akun Uji

> Gunakan akun berikut saat menguji secara manual dengan Mock API:

| Field | Nilai |
|-------|-------|
| Email | `zaki@aspal.id` |
| Password | `password123` |
| User ID | `usr-default-001` |
| Nama | `Zaki` |

**Skenario yang disimulasikan MockAuthRemoteDataSource:**
- ✅ Registrasi berhasil (email baru)
- ❌ Registrasi gagal — email duplikat
- ✅ Login berhasil
- ❌ Login gagal — kredensial salah
- ✅ Refresh token berhasil
- ❌ Refresh token gagal (simulasi token dicabut)
- ✅ Ambil profil
- ✅ Perbarui profil (nama)
- ✅ Ubah password
- ❌ Gangguan jaringan (simulasi timeout)

---

## Yang Masih Membutuhkan Backend Nyata

| Item | Keterangan |
|------|-----------|
| URL endpoint backend | Belum ada; koordinasi dengan Ikhsan |
| HTTP client bersama | Dikerjakan oleh Ikhsan; Modul 1 sudah siap dihubungkan |
| Token refresh endpoint `/auth/refresh` | Sudah ada di interface; perlu URL nyata |
| Logout endpoint `/auth/logout` | Sudah ada di interface; perlu URL nyata |
| Skema database Hasyfi | Diperlukan agar ReportLocalDataGateway bisa dibuat final |
| Skema database Daffa | Diperlukan agar FollowupLocalDataGateway bisa dibuat final |

---

## Rekomendasi Pull Request

**Branch:** `feat/modul1-autentikasi` → target: `feat/integrasi-modul` (atau `main` sesuai kesepakatan tim)

**Checklist sebelum merge:**
- [x] `flutter analyze` — 0 error, 0 warning (hanya info `withOpacity` di file legacy luar scope)
- [x] `flutter test` — 58 tests passed, 0 failures
- [x] Tidak ada perubahan pada database SQLite
- [x] Tidak menyentuh file milik Hasyfi, Ikhsan, atau Daffa
- [x] Password tidak disimpan di perangkat dalam bentuk apapun
- [x] Auth Guard melindungi seluruh route dari akses tanpa autentikasi
- [ ] Backend URL dikonfigurasi (blocker: belum tersedia)
- [ ] ReportLocalDataGateway didaftarkan oleh Hasyfi
- [ ] FollowupLocalDataGateway didaftarkan oleh Daffa
- [ ] API client Ikhsan terhubung dengan TokenProvider

---

## Catatan Teknis

### Arsitektur
Modul 1 menggunakan Clean Architecture:
```
lib/features/auth/
├── domain/
│   ├── models/           ← Pure Dart, tidak ada dependensi Flutter
│   └── repositories/     ← Interface (abstract) saja
├── data/
│   ├── datasources/      ← Implementasi konkret + mock
│   ├── repositories/     ← Implementasi interface domain
│   └── services/         ← Storage services
└── presentation/
    ├── controllers/      ← AuthController (ChangeNotifier)
    └── auth_scope.dart   ← InheritedNotifier untuk widget tree
```

### Cara Mengganti Mock dengan Backend Nyata
1. Implementasikan `AuthRemoteDataSource` di file baru (misal `http_auth_remote_data_source.dart`)
2. Gunakan HTTP client bersama dari Ikhsan
3. Di `AuthModule.init()`, ganti `MockAuthRemoteDataSource()` dengan implementasi HTTP
4. **Tidak ada perubahan pada UI, controller, atau domain layer**

### Dependency Packages yang Digunakan Modul 1
```yaml
flutter_secure_storage: ^11.2.0  # Penyimpanan token sensitif
shared_preferences: ^2.5.6       # Cache profil non-sensitif
```
