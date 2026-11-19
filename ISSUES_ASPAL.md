# GitHub Issues — ASPAL

Repository: https://github.com/daffuu/ASPAL  
Branch acuan: `feat/integrasi-modul`  
Acuan kebutuhan: PRD ASPAL v1.4 dan `ANALISIS_PROGRESS.md`

> Buat empat GitHub Issues terpisah dengan menyalin setiap judul dan body di bawah. Nama penanggung jawab tercantum dalam body. Assignee GitHub belum dipasang karena username akun GitHub tiap anggota belum dikonfirmasi.

---

# Issue 1

**Judul:** `[MODUL 1] Implementasi Autentikasi dan Manajemen Akun (FR-01–FR-04)`  
**Penanggung jawab:** Zaki Alfurqani

## Tujuan
Mengubah UI akun yang masih berupa simulasi menjadi autentikasi nyata. Seluruh fitur ASPAL wajib membutuhkan akun yang sudah login, sedangkan sesi yang masih berlaku dapat digunakan ketika perangkat offline.

## Subtask
- [ ] **FR-01 Registrasi:** form nama, email, password; validasi; hubungkan ke endpoint registrasi; tangani email duplikat dan respons gagal.
- [ ] **FR-02 Login dan sesi:** hubungkan login ke API; simpan access token, refresh token, masa berlaku token, dan identitas akun menggunakan secure storage; pulihkan sesi saat aplikasi dibuka ulang.
- [ ] **FR-02 Akses offline:** pengguna yang pernah login dan memiliki sesi valid dapat membuka aplikasi offline. Jika sesi tidak dapat diperbarui, minta login ulang tanpa menghapus draft lokal.
- [ ] **FR-02 Proteksi aplikasi:** hilangkan jalur Guest dan pasang auth guard pada seluruh route/fitur.
- [ ] **FR-03 Logout:** periksa antrean laporan/tindak lanjut; tampilkan peringatan; saat dikonfirmasi, koordinasikan pembersihan data akun dengan pemilik database dan hapus sesi/token.
- [ ] **FR-04 Profil:** tampilkan profil aktual, ubah nama tampil, dan ubah password melalui API.
- [ ] Tambahkan state loading, validasi, pesan error, dan test alur akun.

## Kriteria selesai (Definition of Done)
- [ ] Registrasi membuat akun di server dan email duplikat ditolak dengan pesan yang jelas.
- [ ] Login hanya berhasil dengan kredensial valid; Guest dan route tanpa autentikasi tidak dapat membuka fitur aplikasi.
- [ ] Sesi tetap aktif setelah aplikasi ditutup/dibuka ulang, termasuk saat offline selama sesi valid.
- [ ] Token disimpan di secure storage, bukan password; refresh token ditangani sesuai kontrak backend.
- [ ] Sesi kedaluwarsa menjeda sinkronisasi dan meminta login ulang tanpa menghapus draft/antrean.
- [ ] Logout mengikuti aturan peringatan dan konfirmasi PRD.
- [ ] Profil dan perubahan password terhubung ke backend.
- [ ] Test validasi, auth guard, pemulihan sesi, dan kondisi error tersedia; `flutter analyze` untuk file yang dikerjakan tidak memiliki error.

## Dependency dan integrasi
- **Backend:** membutuhkan base URL dan kontrak endpoint register, login, refresh, logout, profil, serta ubah password. Bila backend belum tersedia, gunakan mock berlabel jelas; jangan klaim integrasi server selesai.
- **Ikhsan:** sepakati interface API client dan token provider agar seluruh modul memakai client/token yang sama.
- **Hasyfi dan Daffa:** sepakati cara membaca `user_id`, menghitung antrean belum terkirim, dan membersihkan data lokal akun saat logout. Zaki tidak mengubah skema tabel laporan/tindak lanjut.
- **Batas kode:** Zaki memiliki modul auth/session, layar login, profil/pengaturan akun, session provider, dan auth guard. Perubahan route global dikoordinasikan melalui PR.

## Siap diintegrasikan ketika
Alur register-login-pemulihan sesi-logout-profil dapat didemonstrasikan dengan backend atau mock terkontrol, dan anggota lain memperoleh `user_id` serta token melalui interface terdokumentasi.

