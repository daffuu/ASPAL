# Analisis Progres Pengembangan ASPAL

**Tanggal audit:** 17 November 2026  
**Acuan:** `PRD_ASPAL.MD` versi 1.4  
**Cakupan:** Source Dart di `lib/`, konfigurasi Flutter/Android, manifest, dan hasil analisis statis. Tidak ada source code atau konfigurasi yang diubah. Tidak ada dependency yang diinstal.

## 1. Ringkasan Proyek

ASPAL saat ini berupa **prototipe Flutter dengan beberapa alur UI dan interaksi lokal sementara**, belum menjadi aplikasi offline-first yang terhubung ke akun pengguna atau server. Fitur kamera/galeri dan pembacaan GPS sudah mulai dirangkai, begitu pula formulir, tampilan status, riwayat, dan detail. Namun, laporan contoh maupun laporan baru hanya tersimpan di list statis dalam memori; tidak ada SQLite, API, autentikasi nyata, sesi aman, tindak lanjut, atau mekanisme sinkronisasi.

Belum ada FR yang memenuhi keseluruhan perilaku PRD dengan bukti implementasi yang memadai. Sebagian alur UI dapat didemonstrasikan, tetapi label “Terkirim”, antrean, riwayat, dan kegagalan bukan hasil komunikasi dengan server. **Progres FR yang DONE: 0/28 (0%).** Audit tidak menemukan folder/file pengujian Dart.

Pemeriksaan `flutter analyze --no-pub` selesai dengan **3 error** (referensi validator yang tidak didefinisikan) dan 19 info deprecation. Perintah tidak mengambil dependency. Pengujian perangkat, build APK, perilaku GPS, ukuran gambar, endpoint backend, serta kinerja jaringan tidak dijalankan/diverifikasi.

## 2. Struktur Proyek

| Area | Isi / kondisi |
|---|---|
| Flutter/Dart | `lib/main.dart`, tema, validator, route, model, widget, dan screen; versi SDK dipatok `^3.13.3` di `pubspec.yaml`. |
| Screen utama | `lib/screens/login_screen.dart`, `home_shell.dart`, `dashboard_tab.dart`, `offline_geotagging_camera.dart`, `merged_riwayat_screen.dart`, `settings_tab.dart`, `report_detail_screen.dart`. |
| Data dan model | Hanya `lib/data/report_repository.dart` dan model in-memory `lib/models/report.dart` serta `road_report.dart`. Repository menyediakan data contoh dan simulasi delay, bukan penyimpanan atau API. |
| Dependensi aplikasi | `image_picker` dan `geolocator` (serta Flutter/`cupertino_icons`) tercantum di `pubspec.yaml`; tidak ada paket SQLite, HTTP/API, secure storage, connectivity, background worker, atau notifikasi lokal. |
| Android | Ada manifest Android dan konfigurasi Gradle; izin internet, kamera, dan lokasi dideklarasikan. Nilai min SDK menggunakan default Flutter, bukan angka minimum API 26 yang dinyatakan eksplisit di konfigurasi aplikasi. |
| Platform lain | Template iOS, web, Linux, macOS, dan Windows tersedia; PRD membatasi jaminan fungsi untuk Android. |
| Dokumentasi dan tes | README masih deskripsi template Flutter. Tidak ditemukan source test Dart di repository. |

`main.dart` membuka route login, tetapi route tidak menerapkan guard autentikasi. `HomeShell` menghubungkan tab UI, namun status online dapat diubah manual. Dashboard dan riwayat membaca repository statis yang sama; formulir kamera menambahkan record ke list tersebut. Detail tidak mengakses feed/backend dan form catatan bukan alur tindak lanjut.

## 3. Matriks Functional Requirements

Status **DONE** mensyaratkan kesesuaian perilaku end-to-end terhadap PRD, bukan sekadar UI atau simulasi. Referensi file di bawah menunjukkan bukti yang ditemukan; FR yang PARTIAL tetap memiliki gap penting.

