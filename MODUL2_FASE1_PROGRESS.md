# ASPAL — Issue 2 Fase 1

## Status

**DONE** pada 24 November 2026. Repository lokal dapat menyimpan draft belum lengkap, membacanya kembali setelah database ditutup, dan membatasi operasi ke akun aktif.

## Dependency

| Paket | Versi di pubspec | Kegunaan |
| --- | --- | --- |
| sqflite | ^2.4.6 | Driver SQLite produksi Android, sudah tersedia saat inspeksi |
| path | ^1.9.1 | Menyusun lokasi file database, sudah tersedia |
| uuid | ^4.6.0 | Membuat UUID v4 pada insert pertama, sudah tersedia |
| sqflite_common_ffi | ^2.4.4 | Dev dependency baru untuk menguji migration dan SQL yang sama pada SQLite Windows |

Resolver memperbarui `pubspec.lock` untuk dependency pengujian.

## Database

`AppDatabase.instance` membuka `aspal.db` di direktori database aplikasi saat operasi data pertama. Pemanggil berbagi koneksi. Versi saat ini **1**. Registry di `lib/core/database/app_database.dart` menjalankan migration secara berurutan pada create dan upgrade dalam transaksi sqflite. Untuk versi berikutnya, tambahkan fungsi migration baru di akhir daftar `_migrations`. Panjang daftar menentukan versi.

| Tabel | Index yang dibuat migration v1 |
| --- | --- |
| reports | reports_user (user_id), reports_status (sync_status), reports_user_status (user_id, sync_status), reports_user_created (user_id, created_at) |
| sync_attempts | attempts_entity (entity_type, entity_id) |

Tabel log memiliki kolom `attempt_id INTEGER PRIMARY KEY`, `entity_type TEXT`, `entity_id TEXT`, `attempt_no INTEGER`, `attempted_at TEXT`, `trigger TEXT`, `result TEXT`, `http_status INTEGER`, `error_code TEXT`, dan `error_message TEXT`. Tiga kolom terakhir opsional. Untuk percobaan laporan, gunakan `entity_type = 'report'` dan UUID lokal sebagai `entity_id`. Trigger `reports_delete_attempts` menghapus log pasangan tersebut dalam operasi delete yang sama, termasuk ketika gateway membersihkan akun.

## Reports Schema

| Kolom | Tipe SQLite | Aturan |
| --- | --- | --- |
| report_id | TEXT | PRIMARY KEY NOT NULL, UUID v4 stabil dari klien |
| user_id | TEXT | NOT NULL, pemilik dari Auth |
| category | TEXT | Opsional |
| severity | TEXT | Opsional |
| description | TEXT | Opsional |
| latitude | REAL | Opsional |
| longitude | REAL | Opsional |
| gps_accuracy | REAL | Opsional |
| gps_source | TEXT | Opsional |
| photo_local_path | TEXT | Opsional |
| photo_remote_url | TEXT | Opsional |
| thumbnail_path | TEXT | Opsional |
| photo_size_bytes | INTEGER | Opsional |
| sync_status | TEXT | NOT NULL, default DRAFT, CHECK untuk kelima status PRD |
| road_condition | TEXT | Opsional, kondisi jalan dari server |
| server_report_id | TEXT | Opsional, ID yang diberikan backend |
| created_at | TEXT | NOT NULL, ISO-8601 UTC |
| updated_at | TEXT | NOT NULL, ISO-8601 UTC |
| synced_at | TEXT | Opsional, ISO-8601 UTC |
| retry_count | INTEGER | NOT NULL, default 0 |
| last_attempt_at | TEXT | Opsional, ISO-8601 UTC |
| next_retry_at | TEXT | Opsional, ISO-8601 UTC |
| last_error_message | TEXT | Opsional |

## Repository dan integrasi Auth

- `ReportsModule.repository` menyediakan CRUD, filter status, jumlah belum terkirim, dan pembersihan akun. Setiap operasi meminta pemilik melalui `TokenProvider.getUserId()`. Sesi kosong menghasilkan `StateError`.
- `createReport()` membuat draft kosong. Pemanggil juga dapat menyertakan `ReportContent`. `updateReport(id, content)` mengganti seluruh isian yang bisa diedit. Nilai null mengosongkan kolom terkait. UUID, pemilik, waktu pembuatan, dan metadata sinkronisasi dipertahankan.
- Update dan delete memeriksa UUID, pemilik, dan status di SQLite. Hanya DRAFT dan GAGAL_TERKIRIM memenuhi syarat. Hasil `false` berarti baris yang memenuhi syarat tidak ditemukan. Penghitungan belum terkirim mencakup empat status sebelum TERKIRIM.
- Bootstrap di `lib/main.dart` membentuk repository dan gateway setelah Auth siap, lalu mendaftarkan gateway pada composite Modul 1 di Android, iOS, dan macOS. Auth memasok ID akun untuk hitung dan pembersihan logout. Data source membatasi delete ke pemilik tersebut untuk semua status.
- Konflik nama dengan `lib/models/report.dart` dan `lib/data/report_repository.dart` diselesaikan melalui path library `lib/features/reports/`. Form dan Riwayat lama masih memakai list sementara serta ID berbasis panjang list. Integrasi UI dengan UUID dan repository SQLite dijadwalkan pada Fase 2. Model `RoadReport` juga masih digunakan layar lama.

## Testing

| Pemeriksaan | Hasil |
| --- | --- |
| dart format pada 12 file Dart terkait | Selesai |
| flutter analyze | No issues found |
| flutter test test/features/reports | 10/10 lulus |
| flutter test | 71/71 lulus, termasuk 61 test Modul 1 |

Test memakai database file sementara yang terpisah per kasus. Cakupan meliputi migration dan schema, CRUD draft parsial, UUID stabil, pergantian akun, sesi kosong, lima status, aturan edit/hapus, hitung gateway, pembersihan log lintas entitas, mapping UTC dan persistensi close/reopen. Validasi dilakukan pada Windows melalui SQLite FFI. Uji runtime pada perangkat atau emulator Android belum dilakukan.

## Remaining Work

**Fase 2** mencakup integrasi kamera, GPS, galeri, form, kompresi, tombol Simpan Draft/Kirim, edit/hapus dengan konfirmasi, dan Riwayat Saya dengan repository persisten.

**Issue 3** mencakup API, connectivity monitoring, upload, background sync, retry, WorkManager, dan notifikasi. Metadata foto dan sinkronisasi tersedia untuk retensi foto dan perhitungan kuota lintas modul pada tahap terkait.

## Blocker

Tidak ada dependency anggota lain yang menghalangi Fase 1. Modul 1 sudah menyediakan kontrak akun. Daffa dapat menambahkan tabel miliknya melalui migration berikutnya. Kontrak API dan pelaksanaan sinkronisasi menjadi pekerjaan Issue 3.