**PRD:** FR-01–FR-04, NFR-08, NFR-09, secure storage, token refresh.

---

# Issue 2

**Judul:** `[MODUL 2] Pelaporan Offline, SQLite Reports, dan Riwayat Saya (FR-05–FR-11, FR-17–FR-19)`  
**Penanggung jawab:** Hasyfi Zharfan Caniago

## Tujuan
Mengubah pelaporan yang saat ini memakai list statis dalam memori menjadi pelaporan offline yang tersimpan permanen di perangkat, terikat pada akun pengguna, dan dapat dikelola melalui Riwayat Saya.

## Subtask
- [ ] **FR-05 Kamera dan GPS:** ambil foto melalui kamera dan kunci koordinat GPS saat foto diambil.
- [ ] **FR-06 Galeri:** dukung pemilihan foto dari galeri.
- [ ] **FR-07 Form:** kategori, tingkat keparahan, deskripsi, koordinat manual untuk foto galeri, validasi rentang latitude/longitude, dan sumber GPS.
- [ ] **NFR-03 Media:** kompres foto dan pastikan ukuran maksimal 2 MB; `imageQuality` saja tidak cukup sebagai jaminan ukuran.
- [ ] **FR-08 Draft:** draft yang belum lengkap tetap dapat disimpan. Validasi foto, koordinat, dan kategori diterapkan saat pengguna memilih Kirim.
- [ ] **FR-09 SQLite:** persistensi lokal laporan dengan UUID, `user_id`, metadata foto, status, waktu, dan field sinkronisasi; data bertahan setelah aplikasi ditutup/dibuka ulang.
- [ ] **FR-10 Edit:** edit hanya Draft dan Gagal Terkirim; kunci Menunggu Sinyal/Mengirim.
- [ ] **FR-11 Hapus:** hapus Draft dan Gagal Terkirim dengan konfirmasi; larang hapus item yang sedang antre/dikirim.
- [ ] **FR-17 Riwayat Saya:** tampilkan laporan milik akun login; siapkan integrasi daftar tindak lanjut dari Daffa.
- [ ] **FR-18 Filter riwayat:** filter berdasarkan status sinkronisasi.
- [ ] **FR-19 Detail laporan:** tampilkan foto lokal atau thumbnail/foto server, koordinat, kategori, deskripsi, waktu, dan status; koordinasikan komponen detail bersama Daffa.

## Kriteria selesai (Definition of Done)
- [ ] Foto kamera/galeri dapat dipilih; GPS otomatis dan input koordinat manual tersimpan benar.
- [ ] Foto draft maksimal 2 MB.
- [ ] Draft belum lengkap dapat disimpan; validasi wajib diterapkan saat Kirim.
- [ ] Laporan tersimpan di SQLite dan tetap tersedia setelah aplikasi ditutup paksa/dibuka ulang.
- [ ] Data laporan terisolasi berdasarkan `user_id` akun aktif.
- [ ] UUID laporan stabil dan tidak berubah ketika diedit atau dikirim ulang.
- [ ] Aturan edit/hapus mengikuti status dalam PRD.
- [ ] Riwayat dan filter menggunakan data SQLite, bukan data dummy.
- [ ] Detail menampilkan field yang diwajibkan PRD.
- [ ] Test validasi draft/kirim, persistensi, isolasi akun, edit/hapus, dan pengelolaan foto tersedia.

## Dependency dan integrasi
- **Zaki:** menyediakan interface current user/`user_id` dan lifecycle logout. Zaki menghapus session; Hasyfi menangani penghapusan data laporan akun setelah logout dikonfirmasi.
- **Ikhsan:** sepakati kontrak repository untuk query antrean, update status, menyimpan hasil/error/retry, dan menandai laporan terkirim.
- **Daffa:** Hasyfi memiliki fondasi SQLite, migration registry, dan tabel `reports`. Daffa menambahkan tabel `followups` serta `feed_posts` melalui migration terpisah. Riwayat Saya perlu kontrak untuk menampilkan tindak lanjut tanpa mengubah repository laporan milik Hasyfi.
- **Batas kode:** Hasyfi memiliki model/repository laporan, migration `reports`, alur kamera/form, dan layar Riwayat Saya. Detail publik/tindak lanjut timeline dimiliki Daffa.