| FR | Status | Bukti dan hasil audit |
|---|---|---|
| FR-01 Registrasi | **NOT IMPLEMENTED** | Tidak ditemukan form atau panggilan registrasi. Login hanya UI; lihat `lib/screens/login_screen.dart:34-35, 110-120`. |
| FR-02 Login dan sesi offline | **PARTIAL** | Validasi email/password lalu masuk ke home, serta opsi guest; tidak ada verifikasi kredensial, penyimpanan sesi, refresh token, atau proteksi seluruh fitur. `lib/screens/login_screen.dart:27-35, 110-120`; `lib/main.dart:17`. |
| FR-03 Logout dengan konfirmasi/data lokal | **PARTIAL** | Tombol hanya mengganti route ke login; tidak memperingatkan antrean, meminta konfirmasi, atau menghapus sesi/data. `lib/screens/settings_tab.dart:82-85`. |
| FR-04 Profil dan ubah password | **PARTIAL** | Ada item profil dengan nilai statis dan handler kosong; tidak ada pengubahan nama/password. `lib/screens/settings_tab.dart:9-14, 34`. |
| FR-05 Foto kamera dan GPS otomatis | **PARTIAL** | `image_picker` dipanggil dengan sumber kamera dan GPS diambil setelah foto dipilih. Tidak ada penyimpanan permanen; GPS dapat menunggu hingga 10 detik dan belum membuktikan batas NFR 5 detik. `lib/screens/offline_geotagging_camera.dart:34-83, 99-120`. |
| FR-06 Foto dari galeri | **PARTIAL** | Sumber galeri tersedia; foto hanya menjadi state sementara sebelum form/repository memegang path lokal. `lib/screens/offline_geotagging_camera.dart:99-125`. |
| FR-07 Detail dan koordinat manual | **PARTIAL** | Form kategori, severity, deskripsi, latitude, longitude tersedia untuk foto galeri. Validasi koordinat memeriksa parse numerik, bukan rentang koordinat; data tidak dikirim ke server. `lib/screens/offline_geotagging_camera.dart:834-954`. |
| FR-08 Validasi Kirim dan draft tak lengkap | **PARTIAL** | Foto dicek sebelum form, dan `_saveDraft` selalu menjalankan validasi form. Deskripsi diwajibkan bahkan saat menyimpan draft; karena itu draf belum lengkap sesuai PRD tidak dapat disimpan. `lib/screens/offline_geotagging_camera.dart:682-683, 934-946, 960-981`. |
| FR-09 Database lokal dan antrean terikat akun | **PARTIAL** | Tombol memberi status Draft/Menunggu dan objek baru dimasukkan ke list statis; tidak ada SQLite, user_id, atau ketahanan restart. `lib/screens/offline_geotagging_camera.dart:682-722`; `lib/data/report_repository.dart:16`. |
| FR-10 Edit Draft/Gagal dan lock antrean | **PARTIAL** | Model dan detail memeriksa status editable, serta edit memperbarui list; penyimpanan hanya simulasi dalam memori. `lib/models/report.dart:14-18`; `lib/screens/merged_riwayat_screen.dart:690-704, 913-938`. |
| FR-11 Hapus Draft/Gagal dengan konfirmasi | **PARTIAL** | Status dan dialog konfirmasi diterapkan, tetapi penghapusan hanya dari list memori, bukan database perangkat. `lib/screens/merged_riwayat_screen.dart:64-123`. |
| FR-12 Background auto-sync | **NOT IMPLEMENTED** | Tidak ditemukan API, WorkManager, listener konektivitas, atau worker sinkronisasi. “Menunggu” hanya status lokal. |
| FR-13 Auto-retry maksimal 3 kali/backoff | **NOT IMPLEMENTED** | Nilai `retryCount: 3` hanya ada pada record contoh; tidak ada percobaan kirim atau backoff. `lib/data/report_repository.dart:40-49, 133-143`. |
| FR-14 Sinkronisasi manual | **PARTIAL** | Aksi “Kirim ulang” hanya mengubah status menjadi Menunggu dan retry count menjadi nol; tidak mengirim data atau mengirim seluruh antrean. `lib/screens/merged_riwayat_screen.dart:138-159, 543-548`. |
| FR-15 Penyebab gagal kirim | **PARTIAL** | Detail menampilkan `lastErrorMessage`, namun pesan hanya ada pada data contoh dan tidak berasal dari hasil server. `lib/data/report_repository.dart:40-49`; `lib/screens/merged_riwayat_screen.dart:473-480` (label status/error). |
| FR-16 Notifikasi setelah sinkronisasi antrean | **NOT IMPLEMENTED** | Tidak ditemukan implementasi notifikasi lokal atau siklus sinkronisasi. |
| FR-17 Riwayat Saya laporan dan tindak lanjut | **PARTIAL** | Riwayat status laporan tersedia dari repository contoh; tidak ada filter kepemilikan akun maupun data tindak lanjut. `lib/screens/merged_riwayat_screen.dart:23-62`; `lib/data/report_repository.dart:16-145`. |
| FR-18 Filter status Riwayat Saya | **PARTIAL** | Filter Draft/Menunggu/Gagal/Terkirim berfungsi terhadap list report statis; tidak mencakup data milik akun atau tindak lanjut. `lib/screens/merged_riwayat_screen.dart:40-62, 177-223`. |
| FR-19 Detail laporan komprehensif | **PARTIAL** | Detail menampilkan kategori, waktu, koordinat, deskripsi, dan status; foto memakai URL jaringan dan tidak ada sumber foto lokal/server yang terintegrasi ataupun tindak lanjut. `lib/screens/merged_riwayat_screen.dart:662-852`; `lib/screens/report_detail_screen.dart:193`. |
| FR-20 Koneksi dan jumlah antrean | **PARTIAL** | Header menampilkan status yang diubah dengan toggle lokal; ringkasan riwayat menghitung report statis saja, bukan koneksi aktual atau jumlah tindak lanjut antrean. `lib/screens/home_shell.dart:18-19, 27-32`; `lib/screens/merged_riwayat_screen.dart:30-38`. |
| FR-21 Timeline laporan | **PARTIAL** | Dashboard menampilkan kumpulan report repository contoh. Belum ada field lengkap feed, server, urutan server, atau pagination. `lib/screens/dashboard_tab.dart:17-24, 58-112`; `lib/data/report_repository.dart:16-145`. |
| FR-22 Refresh server dan cache offline | **NOT IMPLEMENTED** | `fetchReports` menunggu dua detik lalu mengembalikan list contoh; tidak ada refresh server/cache/waktu pembaruan. `lib/data/report_repository.dart:147-154`; `lib/screens/dashboard_tab.dart:36-55`. |
| FR-23 Detail timeline dan tindak lanjut kronologis | **NOT IMPLEMENTED** | Detail yang ditemukan adalah detail report statis; tidak ada kondisi jalan terkini ataupun daftar tindak lanjut server. `lib/screens/report_detail_screen.dart:26-105`; `lib/screens/merged_riwayat_screen.dart:662-852`. |
| FR-24 Filter timeline | **NOT IMPLEMENTED** | Tidak ditemukan filter kategori, keparahan, atau kondisi jalan di dashboard. |
| FR-25 Membuat tindak lanjut offline | **NOT IMPLEMENTED** | Form catatan menerima teks saja; tidak ada kondisi wajib, foto opsional, keterkaitan laporan terkirim, atau penyimpanan tindak lanjut. `lib/screens/catatan_form_screen.dart:13-25`; `lib/screens/report_detail_screen.dart:26-37`. |
| FR-26 Siklus sinkronisasi tindak lanjut | **NOT IMPLEMENTED** | Tidak ditemukan model/repository/antrean/sync untuk tindak lanjut. |
| FR-27 Edit/hapus tindak lanjut | **NOT IMPLEMENTED** | Tidak ditemukan entitas atau alur pengelolaan tindak lanjut. |
| FR-28 Pemeriksaan dan notifikasi tindak lanjut baru | **NOT IMPLEMENTED** | Tidak ditemukan polling, task periodik, atau notifikasi tindak lanjut. |

