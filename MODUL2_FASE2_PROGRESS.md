# ASPAL — Issue 2 Fase 2

## Status

**DONE — implementation complete**, 24 November 2026. Tab **Lapor** menyimpan laporan di `aspal.db` versi 1. Untuk melanjutkan draft setelah membuka ulang aplikasi, pilih **Lapor → Buka laporan untuk diedit**. Tab Riwayat masih menampilkan data contoh.

**Manual verification on Android pending.** Pemeriksaan `adb devices -l` menghasilkan daftar kosong. SDK lokal juga tidak menyediakan emulator atau AVD.

## Functional Requirements

| Requirement | Implementasi dan bukti otomatis | Verifikasi manual Android |
| --- | --- | --- |
| FR-05 | Pemilihan kamera diikuti pengambilan posisi dan akurasi. Test memakai picker/lokasi terinjeksi untuk keberhasilan dan penolakan GPS. | Pending |
| FR-06 | Galeri membuka preview dan memakai koordinat manual. Test memastikan galeri dan pembatalan picker tidak memanggil GPS. | Pending |
| FR-07 | Form memakai pilihan kategori dan severity yang tersedia, deskripsi dan koordinat. Test meliputi batas inklusif, teks kosong, nonnumerik dan angka non-finite. | Pending |
| FR-08 | Form dapat dibuka tanpa foto dan draft dapat disimpan kosong. Test tombol Simpan Draft membaca hasil dari SQLite. | Pending |
| FR-09 integrasi | UUID klien dan pemilik berasal dari repository Fase 1. Test memeriksa UUID, waktu, pemilik, ukuran file dan hasil close/reopen. | Pending |
| FR-10 | Tab Lapor membuka draft dan laporan gagal milik akun aktif untuk diedit. Uji repository meliputi isolasi pemilik dan semua status terkunci. | Pending |
| FR-11 | Dialog hapus membedakan Batal dan Hapus. Test terpisah memeriksa penghapusan record dan foto lokal serta perlindungan foto asal. | Pending |
| NFR-03 | Uji BMP lebih dari 2 MB melewati codec Flutter. Test mengukur file hasil dan memeriksa penolakan byte yang melampaui batas. | Pending |

## Architecture

Tab Lapor memakai `ReportFormService` untuk parsing koordinat dan pengelolaan file, lalu memanggil `ReportRepository`. Repository mengambil akun dari `TokenProvider.getUserId()`. Data source menulis ke tabel `reports` melalui `AppDatabase`. Bootstrap dan layar menggunakan instance ReportsModule yang sama. Gateway logout tetap menghitung antrean dan pembersihan akun kini juga membuang salinan foto laporan yang dikelola aplikasi.

## Camera Flow

ImagePicker membuka kamera. Setelah picker mengembalikan foto, Geolocator memeriksa layanan lokasi dan izin, meminta izin bila diperlukan, lalu mengambil posisi dengan batas waktu 10 detik. Form mengunci koordinat kamera dan menyimpan `gps_source = camera` beserta `gps_accuracy` jika tersedia. Kegagalan lokasi menampilkan pesan dan mempertahankan foto untuk draft. Foto kamera baru menggantikan koordinat lama meskipun percobaan GPS baru gagal.

## Gallery Flow

Pemilihan galeri membersihkan koordinat sebelumnya, menampilkan preview, dan mengaktifkan input latitude/longitude pada detail. Sumber disimpan sebagai `manual`. Pembatalan picker mempertahankan pilihan sebelumnya.

## Draft Flow

**Selanjutnya → Simpan Draft** dapat dilakukan sebelum memilih foto, kategori, severity, atau mengisi deskripsi maupun lokasi. Koordinat boleh kosong atau baru terisi satu. Angka yang sudah diisi diperiksa agar latitude berada dalam ±90 dan longitude dalam ±180. Edit menggunakan UUID dan waktu pembuatan asli serta memperbarui `updated_at`.

## Send Flow

**Kirim** memerlukan foto yang dapat dibaca dengan ukuran sesuai, kategori, serta sepasang koordinat valid. Sesuai FR-08, deskripsi dan severity bersifat opsional saat Kirim. Untuk laporan baru, repository langsung menyisipkan satu record berstatus `MENUNGGU_SINYAL`. Untuk draft lama, penyimpanan isi dan perubahan status terjadi dalam transaksi yang mensyaratkan UUID, akun aktif dan status DRAFT. Laporan menetap dalam antrean lokal sampai Issue 3 menyediakan sinkronisasi.

## Media Processing

1. Picker meminta dimensi maksimal 2400 × 2400 dan kualitas 88. Aplikasi membaca byte hasil dan memeriksa apakah codec dapat mendekodenya.
2. Untuk input di atas 2.097.152 byte, codec Flutter mengubah ukuran dengan mempertahankan rasio, dimulai dengan sisi terpanjang maksimal 1600, lalu mengenkode PNG. Bila masih terlalu besar, sisi target dibagi dua dan hasil diperiksa kembali.
3. Saat Simpan atau Kirim, aplikasi menulis salinan unik ke direktori application support di `report_photos/<uuid>.photo`. File asli dari picker hanya dibaca. Panjang file diukur kembali untuk `photo_size_bytes`; byte preview dan path temporer picker tidak menjadi sumber persistensi.
4. Jika penyimpanan metadata gagal, salinan baru dibersihkan. Saat mengganti atau menghapus foto, data source menyelesaikan transaksi sebelum membuang foto lama. Penghapusan dibatasi pada file terkelola dalam direktori foto. Kegagalan I/O saat pembersihan atau penghentian proses di antara operasi file dan SQLite dapat meninggalkan salinan yatim.