## Siap diintegrasikan ketika
Laporan dapat dibuat offline, tersimpan permanen di SQLite, diedit/dihapus sesuai status, dan tampil di Riwayat Saya berdasarkan akun aktif. Kontrak antrean dapat dipakai Ikhsan tanpa mengakses UI.

**PRD:** FR-05–FR-11, FR-17–FR-19, NFR-01, NFR-03, persistensi NFR-04, aturan kepemilikan/batas penyimpanan/retensi foto/idempotensi.

---

# Issue 3

**Judul:** `[MODUL 3] API Client, Konektivitas, dan Background Sync (FR-12–FR-16, FR-20)`  
**Penanggung jawab:** M. Ikhsan Pratama

## Tujuan
Membangun infrastruktur komunikasi server dan sinkronisasi bersama untuk modul laporan (Hasyfi) dan tindak lanjut (Daffa). Sinkronisasi tidak boleh memblokir UI, harus menampilkan status yang jujur, dan tidak boleh membuat data duplikat.

## Subtask
- [ ] Buat API client bersama: HTTPS, base URL, timeout, parsing respons, HTTP error, dan pemasangan token melalui interface dari Zaki.
- [ ] Buat connectivity listener dan pemeriksaan keterjangkauan server; Wi-Fi tersambung tidak otomatis berarti server dapat dijangkau.
- [ ] **FR-12 Background auto-sync:** proses item Menunggu Sinyal ketika jaringan dan server tersedia, melalui pemicu foreground dan WorkManager di background.
- [ ] **FR-13 Retry:** catat percobaan; maksimal 3 retry dengan backoff; setelah batas gagal, ubah status menjadi Gagal Terkirim.
- [ ] **FR-14 Manual sync:** sediakan sinkronisasi satu item dan seluruh antrean.
- [ ] **FR-15 Error status:** petakan NO_NETWORK, SERVER_ERROR, AUTH_EXPIRED, timeout, dan data ditolak server; simpan pesan untuk UI.
- [ ] **FR-16 Notifikasi:** notifikasi lokal saat seluruh antrean laporan selesai disinkronkan.
- [ ] **FR-20 Indikator:** sediakan status koneksi aktual dan jumlah laporan/tindak lanjut yang menunggu.
- [ ] Sediakan idempotensi berbasis `user_id` dan UUID item agar retry tidak menggandakan data.
- [ ] Sediakan interface agar Daffa dapat mendaftarkan sync followup dan pemeriksaan pembaruan tanpa membuat worker duplikat.

## Kriteria selesai (Definition of Done)
- [ ] API client dipakai bersama oleh Auth, Reports, Timeline, dan Followups.
- [ ] Sync hanya berjalan ketika koneksi tersedia, server terjangkau, dan sesi valid.
- [ ] Pemicu foreground merespons saat koneksi pulih; WorkManager memakai constraint jaringan dan berjalan best-effort.
- [ ] Retry maksimal 3 kali dengan backoff dan transisi status sesuai PRD.
- [ ] Manual retry satu item dan seluruh antrean tersedia melalui interface.
- [ ] Kegagalan menyimpan kode/pesan penyebab yang dapat dilihat pengguna.
- [ ] Notifikasi lokal hanya diberikan setelah antrean benar-benar selesai.
- [ ] Indikator koneksi aktual dan jumlah antrean berasal dari data reports + followups, bukan angka hard-coded.
- [ ] Retry dengan UUID sama tidak membuat duplikasi di server (dibuktikan melalui kontrak/uji backend).
- [ ] Sync berjalan terpisah dari UI thread; test retry, error mapping, transisi status, dan idempotensi tersedia.
- [ ] `flutter analyze` untuk file yang dikerjakan tidak memiliki error.