### Rekap FR

| DONE | PARTIAL | NOT IMPLEMENTED | BLOCKED | UNCLEAR | Total |
|---:|---:|---:|---:|---:|---:|
| 0 | 18 | 10 | 0 | 0 | 28 |

**Progres sesuai rumus yang diminta = jumlah FR DONE / seluruh FR = 0 / 28 = 0%.** PARTIAL tidak dihitung selesai. BLOCKED tidak digunakan karena repo tidak membuktikan dependensi eksternal gagal/menahan pengerjaan; API backend hanya dinyatakan sebagai asumsi PRD dan ketersediaannya belum diverifikasi.

## 4. Matriks Non-Functional Requirements

| NFR | Status | Bukti / kekurangan |
|---|---|---|
| NFR-01 GPS ≤5 detik | **PARTIAL** | `Geolocator.getCurrentPosition` menetapkan `timeLimit` 10 detik (`lib/screens/offline_geotagging_camera.dart:73-77`). Tidak ada pengukuran di perangkat/area terbuka; batas PRD belum dipenuhi secara eksplisit. |
| NFR-02 UI responsif ≤1 detik saat background sync | **NOT IMPLEMENTED** | Tidak ada sinkronisasi background yang dapat diukur; tidak ada bukti uji responsivitas. |
| NFR-03 Foto maksimal 2 MB | **PARTIAL** | `image_picker` menggunakan `imageQuality: 80` (`lib/screens/offline_geotagging_camera.dart:99-104`), tetapi tidak memeriksa atau menjamin ukuran byte ≤2 MB. |
| NFR-04 Persistensi, ID unik, idempotensi | **NOT IMPLEMENTED** | Repository adalah list dalam memori dan ID report dibuat berdasarkan jumlah list (`lib/data/report_repository.dart:16`; `lib/screens/offline_geotagging_camera.dart:698-722`). Tidak ada persistensi atau pembuktian idempotensi server. |
| NFR-05 HTTPS dan izin minimum | **PARTIAL** | Manifest mendeklarasikan internet, kamera, dan lokasi (`android/app/src/main/AndroidManifest.xml:1-5`); runtime permission lokasi diminta. Tidak ada API/HTTPS; izin POST_NOTIFICATIONS/runtime notification belum ada. |
| NFR-06 Android API 26+ | **UNCLEAR** | `minSdk` menggunakan `flutter.minSdkVersion` (`android/app/build.gradle.kts`), bukan API 26 eksplisit. Nilai efektif dan kompatibilitas belum diverifikasi lewat build/perangkat. |
| NFR-07 Timeline ≤3 detik, ≤10 item, UI tidak terblokir | **NOT IMPLEMENTED** | Dashboard memakai data contoh; repository menambahkan delay simulasi 2 detik dan tidak mengimplementasikan pagination maupun pengukuran batas waktu. `lib/data/report_repository.dart:147-154`. |
| NFR-08 Password hash server/token aman | **PARTIAL** | UI tidak menunjukkan penyimpanan password, tetapi tidak ada backend untuk membuktikan hash server atau mekanisme token aman/enkripsi. |
| NFR-09 Sesi offline 30 hari, login/registrasi ≤3 detik | **NOT IMPLEMENTED** | Tidak ada sesi, autentikasi jaringan, atau pengukuran waktu. Tombol login langsung mengarah ke home (`lib/screens/login_screen.dart:27-35`). |

