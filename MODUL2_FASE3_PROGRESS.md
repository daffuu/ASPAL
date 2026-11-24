# ASPAL — Issue 2 Fase 3

## Status

**DONE — Issue 2 implementation complete.** Tab Riwayat menampilkan laporan akun aktif dari SQLite. Detail memuat ulang laporan berdasarkan UUID, menyediakan pengelolaan melalui form Fase 2, dan menampilkan lokasi tersimpan pada peta OpenStreetMap.

## Audit dan kelanjutan pekerjaan

Audit working tree menemukan layar Riwayat dan Detail, integrasi tab, pemetaan status, fallback foto, pengurutan waktu, serta enam test Fase 3. Dependensi peta dan laporan progress ini belum tersedia. Analyzer baseline bersih. Empat dari enam test awal lulus. Dua kegagalan terjadi saat test menunggu rangkaian navigasi dan operasi SQLite native setelah edit, serta saat meneruskan error dari zona I/O ke widget test.

Kelanjutan pekerjaan memperbaiki penantian I/O dan frame di test yang sama, menambahkan peta bersama untuk Detail dan Form, serta memperluas pengujian koordinat dan kondisi offline.

## Functional Requirements

| FR | Hasil |
| --- | --- |
| FR-17 Riwayat Saya | Laporan milik akun aktif, urutan terbaru dahulu, foto atau thumbnail, kategori, severity, waktu lokal, dan indikator status. |
| FR-18 Filter | Semua, Draft, Menunggu Sinyal, Mengirim, Gagal Terkirim, dan Terkirim. Filter terpilih dipertahankan saat kembali dari detail atau mengaktifkan tab lagi. |
| FR-19 Detail | Pembacaan ulang berdasarkan UUID dan akun aktif, metadata laporan, foto dengan fallback, penyebab gagal jika tersedia, serta marker dan koordinat tekstual. |

## Architecture, History dan Filter

Auth menyediakan pemilik melalui `TokenProvider.getUserId()`. Riwayat memanggil `getReportsByUser()` untuk Semua dan `getReportsByStatus()` untuk satu status. Keduanya menerapkan kepemilikan di query SQLite. Daftar memuat saat tab diaktifkan, filter berubah, atau pengguna kembali dari detail. Loading, daftar kosong, hasil filter kosong, dan kegagalan baca memiliki tampilan tersendiri. Tombol **Coba Lagi** mengulang query dengan filter aktif.

## Detail dan integrasi Form

Riwayat membawa `report_id` ke Detail. Repository menjalankan pencarian menggunakan pasangan UUID dan pemilik. Laporan yang hilang atau milik akun lain menghasilkan pesan bahwa laporan tidak tersedia. Detail menampilkan waktu pembuatan dan pembaruan, kategori, severity, deskripsi, koordinat, sumber dan akurasi GPS jika tersedia, serta status. Draft parsial memiliki placeholder. Foto memakai urutan file lokal, thumbnail lokal, lalu placeholder jika keduanya gagal. URL foto server belum diunduh.

**Edit atau hapus laporan** membuka pengelolaan Fase 2 untuk Draft dan Gagal Terkirim. Alur ini memakai konfirmasi hapus, pemeriksaan pemilik/status, dan pengelolaan file yang sama dengan tab Lapor. Setelah edit, Detail membaca ulang UUID yang sama. Hapus mengembalikan pengguna ke Riwayat. **Lapor → Buka laporan untuk diedit** juga tetap tersedia. Rute Dasbor dan model legacy masih digunakan untuk konten contoh Dasbor.

## OpenStreetMap

Detail mengubah pasangan latitude/longitude dari `Report.content` menjadi `LatLng` dan menggunakannya untuk pusat `FlutterMap` serta satu marker dalam `MarkerLayer`. TileLayer membaca tile OpenStreetMap dengan identitas aplikasi Android dan atribusi kontributor pada peta. Peta bersifat pratinjau lokasi laporan. Pembukaan Detail tidak meminta lokasi perangkat.