## Dependency dan integrasi
- **Zaki:** menyediakan token/access-session, refresh token, dan status sesi. Sesi berakhir harus menjeda sync tanpa menghapus antrean.
- **Hasyfi:** menyediakan repository/kontrak laporan untuk query antrean, update status, menyimpan error/retry, dan menandai terkirim.
- **Daffa:** menyediakan kontrak repository tindak lanjut. Ikhsan menyediakan worker/engine generik agar followup menggunakan retry dan sync yang sama.
- **Backend:** membutuhkan endpoint upload laporan/tindak lanjut, respons sukses/gagal, dan dukungan idempotensi. Jika backend belum tersedia, gunakan adapter/mock dan tandai integrasi server belum terverifikasi.
- **Batas kode:** Ikhsan memiliki API client, connectivity, sync engine/worker, retry policy, sync log, dan notification service. Model/repository domain tetap dimiliki Hasyfi dan Daffa.

## Siap diintegrasikan ketika
API client, connectivity service, dan sync engine memiliki interface terdokumentasi; item uji dapat diproses end-to-end; Hasyfi dan Daffa dapat mendaftarkan tipe item tanpa menyalin logika retry/WorkManager.

**PRD:** FR-12–FR-16, FR-20, NFR-02, HTTPS NFR-05, idempotensi NFR-04, WorkManager, connectivity listener, token refresh, notifikasi lokal.

---

# Issue 4

**Judul:** `[MODUL 4] Timeline Publik dan Laporan Tindak Lanjut (FR-21–FR-28)`  
**Penanggung jawab:** Daffa Valiant Hansen

## Tujuan
Mengubah dashboard berbasis data contoh menjadi timeline laporan publik dari server, serta membangun tindak lanjut sebagai transaksi kedua yang dapat dibuat offline dan disinkronkan melalui mekanisme bersama.

## Subtask
- [ ] **FR-21 Timeline:** tampilkan foto, kategori, severity, wilayah, nama pelapor, waktu, kondisi jalan terkini, dan jumlah tindak lanjut; urut terbaru dan gunakan pagination.
- [ ] **FR-22 Refresh/cache:** fetch server, pull-to-refresh, cache lokal, waktu pembaruan cache, dan tampilan cache saat offline.
- [ ] **FR-23 Detail publik:** tampilkan foto, deskripsi, koordinat, kondisi jalan, dan tindak lanjut kronologis. Detail dapat dibuka dari Dashboard maupun Riwayat Saya.
- [ ] **FR-24 Filter:** filter kategori, tingkat keparahan, dan kondisi jalan.
- [ ] **FR-25 Buat tindak lanjut:** hanya untuk laporan Terkirim/berisi `server_report_id`; kondisi jalan wajib, catatan/foto opsional; draft dapat disimpan saat offline.
- [ ] **FR-26 Kelola tindak lanjut:** model/repository, status Draft–Menunggu Sinyal–Mengirim–Terkirim/Gagal Terkirim, edit/hapus sesuai status, error/retry melalui Sync Engine Ikhsan, dan tampilkan di Riwayat Saya.
- [ ] **FR-27 Edit/hapus:** hanya tindak lanjut milik sendiri yang Draft atau Gagal Terkirim.
- [ ] **FR-28 Update baru:** deteksi tindak lanjut baru pada laporan milik pengguna ketika aplikasi dibuka dan secara periodik; tampilkan notifikasi lokal. Daffa memiliki logika deteksi; Ikhsan menyediakan penjadwalan/worker dan notification service.
- [ ] Buat migration terpisah untuk `followups` dan `feed_posts` melalui mekanisme database yang dikoordinasikan dengan Hasyfi.