## 5. Kebutuhan Teknis Pendukung (bukan FR)

| Kebutuhan PRD | Status | Temuan |
|---|---|---|
| Runtime permission kamera, lokasi, notifikasi | **PARTIAL** | Manifest berisi CAMERA/FINE/COARSE location dan geolocator meminta izin lokasi; izin notifikasi Android 13+ belum ditemukan. `android/app/src/main/AndroidManifest.xml:1-5`; `lib/screens/offline_geotagging_camera.dart:51-68`. |
| Device_ID UUID | **NOT IMPLEMENTED** | Tidak ditemukan pembuatan/penyimpanan device ID. |
| Secure storage, bearer token, refresh | **NOT IMPLEMENTED** | Tidak ada paket atau implementasi session/token/API client di dependency dan source. |
| WorkManager, konektivitas, sync/pemeriksaan berkala | **NOT IMPLEMENTED** | Tidak ditemukan paket worker/konektivitas, registrasi task, retry, maupun pemeriksaan tindak lanjut. |
| Endpoint API dan HTTPS | **NOT IMPLEMENTED** | Tidak ada klien HTTP, konfigurasi endpoint, atau endpoint backend di repository. Tautan Unsplash hanyalah URL gambar contoh, bukan API ASPAL. |
| SQLite, akun, cache feed, log percobaan, batas kapasitas | **NOT IMPLEMENTED** | Tidak ditemukan database lokal, tabel sesuai PRD, mekanisme retensi/cache, atau log sinkronisasi. |