Manifest Android sudah memiliki CAMERA, ACCESS_FINE_LOCATION, dan ACCESS_COARSE_LOCATION. Konfigurasi permission lama tetap mencukupi untuk alur picker.

## Edit/Delete Rules

| Status | Edit | Hapus | Kirim dari form |
| --- | --- | --- | --- |
| DRAFT | Ya | Dengan konfirmasi | Jika valid |
| GAGAL_TERKIRIM | Ya, status dipertahankan | Dengan konfirmasi | Retry manual dijadwalkan pada Issue 3 |
| MENUNGGU_SINYAL, MENGIRIM, TERKIRIM | Dikunci | Dikunci | Dikunci |

Form legacy mengharuskan foto sebelum membuka detail dan menyisipkan ID dari panjang list. Form produksi mengikuti FR-08 dan UUID Fase 1. Layar edit contoh pada Riwayat dapat mengubah laporan gagal menjadi draft. Pada laporan SQLite, edit mengikuti kontrak Fase 1 yang mempertahankan status gagal.

## Files Changed

| Perubahan | File |
| --- | --- |
| Baru, komposisi modul | `lib/app_modules.dart` |
| Baru, pemilihan foto/GPS dan storage | `lib/features/reports/data/report_capture.dart`, `lib/features/reports/data/report_photos.dart` |
| Baru, validasi dan penyimpanan form | `lib/features/reports/domain/models/report_validation.dart`, `lib/features/reports/report_form_service.dart` |
| Baru, pengujian dan laporan | `test/features/reports/report_form_test.dart`, `MODUL2_FASE2_PROGRESS.md` |
| Diubah, entry point dan UI | `lib/main.dart`, `lib/screens/offline_geotagging_camera.dart` |
| Diubah, kontrak dan akses data | `lib/features/reports/domain/repositories/report_repository.dart`, `lib/features/reports/data/report_repository_impl.dart`, `lib/features/reports/data/report_local_data_source.dart` |
| Diubah, dependency | `pubspec.yaml`, `pubspec.lock` |

Daftar ini mencakup perubahan Fase 2 pada working tree yang sudah berisi pekerjaan Modul 1 dan Fase 1.

## Dependencies

`path_provider ^2.1.6` menjadi dependency langsung untuk memperoleh direktori privat aplikasi. `image_picker` dan `geolocator` sudah tersedia. Resizing dan encoding memakai codec bawaan Flutter.

## Testing

| Pemeriksaan | Hasil |
| --- | --- |
| dart format pada 11 file Dart Fase 2 | Selesai |
| flutter analyze | No issues found |
| flutter test test/features/reports/report_form_test.dart | 11/11 lulus |
| flutter test | 82/82 lulus, terdiri dari 61 test Auth, 10 Fase 1 dan 11 Fase 2 |

Pengujian otomatis berjalan pada Windows dengan SQLite FFI berbasis file dan filesystem sementara. Test widget form menjalankan callback tombol Simpan Draft pada repository SQLite nyata. Test media memakai codec Flutter nyata dan input kamera/GPS terkontrol.

### Verifikasi Android dan inspeksi database yang masih pending

1. Pada build debug, login dan buka Lapor. Ambil foto kamera, izinkan GPS, isi laporan dan pilih Simpan Draft.
2. Tutup aplikasi, buka lagi dengan akun yang sama, lalu buka laporan melalui **Buka laporan untuk diedit**. Cocokkan UUID, foto dan lokasi.
3. Buat laporan lain dari galeri, ketik koordinat manual, pilih kategori dan tekan Kirim.
4. Di Android Studio, buka **App Inspection → Database Inspector**, pilih proses `com.example.aspal` dan database `aspal.db`. Jalankan query berikut dan ulangi setelah restart.

```sql
SELECT report_id, user_id, category, severity, latitude, longitude, gps_accuracy,
       gps_source, photo_local_path, photo_size_bytes, sync_status, created_at, updated_at
FROM reports
ORDER BY created_at DESC;
```

Draft kamera seharusnya memuat sumber `camera`, akurasi GPS jika diperoleh dan status DRAFT. Baris galeri seharusnya memuat `manual`, koordinat yang diketik dan status MENUNGGU_SINYAL. Periksa ukuran foto dalam rentang 1–2.097.152 byte. Salinan database dapat diekspor dari Database Inspector untuk dibaca menggunakan DB Browser for SQLite.

## Pekerjaan berikutnya

Fase 3 mencakup migrasi Riwayat Saya, filter, dan detail. Issue 3 mencakup API, unggah, konektivitas, retry, WorkManager dan notifikasi. Verifikasi kamera, galeri, dialog izin, dan persistensi pada perangkat Android masih menunggu perangkat.