## Kriteria selesai (Definition of Done)
- [ ] Timeline berasal dari API/server, bukan list dummy; pagination dan pull-to-refresh berfungsi.
- [ ] Timeline dan gambar memiliki cache sesuai aturan retensi PRD; dapat dibuka offline dan menampilkan waktu cache terakhir.
- [ ] Filter kategori, severity, dan road_condition bekerja.
- [ ] Detail timeline menampilkan kondisi jalan dan tindak lanjut secara kronologis.
- [ ] Tindak lanjut hanya dapat dibuat pada laporan terkirim dan kondisi jalan wajib diisi.
- [ ] Draft tindak lanjut dapat dibuat offline dan tersimpan permanen dengan UUID serta `user_id`.
- [ ] Status, retry, pesan gagal, dan manual sync tindak lanjut menggunakan Sync Engine Ikhsan; tidak ada worker/retry kedua.
- [ ] Pengguna hanya dapat mengedit/menghapus tindak lanjut miliknya yang Draft atau Gagal Terkirim.
- [ ] Riwayat Saya dapat menampilkan tindak lanjut milik akun aktif melalui kontrak dengan Hasyfi.
- [ ] Pemeriksaan tindak lanjut baru berjalan saat aplikasi dibuka dan secara periodik; notifikasi tidak duplikat untuk item sama.
- [ ] Kondisi jalan mengikuti tindak lanjut terbaru dari server dan read-only di aplikasi.
- [ ] Test cache, pagination, filter, validasi followup, status, ownership, dan deteksi update tersedia.
- [ ] `flutter analyze` untuk file yang dikerjakan tidak memiliki error.

## Dependency dan integrasi
- **Hasyfi:** gunakan fondasi SQLite/migration registry milik Hasyfi. Daffa membuat migration `followups` dan `feed_posts` secara terpisah tanpa mengubah tabel/repository `reports`. Sepakati kontrak agar followup masuk ke Riwayat Saya.
- **Ikhsan:** gunakan API client, sync engine, retry, WorkManager, dan notification service milik Ikhsan. Daffa menyediakan operasi/domain followup yang dipanggil engine.
- **Zaki:** gunakan current user/`user_id` dan sesi/token dari modul akun.
- **Batas kode:** Daffa memiliki dashboard/timeline, model dan repository followup/feed, detail publik, form tindak lanjut, dan migration followups/feed. Jangan mengubah autentikasi atau menyalin implementasi sync.

## Siap diintegrasikan ketika
Timeline dapat dibuka online/offline dan seluruh alur tindak lanjut—buat draft, antrekan, kirim, tampilkan di detail, dan tampilkan di Riwayat Saya—menggunakan kontrak Auth, Database, API, dan Sync Engine yang disepakati.

**PRD:** FR-21–FR-28, NFR-07, persistensi/idempotensi NFR-04, cache, WorkManager, notifikasi lokal.

---

# Koordinasi lintas issue

## Urutan dependency utama
1. Seluruh anggota menyepakati `user_id`, token/session interface, UUID, status sinkronisasi, model data, API response, dan kontrak repository.
2. Zaki + Ikhsan menyepakati API client dan token provider; Ikhsan mengonsumsi token/session dari Zaki.
3. Hasyfi menyiapkan fondasi SQLite, migration registry, dan tabel `reports`.
4. Daffa menambahkan tabel `followups` dan `feed_posts` lewat migration terpisah di atas fondasi yang sama.
5. Ikhsan + Hasyfi mengintegrasikan upload dan status sinkronisasi laporan.
6. Ikhsan + Daffa mengintegrasikan tindak lanjut ke sync engine generik dan jadwal pemeriksaan tindak lanjut.
7. Semua anggota menguji alur end-to-end pada perangkat Android.

## Aturan Git dan integrasi
- Setiap anggota bekerja pada feature branch sendiri dan membuat Pull Request ke `feat/integrasi-modul`.
- Jangan mengedit file milik modul anggota lain tanpa koordinasi.
- Perubahan `pubspec.yaml`, route global, migration registry, API contract, dan komponen bersama harus dibahas sebelum merge.
- Setiap PR menyertakan ringkasan perubahan, FR terkait, bukti pengujian, dan catatan dependency.
- UI/mock tidak boleh dianggap sebagai FR DONE; status DONE memerlukan perilaku sesuai PRD dan bukti pengujian.

## Urutan milestone (tanpa tanggal deadline)
- **Fondasi:** kontrak backend/API, model data, interface akun, database, dan sync disepakati.
- **Pengerjaan paralel:** empat anggota mengerjakan modul sesuai kepemilikan.
- **Integrasi pertama:** auth + SQLite reports + API client + antrean laporan.
- **Integrasi kedua:** timeline/cache + followups + sync followups.
- **Penutupan:** pengujian seluruh FR dan NFR yang dapat diukur pada perangkat Android fisik.