## 6. Temuan dan Bug

Prioritas: **P1** menghalangi validasi/keamanan atau alur inti; **P2** fitur utama belum berperilaku sesuai harapan; **P3** mutu/pelengkap.

| Prioritas | Lokasi | Temuan dan dampak |
|---|---|---|
| **P1** | `lib/screens/login_screen.dart:27-35, 110-120`; `lib/main.dart:17`; `lib/routes/app_routes.dart` | Tombol masuk tidak memanggil layanan autentikasi dan langsung membuka home; ada opsi guest yang membuka seluruh tab. Semua fitur dapat dilewati tanpa akun, bertentangan dengan kewajiban login dan kepemilikan akun. |
| **P1** | `lib/data/report_repository.dart:16-154`; `lib/screens/offline_geotagging_camera.dart:682-722` | Data inti adalah contoh/list memori; penyimpanan laporan baru hilang ketika proses aplikasi berakhir. Klaim simpan antrean dan sukses tidak merepresentasikan persistensi. |
| **P1** | `lib/widgets/login_form_dialog.dart:44, 51`; `lib/screens/note_form_screen.dart:67`; `lib/utils/validators.dart` | `flutter analyze --no-pub` gagal dengan error `validateEmail`, `validatePassword`, dan `validateNote` tidak terdefinisi. Validator yang tersedia berada di class `Validators`; file yang memanggil simbol tersebut tidak memakai validator yang ada. Hasil ini adalah kegagalan analisis statis; build aplikasi tidak dijalankan. |
| **P1** | `lib/screens/offline_geotagging_camera.dart:682-722`; `lib/screens/merged_riwayat_screen.dart:138-159` | Tombol Kirim mengubah state lokal saja, dan retry manual hanya mengubah status. Tidak ada pengiriman; item dapat tetap “Menunggu Sinyal” tanpa batas dan label UI berpotensi menyesatkan. |
| **P2** | `lib/screens/offline_geotagging_camera.dart:682-683, 934-946, 960-981` | Validasi yang sama dipakai untuk draft dan antrean; deskripsi wajib, sehingga draf belum lengkap tidak dapat disimpan. |
| **P2** | `lib/screens/offline_geotagging_camera.dart:73-77, 99-104` | Timeout GPS 10 detik melampaui target 5 detik; kualitas gambar 80 tidak memastikan ukuran maksimal 2 MB. |
| **P2** | `lib/screens/home_shell.dart:18-19, 27-32`; `lib/screens/merged_riwayat_screen.dart:30-38`; `lib/screens/dashboard_tab.dart:114-131` | Status online diubah dengan toggle manual; angka dasbor sebagian hard-coded dan statistik riwayat hanya mencakup list contoh. Tampilan tidak menunjukkan keadaan perangkat/antrean yang sebenarnya. |
| **P2** | `lib/screens/report_detail_screen.dart:26-37, 447-512`; `lib/screens/catatan_form_screen.dart:13-25` | “Catatan Tambahan” hanya disimpan di state screen dan tombol aksi detail tidak berfungsi (`onPressed: () {}`). Catatan bukan tindak lanjut sesuai PRD dan hilang saat screen ditutup. |
| **P3** | `lib/screens/login_screen.dart`, `lib/screens/report_history.dart`, `lib/screens/report_form_tab.dart`, `lib/screens/merged_riwayat_screen.dart`, `lib/screens/report_detail_screen.dart`, `lib/widgets/app_header.dart` | Analisis statis juga melaporkan 19 info penggunaan `withOpacity` deprecated. Bukan penghalang langsung, tetapi menghasilkan noise dan perlu dibereskan setelah masalah P1. |
| **P3** | `README.md` | Masih README starter Flutter, tidak menggambarkan fungsi atau cara menjalankan ASPAL saat ini. |