Di Form, **Pratinjau lokasi** memakai GPS hasil kamera atau koordinat manual galeri yang sedang diisi. Marker hanya dibuat untuk angka finite dalam rentang latitude ±90 dan longitude ±180. Posisi kosong atau tidak valid menghasilkan **Lokasi belum ditentukan**. Kedua layar tetap menyediakan koordinat tekstual.

Dependency langsung baru adalah `flutter_map 7.0.0` dan `latlong2 0.9.1`. Geolocator sudah tersedia dari Fase 2.

## Database

**Database tetap version 1.** Fase 3 memakai tabel dan indeks pemilik/status dari Fase 1. Query mengurutkan timestamp UTC sebagai teks dengan mengabaikan akhiran Z agar pecahan tiga dan enam digit pada milidetik yang sama tetap berurutan. UUID menjadi pembeda jika waktu sama. Format penyimpanan timestamp dan kontrak repository tetap berlaku.

## Files Changed

| File Fase 3 | Peran |
| --- | --- |
| `lib/screens/home_shell.dart` | Mengaktifkan tab Riwayat berbasis repository dan memperbarui daftar saat tab kembali aktif. |
| `lib/screens/my_report_history.dart` | Daftar pribadi, status, filter dan navigasi ke detail. |
| `lib/screens/my_report_detail.dart` | Pembacaan detail, field nullable, peta, dan akses edit/hapus. |
| `lib/screens/offline_geotagging_camera.dart` | Memakai form Fase 2 untuk laporan terpilih dan menyediakan preview peta. |
| `lib/features/reports/data/report_local_data_source.dart` | Pengurutan timestamp sampai mikrodetik. |
| `lib/features/reports/presentation/report_presentation.dart` | Label dan ikon status, format waktu, fallback foto. |
| `lib/features/reports/presentation/report_location_map.dart` | Komponen peta bersama yang ditambahkan saat pekerjaan dilanjutkan. |
| `pubspec.yaml`, `pubspec.lock` | Dependency peta dan versi hasil resolusi. |
| `test/features/reports/report_history_test.dart` | Test widget dengan repository SQLite berbasis file, pengujian peta dan alur kembali dari form. |
| `MODUL2_FASE3_PROGRESS.md` | Hasil audit, implementasi, dan verifikasi. |

## Tests dan regression

| Pemeriksaan | Hasil |
| --- | --- |
| Flutter analyze | No issues found |
| Modul 1 Auth | 61/61 lulus |
| Fase 1 database/repository/gateway | 10/10 lulus |
| Fase 2 form dan media | 11/11 lulus |
| Fase 3 Riwayat, Detail, peta dan integrasi | 7/7 lulus, terdiri dari 6 test awal dan 1 test marker baru |
| Flutter test, seluruh proyek | 89/89 lulus |

Pengujian meliputi dua akun, lima filter status dan Semua, urutan mikrodetik, error dan retry pembacaan, foto hilang, dan draft parsial. Alur integrasi menyimpan draft melalui layanan Form, menutup database, membuka Riwayat serta Detail, lalu mengedit dan menghapus melalui UI. Test memeriksa UUID, waktu pembuatan, perubahan isi, serta filter yang tetap aktif. Pengujian marker memakai tile dalam memori. Respons gagal dari HTTP tiruan widget test memverifikasi fallback peta dan memeriksa kembali koordinat serta status di SQLite.

## Known Limitations

**Manual verification on Android pending.** Daftar `adb devices -l` kosong dan emulator/AVD lokal tidak tersedia saat audit. Kamera, GPS, filesystem, serta tampilan tile langsung pada perangkat masih menunggu verifikasi Android. Peta dasar memerlukan tile yang dapat dimuat. Saat tile gagal, pengguna melihat **Peta dasar tidak tersedia** dan tetap dapat menggunakan data laporan lokal.

## Remaining Work

Issue 3 mencakup konektivitas, API, upload foto, pemrosesan latar belakang, retry/backoff, ID laporan dari server, notifikasi, dan penyelesaian sinkronisasi. Kirim di Issue 2 berhenti pada MENUNGGU_SINYAL. Riwayat tindak lanjut menunggu integrasi modul pemiliknya.