## 7. Rekomendasi Pekerjaan Berikutnya

Urutan berikut menjaga dependensi antarfitur; jangan memperluas mock UI sebelum fondasi penyimpanan/sesi terbukti:

1. **Pulihkan baseline kualitas dan rapikan batas modul (P1).** Perbaiki tiga validator yang tidak terdefinisi, jalankan kembali `flutter analyze`, lalu pastikan screen legacy yang tidak terhubung memang diintegrasikan atau dibersihkan melalui perubahan terpisah yang disetujui. Tambahkan test dasar pada alur yang mulai diimplementasikan.
2. **Tetapkan kontrak backend dan implementasikan autentikasi (P1; bergantung ketersediaan API eksternal).** Verifikasi endpoint/kontrak dengan pemilik backend, implementasikan registrasi, login, refresh/logout, profil, token aman, dan guard route. Hilangkan jalur guest serta data profil statis. Jangan tandai BLOCKED sebelum ketidaktersediaan backend terkonfirmasi.
3. **Bangun lapisan data lokal yang persisten dan terisolasi per akun (P1).** Implementasikan SQLite untuk laporan/draft, ID UUID, validasi draft yang sesuai PRD, update/delete terbatas status, batas kapasitas, serta tes bahwa data bertahan setelah aplikasi ditutup. Pisahkan repository dari data contoh.
4. **Lengkapi pipeline media dan sinkronisasi laporan (P1).** Terapkan ukuran foto ≤2 MB, record percobaan/error, cek keterjangkauan server, upload HTTPS/idempotent, koneksi foreground dan worker background, retry maksimum tiga kali dengan backoff, retry manual, pause saat sesi kedaluwarsa, dan notifikasi antrean. Uji foreground/background serta kehilangan koneksi.
5. **Implementasikan feed, riwayat, dan tindak lanjut end-to-end (P2).** Integrasikan pagination/filter/cache feed dan detail; kemudian tindak lanjut offline berikut siklus antrean yang sama, tampilan riwayat, serta pemeriksaan/notifikasi update. Ukur NFR pada perangkat Android API 26+ dan uji seluruh success criteria PRD.

## 8. Batas Audit

- Status “belum ditemukan” berarti tidak ada bukti implementasi pada source/config yang diperiksa, bukan klaim bahwa sistem backend eksternal tidak ada.
- Tidak ada pengujian perangkat Android, uji jaringan, pengukuran performa/ukuran file, atau verifikasi endpoint. Angka dan kinerja tersebut karena itu tidak diasumsikan lulus.
- `PRD_ASPAL.MD` ada di root tetapi pada saat audit tercatat sebagai file **untracked** di Git (`git status --short`); laporan ini tidak mengubah status atau isi PRD.
- Tidak ada source, konfigurasi, dependency, maupun file lain yang diubah selain pembuatan laporan ini.
