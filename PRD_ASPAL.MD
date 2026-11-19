PROJECT PRD

Product Requirements Document

| Project Name | ASPAL (Aplikasi Survei Pelaporan Akses Lalu-lintas) |
| --- | --- |
| Team | 1. Zaki Alfurqani (2411522015) 2. Hasyfi Zharfan Caniago (2411522037) 3. M. Ikhsan Pratama (2411522038) 4. Daffa Valiant Hansen (2411523004) |
| Course | Mobile Programming |
| Version | 1.4 (Revisi) |
| Date | 17 November 2026 |

# 1. Problem & Users

## 1.1 Problem Statement

Masyarakat atau petugas survei lapangan sering menemukan kerusakan infrastruktur jalan di area perbatasan atau pedalaman yang minim sinyal internet, sehingga pelaporan lokasi koordinat dan foto secara real-time sering kali gagal dilakukan

## 1.2 Target Users

Primary user: relawan infrastruktur dan petugas pemeliharaan jalan raya daerah yang melakukan survei di area perbatasan/pedalaman dengan sinyal minim. Secondary user: masyarakat umum pengguna jalan raya yang ingin melaporkan kerusakan jalan. Seluruh pengguna wajib mendaftar dan login menggunakan akun sehingga kepemilikan laporan dan tindak lanjut dapat diverifikasi. Pada tahap pengembangan ini, aplikasi difokuskan untuk perangkat berbasis Android.

## 1.3 User Needs / Pain Points

Pengguna butuh mengambil foto kerusakan dan menyimpan lokasinya tanpa harus terhubung ke internet.

Pengguna sering lupa melapor jika harus menunggu sampai tiba di rumah atau area yang bersinyal.

Pengguna kesulitan mendeskripsikan secara akurat lokasi jalan rusak jika tidak didukung dengan titik koordinat GPS yang pasti.

Pengguna sering tidak mengetahui apakah laporan gagal terkirim karena kendala jaringan atau kesalahan server, sehingga tidak yakin harus menunggu atau melapor ulang.

Pengguna tidak dapat mengetahui perkembangan kondisi kerusakan yang sudah dilaporkan (apakah masih rusak, sedang diperbaiki, atau sudah diperbaiki) dan tidak dapat melihat laporan kerusakan lain yang sudah masuk sehingga rawan terjadi laporan ganda.

## 1.4 Project Goal

Membangun aplikasi mobile pelaporan infrastruktur berbasis offline-first yang mampu merekam foto dan titik koordinat GPS jalan rusak, menyimpannya di perangkat, lalu menyinkronkan data tersebut ke sistem pusat secara otomatis saat koneksi internet tersedia, serta memberi transparansi kepada pengguna, baik status pengiriman setiap laporan (termasuk penyebab kegagalan kirim) maupun perkembangan kondisi kerusakan jalan melalui beranda berbentuk timeline laporan dan laporan tindak lanjut dari pengguna, dengan kepemilikan data yang terverifikasi melalui akun pengguna.

# 2. Product Requirements

2.1 Functional Requirements

Akun & Autentikasi

FR-01: Pengguna harus bisa melakukan registrasi akun dengan mengisi nama, email, dan password; email harus unik. Registrasi memerlukan koneksi internet.

FR-02: Pengguna harus bisa login menggunakan email dan password; seluruh fitur aplikasi hanya dapat diakses setelah login. Setelah berhasil, sesi login tersimpan di perangkat sehingga pengguna tetap masuk saat aplikasi dibuka ulang, termasuk tanpa koneksi internet. Jika sesi berakhir dan tidak dapat diperbarui, sinkronisasi dijeda dan pengguna diminta login ulang tanpa menghapus data lokal.

FR-03: Pengguna harus bisa logout; jika masih ada laporan atau tindak lanjut yang belum terkirim, sistem menampilkan peringatan dan pengguna dapat membatalkan logout atau mengonfirmasinya dengan konsekuensi data lokal yang belum terkirim dihapus.

FR-04: Pengguna harus bisa melihat dan mengubah profil (nama tampil) serta mengubah password.

Pengumpulan Data

FR-05: Pengguna harus bisa mengambil foto kerusakan jalan menggunakan kamera aplikasi, dan sistem harus otomatis mengunci titik koordinat GPS saat foto diambil.

FR-06: Pengguna harus bisa menambahkan foto kerusakan jalan yang dipilih dari galeri perangkat.

FR-07: Pengguna harus bisa mengisi detail laporan seperti kategori, tingkat keparahan, deskripsi, dan memasukkan titik koordinat GPS secara manual (jika foto diambil dari galeri).

Draft Lokal

FR-08: Sistem harus memvalidasi kelengkapan data wajib (foto, titik GPS, dan kategori) saat pengguna menekan tombol Kirim; laporan yang belum lengkap tetap dapat disimpan sebagai draf.

FR-09: Sistem harus bisa menyimpan laporan ke database lokal perangkat (terikat pada akun pengguna yang sedang login) sebagai Draft; saat data wajib sudah lengkap dan pengguna memilih Kirim, status laporan berubah menjadi Menunggu Sinyal dan laporan masuk antrean sinkronisasi.

FR-10: Pengguna harus bisa mengedit detail laporan yang berstatus Draft atau Gagal Terkirim; laporan berstatus Menunggu Sinyal atau Mengirim dikunci selama proses sinkronisasi berlangsung.

FR-11: Pengguna harus bisa menghapus laporan yang berstatus Draft atau Gagal Terkirim dari penyimpanan lokal (dengan konfirmasi); laporan berstatus Menunggu Sinyal atau Mengirim tidak dapat dihapus.

Sinkronisasi

FR-12: Sistem harus bisa melakukan sinkronisasi otomatis di latar belakang (background auto-sync) terhadap laporan berstatus Menunggu Sinyal saat perangkat terdeteksi terhubung ke internet dan server dapat dijangkau.

FR-13: Sistem harus melakukan percobaan pengiriman ulang (auto-retry) maksimal 3 kali dengan jeda bertahap (backoff) jika laporan gagal terkirim; setelah percobaan ke-3 gagal, status laporan menjadi Gagal Terkirim.

FR-14: Pengguna harus bisa melakukan sinkronisasi manual untuk mengulang pengiriman satu laporan yang gagal atau mengirim seluruh antrean draf sekaligus.

FR-15: Sistem harus menampilkan pesan informasi mengenai penyebab gagal kirim (misalnya tidak ada koneksi, server tidak merespons, sesi login berakhir, atau data ditolak server) pada laporan yang tidak berhasil disinkronkan.

FR-16: Pengguna harus menerima notifikasi lokal di perangkat saat proses sinkronisasi seluruh antrean laporan selesai.

Riwayat

FR-17: Pengguna harus bisa melihat daftar riwayat pelaporan dan tindak lanjut milik akunnya (Riwayat Saya) yang dilengkapi dengan indikator status (Draft, Menunggu Sinyal, Mengirim, Gagal Terkirim, atau Terkirim).

FR-18: Pengguna harus bisa menyaring (filter) daftar riwayat laporan berdasarkan status pengirimannya.

FR-19: Pengguna harus bisa melihat detail laporan komprehensif yang mencakup foto (dari penyimpanan lokal, atau thumbnail/foto dari server untuk laporan yang sudah Terkirim), koordinat, kategori, deskripsi, waktu pelaporan, dan status.

FR-20: Sistem harus menampilkan indikator status koneksi internet dan jumlah total laporan serta tindak lanjut yang sedang menunggu antrean sinkronisasi.

Beranda (Timeline)

FR-21: Pengguna harus bisa melihat beranda berupa timeline laporan kerusakan jalan yang sudah dilaporkan; setiap kartu menampilkan foto, kategori, tingkat keparahan, wilayah, nama tampil pelapor, waktu pelaporan, kondisi jalan terkini, dan jumlah tindak lanjut, diurutkan dari yang terbaru dan dimuat bertahap (pagination).

FR-22: Sistem harus mengunduh dan memperbarui data timeline dari server saat perangkat online (termasuk pull-to-refresh), dan menampilkan data cache terakhir beserta waktu pembaruannya saat perangkat offline.

FR-23: Pengguna harus bisa membuka detail laporan dari timeline yang menampilkan foto, deskripsi, koordinat, kondisi jalan terkini, dan daftar tindak lanjut dari pengguna secara kronologis.

FR-24: Pengguna harus bisa menyaring timeline berdasarkan kategori, tingkat keparahan, dan kondisi jalan.

Tindak Lanjut Laporan

FR-25: Pengguna harus bisa menambahkan tindak lanjut pada laporan yang sudah terkirim (dari timeline atau Riwayat Saya), berupa kondisi jalan terbaru (Masih Rusak, Sedang Diperbaiki, atau Sudah Diperbaiki) yang wajib diisi serta catatan dan foto yang bersifat opsional, termasuk saat perangkat offline.

FR-26: Sistem harus memperlakukan tindak lanjut dengan siklus status dan mekanisme sinkronisasi yang sama dengan laporan (draf, antrean Menunggu Sinyal, sinkronisasi otomatis di latar belakang, auto-retry maksimal 3 kali, sinkronisasi manual, dan pesan penyebab gagal kirim), dan menampilkan statusnya pada Riwayat Saya.

FR-27: Pengguna harus bisa mengedit atau menghapus tindak lanjut miliknya yang berstatus Draft atau Gagal Terkirim.

FR-28: Sistem harus memeriksa pembaruan tindak lanjut atas laporan milik akun pengguna (saat aplikasi dibuka dan secara periodik di latar belakang) dan menampilkan notifikasi lokal bila ada tindak lanjut baru dari pengguna lain.

Supporting / Technical Requirements (tidak dihitung sebagai FR)

Permission runtime: kamera, lokasi (saat aplikasi digunakan), dan notifikasi (POST_NOTIFICATIONS pada Android 13 ke atas).

Pembuatan Device_ID (UUID) saat aplikasi pertama kali dibuka, hanya sebagai identitas perangkat untuk keperluan audit (kepemilikan data memakai akun pengguna).

Penyimpanan token sesi pada penyimpanan aman (secure storage) serta pemasangan token otomatis pada setiap permintaan API, termasuk pembaruan token (refresh).

Registrasi tugas latar belakang (WorkManager) untuk sinkronisasi (laporan dan tindak lanjut) serta pemeriksaan pembaruan tindak lanjut, serta listener konektivitas.

Konfigurasi endpoint API (registrasi, login, refresh token, logout, profil, kirim laporan, kirim tindak lanjut, ambil timeline, ambil tindak lanjut, ambil riwayat milik akun) dan pengiriman data melalui HTTPS.

2.2 Non-functional Requirements

NFR-01 (Kinerja GPS): Aplikasi dapat menangkap titik koordinat GPS dengan durasi maksimal 5 detik pada perangkat dengan fitur lokasi aktif di area terbuka.

NFR-02 (Responsivitas): Proses sinkronisasi background berjalan terpisah dari UI thread sehingga antarmuka tetap merespons input pengguna dalam waktu ≤ 1 detik selama sinkronisasi berlangsung (tidak freeze).

NFR-03 (Efisiensi): Ukuran file gambar dikompresi maksimal 2 MB per foto saat disimpan ke draf lokal, sebelum dikirim ke server, untuk menghemat penyimpanan dan bandwidth.

NFR-04 (Reliabilitas): Data draf dan antrean laporan tidak hilang saat aplikasi ditutup paksa, perangkat dimatikan, atau proses sinkronisasi terputus; setiap laporan memiliki ID unik dari klien sehingga pengiriman ulang tidak menimbulkan duplikasi di server.

NFR-05 (Keamanan): Pengiriman data dan foto ke server menggunakan HTTPS, dan aplikasi hanya meminta izin yang diperlukan (kamera, lokasi saat aplikasi digunakan, dan notifikasi).

NFR-06 (Kompatibilitas): Aplikasi berjalan pada Android 8.0 (API 26) ke atas.

NFR-07 (Kinerja Timeline): Halaman pertama timeline (maksimal 10 laporan) termuat dalam ≤ 3 detik pada koneksi 4G yang stabil, tanpa memblokir antarmuka aplikasi.

NFR-08 (Keamanan Akun): Password disimpan di server dalam bentuk hash (misalnya bcrypt) dan tidak pernah disimpan di perangkat; token sesi disimpan terenkripsi pada penyimpanan aman perangkat.

NFR-09 (Ketersediaan Sesi): Aplikasi dapat dibuka dan digunakan tanpa koneksi internet selama sesi login masih berlaku (usulan masa berlaku sesi 30 hari); proses registrasi dan login selesai dalam ≤ 3 detik pada koneksi 4G yang stabil.

2.3 Core Features

| No. | Core Feature | Purpose / Value | FR Terkait |
| --- | --- | --- | --- |
| 1 | Akun & Autentikasi | Memverifikasi identitas pengguna melalui registrasi dan login sehingga kepemilikan laporan dan tindak lanjut dapat dipastikan, dengan sesi yang tetap aktif saat offline. | FR-01 s.d. FR-04 |
| 2 | Offline Pelaporan (Geo-Tagging & Draft Lokal) | Memungkinkan pengguna mengunci lokasi (GPS) otomatis atau manual tanpa koneksi data aktif, lalu menyimpan detail laporan dan media sebagai draf agar banyak titik dapat diinput dengan cepat, lengkap dengan validasi dan pengelolaan draf. | FR-05 s.d. FR-11 |
| 3 | Background Auto-Sync | Meringankan beban pengguna karena aplikasi otomatis mengunggah data (laporan dan tindak lanjut) ketika masuk ke zona bersinyal, dengan auto-retry, sinkronisasi manual, dan notifikasi. | FR-12 s.d. FR-16 |
| 4 | Riwayat & Sync Status Dashboard | Memberikan transparansi kepada pengguna tentang laporan dan tindak lanjut miliknya yang sudah terkirim, sedang menunggu, atau gagal terkirim beserta penyebabnya. | FR-17 s.d. FR-20 |
| 5 | Beranda Timeline Laporan | Menampilkan laporan kerusakan jalan yang sudah masuk dalam bentuk timeline (semi media sosial) agar pengguna mendapat gambaran kondisi jalan sekitar dan laporan ganda berkurang; tetap dapat dibuka saat offline melalui cache. | FR-21 s.d. FR-24 |
| 6 | Laporan Tindak Lanjut | Memungkinkan pengguna melaporkan perkembangan kondisi kerusakan jalan (masih rusak, sedang diperbaiki, sudah diperbaiki) beserta catatan dan foto, termasuk saat offline, serta memberi tahu pelapor bila laporannya mendapat tindak lanjut. | FR-25 s.d. FR-28 |

## 2.4 User Flow

Alur utama: Buka Aplikasi → Login (pertama kali, online; selanjutnya sesi tersimpan) → Tap "Lapor Kerusakan" → Ambil Foto (Offline) → Sistem Membaca GPS (Offline) → Isi Detail dan Simpan ke Draft Lokal → Tap "Kirim" (status Menunggu Sinyal) → Pengguna Memasuki Area Bersinyal → Aplikasi Mendeteksi Internet → Laporan Diunggah Otomatis (Background, status Mengirim) → Status Berubah Menjadi Terkirim.

Alternatif – registrasi: Buka Aplikasi → Tap "Daftar" → Isi Nama, Email, dan Password (online) → Akun Dibuat → Masuk ke Beranda.

Alternatif – buka aplikasi tanpa internet: Buka Aplikasi → Sesi Tersimpan Masih Valid → Langsung Masuk Beranda (cache) → Buat Laporan Offline.

Alternatif – sesi berakhir: Sinkronisasi Mendapat Respons Sesi Tidak Valid → Sinkronisasi Dijeda dan Item Tetap Tersimpan → Pengguna Diminta Login Ulang → Sinkronisasi Dilanjutkan Otomatis.

Alternatif – logout: Tap Logout → (Jika Ada Item Belum Terkirim) Peringatan → Batalkan atau Konfirmasi → Sesi dan Data Lokal Akun Dibersihkan.

Alternatif – foto dari galeri: Tap "Lapor Kerusakan" → Pilih Foto dari Galeri → Isi Koordinat GPS Secara Manual → Simpan ke Draft Lokal.

Alternatif – gagal kirim: Unggah Gagal → Auto-Retry (maksimal 3 kali) → Status Gagal Terkirim dan Pesan Penyebab Ditampilkan → Pengguna Mengedit (opsional) → Kirim Ulang Manual. Alur ini berlaku untuk laporan maupun tindak lanjut.

Alternatif – sinkronisasi manual: Buka Riwayat → Pilih Satu Item Gagal atau Kirim Seluruh Antrean → Sinkronisasi Berjalan → Notifikasi Lokal Saat Seluruh Antrean Selesai.

Alternatif – pantau status: Buka Riwayat → Filter Berdasarkan Status → Buka Detail Laporan.

Alternatif – beranda: Buka Beranda → Lihat Timeline Laporan (online: data terbaru; offline: cache terakhir) → Filter → Buka Detail → Lihat Kondisi Jalan dan Daftar Tindak Lanjut.

Alternatif – tindak lanjut: Buka Beranda → Pilih Laporan → Tap "Tambah Tindak Lanjut" → Pilih Kondisi Jalan, Isi Catatan, dan Tambah Foto (opsional) → Simpan ke Draft → Tap "Kirim" (Menunggu Sinyal) → Diunggah Otomatis Saat Ada Sinyal → Tindak Lanjut Muncul di Detail Laporan.

Alternatif – notifikasi tindak lanjut: Pengguna Lain Menambahkan Tindak Lanjut pada Laporan Anda → Aplikasi Memeriksa Pembaruan (saat dibuka atau periodik) → Notifikasi Lokal → Pengguna Membuka Detail Laporan.

## 2.5 Data Requirements

Data disimpan pada database lokal (SQLite), sedangkan token sesi disimpan pada penyimpanan aman perangkat. Seluruh data milik pengguna diikat ke akun (user_id). Laporan dan tindak lanjut milik pengguna dikirim ke server dalam format JSON beserta file gambar, sedangkan data timeline dan tindak lanjut pengguna lain diunduh dari server dan disimpan sebagai cache (hanya-baca). Penamaan atribut memakai snake_case. sync_status (status pengiriman) dibedakan dari road_condition (kondisi jalan terkini).

Entitas Data

| Data / Entity | Key Information | Purpose |
| --- | --- | --- |
| users (Akun, sisi server) | user_id; display_name; email (unik); password_hash; created_at; updated_at | Identitas dan kepemilikan data; password hanya disimpan sebagai hash di server (FR-01 s.d. FR-04). |
| session (Sesi Lokal) | user_id; display_name; email; access_token; refresh_token; token_expires_at; logged_in_at (disimpan di secure storage, bukan SQLite biasa) | Menjaga sesi tetap aktif saat offline dan menempelkan token pada setiap permintaan API (FR-02, FR-03, FR-12 s.d. FR-16). |
| reports (Report Log) | report_id (UUID dibuat di klien, kunci unik pencegah duplikat saat retry); user_id (FK ke akun pemilik); category; severity; description; latitude; longitude; gps_accuracy; gps_source (kamera/manual); photo_local_path; photo_remote_url; thumbnail_path; photo_size_bytes; sync_status; road_condition; server_report_id; created_at; updated_at; synced_at; retry_count; last_attempt_at; next_retry_at; last_error_message | Entitas utama laporan milik pengguna: isi laporan, status sinkronisasi, data retry, dan salinan kondisi jalan terkini dari server (FR-05 s.d. FR-15, FR-17 s.d. FR-19). |
| followups (Tindak Lanjut) | followup_id (UUID dibuat di klien); server_report_id (FK ke laporan induk); server_followup_id; user_id (FK ke akun penulis); display_name; road_condition (kondisi jalan yang dilaporkan); note; photo_local_path; photo_remote_url; thumbnail_path; sync_status; created_at; updated_at; synced_at; cached_at; retry_count; last_attempt_at; next_retry_at; last_error_message | Entitas transaksi kedua: tindak lanjut milik pengguna (dengan siklus sinkronisasi) sekaligus cache tindak lanjut pengguna lain untuk detail laporan; milik sendiri bila user_id sama dengan akun yang login (FR-23, FR-25 s.d. FR-28). |
| sync_attempts (Sync Log) | attempt_id; entity_type (laporan/tindak lanjut); entity_id; attempt_no; attempted_at; trigger (otomatis/manual); result; http_status; error_code (misalnya NO_NETWORK, SERVER_ERROR, AUTH_EXPIRED); error_message | Mencatat setiap percobaan pengiriman laporan maupun tindak lanjut sebagai jejak audit dan sumber pesan penyebab gagal (FR-13 s.d. FR-15, FR-26). |
| feed_posts (Cache Timeline) | server_report_id; user_id; display_name (nama tampil pelapor); category; severity; description; region_name; latitude; longitude; photo_url; thumbnail_path; road_condition; followup_count; created_at; cached_at | Cache laporan publik untuk beranda agar tetap dapat dibuka saat offline (FR-21 s.d. FR-24). |
| app_state (Device Data) | device_id (UUID dibuat saat pertama dibuka, hanya untuk audit); last_sync_at; last_feed_sync_at; last_followup_check_at | Mencatat identitas perangkat serta waktu sinkronisasi, pembaruan timeline, dan pengecekan tindak lanjut terakhir (FR-16, FR-20, FR-22, FR-28). |
| Referensi (konstanta aplikasi) | category (contoh: lubang, retak, amblas); severity (ringan, sedang, berat); road_condition (MASIH_RUSAK, SEDANG_DIPERBAIKI, SUDAH_DIPERBAIKI) | Menjaga konsistensi pilihan kategori, tingkat keparahan, dan kondisi jalan (FR-07, FR-24, FR-25). |

Siklus Status Pengiriman (sync_status) – berlaku untuk laporan dan tindak lanjut

| sync_status | Arti | Transisi | FR |
| --- | --- | --- | --- |
| DRAFT | Tersimpan lokal, belum dikirim; boleh belum lengkap | → MENUNGGU_SINYAL saat pengguna menekan Kirim dan data wajib lengkap; dapat diedit/dihapus | FR-08 s.d. FR-11, FR-25, FR-27 |
| MENUNGGU_SINYAL | Masuk antrean, menunggu koneksi | → MENGIRIM saat koneksi tersedia, server terjangkau, dan sesi login valid (jika sesi berakhir, item tetap MENUNGGU_SINYAL dan sinkronisasi dijeda sampai login ulang); dikunci (tidak dapat diedit/dihapus) | FR-12, FR-20, FR-26 |
| MENGIRIM | Sedang diunggah ke server | → TERKIRIM bila berhasil; dijadwalkan ulang bila gagal dan retry_count < 3; → GAGAL_TERKIRIM bila percobaan ke-3 gagal | FR-12, FR-13, FR-26 |
| GAGAL_TERKIRIM | Gagal setelah 3 kali retry; pesan penyebab ditampilkan | → MENUNGGU_SINYAL melalui sinkronisasi manual; dapat diedit/dihapus | FR-10, FR-11, FR-14, FR-15, FR-27 |
| TERKIRIM | Berhasil diterima server; laporan tampil di beranda dan dapat ditindaklanjuti pengguna | Status akhir; foto lokal dihapus (thumbnail dan metadata dipertahankan untuk riwayat) | FR-17, FR-19, FR-21, FR-25 |

Kebutuhan Data per FR

| FR | Data yang dibutuhkan |
| --- | --- |
| FR-01 s.d. FR-04 | users (user_id, display_name, email, password_hash); session (user_id, access_token, refresh_token, token_expires_at) |
| FR-05 s.d. FR-07 | photo_local_path, latitude, longitude, gps_accuracy, gps_source, category, severity, description, user_id |
| FR-08 s.d. FR-11 | sync_status, updated_at beserta seluruh kolom isi laporan yang divalidasi/diedit/dihapus |
| FR-12, FR-14 | sync_status (MENUNGGU_SINYAL), photo_local_path, report_id/followup_id (idempotensi), server_report_id, synced_at, session (token) |
| FR-13, FR-15 | retry_count, last_attempt_at, next_retry_at, last_error_message; sync_attempts (attempt_no, result, http_status, error_code, error_message) |
| FR-16, FR-20 | sync_status (hitung antrean), last_sync_at; status koneksi dibaca saat runtime (tidak disimpan) |
| FR-17 s.d. FR-19 | sync_status (diindeks untuk filter), created_at, thumbnail_path, photo_remote_url, latitude, longitude, category, description; reports dan followups dengan user_id = akun yang login (Riwayat Saya) |
| FR-21 s.d. FR-24 | feed_posts (seluruh kolom), followups (user_id akun lain, untuk detail), last_feed_sync_at (penanda waktu pembaruan cache), road_condition (filter) |
| FR-25 s.d. FR-27 | followups (followup_id, server_report_id, user_id, road_condition, note, photo_local_path, sync_status, created_at, updated_at, kolom retry), sync_attempts (entity_type = tindak lanjut) |
| FR-28 | followups (server_followup_id, user_id, created_at), reports (server_report_id, user_id), last_followup_check_at |

Aturan Data (Business Rules)

Retensi foto: setelah laporan atau tindak lanjut berstatus Terkirim, file foto asli di perangkat dihapus otomatis; metadata dan thumbnail tetap disimpan untuk keperluan riwayat.

Batas penyimpanan lokal: maksimal 100 item (laporan dan tindak lanjut) yang belum terkirim atau 500 MB (mana yang tercapai lebih dulu); saat batas tercapai, pengguna diminta mengirim atau menghapus item sebelum membuat yang baru.

Cache timeline: menyimpan maksimal 100 laporan terbaru beserta tindak lanjutnya dan cache gambar maksimal 100 MB; data terlama dibersihkan otomatis dan tidak dihitung dalam batas item yang belum terkirim.

Syarat tindak lanjut: hanya dapat dibuat pada laporan yang sudah Terkirim (memiliki server_report_id); tindak lanjut dapat dibuat oleh pengguna terdaftar mana pun.

Kondisi jalan terkini: road_condition suatu laporan mengikuti tindak lanjut terbaru yang diterima server; laporan tanpa tindak lanjut berstatus MASIH_RUSAK. Di aplikasi, nilai ini hanya-baca dan mengikuti data server.

Kepemilikan: setiap laporan dan tindak lanjut terikat pada user_id yang diambil server dari token sesi (bukan dari isi permintaan); server hanya mengizinkan pemilik mengubah atau menghapus datanya dan menolak selainnya (kode 403).

Keamanan sesi dan isolasi data lokal: password tidak disimpan di perangkat dan token disimpan di secure storage; seluruh query lokal difilter berdasarkan user_id akun yang login; saat logout, token dan data lokal akun dibersihkan.

Pemulihan data: setelah aplikasi dipasang ulang dan pengguna login, Riwayat Saya (item berstatus Terkirim) dapat diunduh ulang dari server; draf dan antrean yang belum terkirim tidak dapat dipulihkan.

Idempotensi: server mengabaikan atau menggabungkan kiriman dengan pasangan user_id dan report_id/followup_id yang sama sehingga retry tidak menimbulkan duplikasi.

## 2.6 Constraints & Assumptions

Asumsi (API): Ada titik penerima (API) di sisi backend (misalnya skrip PHP) berbasis token (misalnya Bearer/JWT) dengan endpoint registrasi, login, refresh token, logout, profil, kirim laporan dan tindak lanjut (JSON beserta foto multipart) melalui HTTPS, ambil timeline (dengan pagination), ambil tindak lanjut, dan ambil riwayat milik akun. Server mengembalikan status sukses/gagal yang jelas, menangani duplikasi, memverifikasi kepemilikan dari token, dan menghitung kondisi jalan terkini dari tindak lanjut terbaru.

Asumsi (Akun): Seluruh fitur wajib login. Registrasi dan login pertama harus dilakukan saat online; setelah itu sesi tersimpan sehingga aplikasi dapat dipakai offline selama sesi valid (usulan masa berlaku 30 hari). Pengguna yang belum pernah login dan tidak memiliki sinyal tidak dapat memakai aplikasi (diterima sebagai keterbatasan; registrasi dan login dilakukan saat berada di area bersinyal). Verifikasi email/OTP, lupa password, dan login sosial tidak disediakan pada tahap ini.

Asumsi (Tindak lanjut): Tindak lanjut dapat dibuat oleh pengguna terdaftar mana pun pada laporan yang sudah Terkirim. Keabsahan isi laporan dan tindak lanjut tidak diverifikasi di dalam aplikasi; moderasi berada di luar scope sehingga risiko laporan atau tindak lanjut palsu diterima sebagai keterbatasan, dengan akun sebagai jejak pertanggungjawaban.

Asumsi (Perangkat): Perangkat uji berbasis Android 8.0 (API 26) ke atas dengan sensor GPS dan kamera yang berfungsi.

Batasan Teknis (Platform): Klien dikembangkan menggunakan bahasa Dart dan framework Flutter dengan database lokal SQLite. Pengujian dan jaminan fungsi difokuskan pada Android; iOS berada di luar scope.

Batasan Teknis (Background Sync): Sinkronisasi latar belakang (laporan dan tindak lanjut) memakai WorkManager (paket workmanager pada Flutter) dengan constraint jaringan terhubung. Android membatasi tugas latar belakang: interval periodik minimum 15 menit, serta Doze/penghemat baterai (termasuk kebijakan beberapa pabrikan) dapat menunda eksekusi. Karena itu sinkronisasi memakai dua jalur: (1) saat aplikasi terbuka, dipicu segera oleh listener konektivitas; (2) saat aplikasi di background, dijalankan secara best-effort oleh WorkManager. Deteksi jaringan selalu diikuti pengecekan keterjangkauan server untuk menghindari kasus Wi-Fi tanpa internet. Tugas latar belakang mengakses token dari penyimpanan aman dan memperbaruinya secara otomatis; bila gagal diperbarui, sinkronisasi dijeda sampai pengguna login ulang.

Batasan Teknis (Pembaruan Tindak Lanjut): Pemeriksaan tindak lanjut baru memakai mekanisme periodik yang sama (minimum 15 menit) dan saat aplikasi dibuka. Aplikasi tidak memakai push notification dari server (misalnya FCM), sehingga notifikasi tindak lanjut bersifat best-effort.

Batasan Teknis (Notifikasi): Notifikasi lokal pada Android 13 ke atas memerlukan izin runtime POST_NOTIFICATIONS.

Batasan Teknis (Penyimpanan): Jumlah item yang belum terkirim dan cache timeline dibatasi sesuai Aturan Data agar penyimpanan perangkat tidak penuh.

Batasan Teknis (Peran aplikasi): Aplikasi berfungsi sebagai alat pengumpul dan penampil data (klien); analitik lanjutan atas koordinat yang terkumpul dilakukan di luar aplikasi mobile ini.

## 2.7 Success Criteria

Dalam pengujian pada minimal 20 laporan dengan koneksi internet dimatikan sepenuhnya, aplikasi berhasil mencatat titik GPS dan menyimpan foto tanpa error (crash), dan seluruh draf tetap tersimpan setelah aplikasi ditutup lalu dibuka kembali.

Setelah satu kali login saat online, pengguna dapat membuka aplikasi dan membuat laporan tanpa internet, dan sesi tetap aktif setelah aplikasi ditutup lalu dibuka kembali.

Laporan atau tindak lanjut berstatus Menunggu Sinyal berpindah menjadi Terkirim maksimal 2 menit setelah perangkat kembali mendapat akses internet saat aplikasi aktif (foreground), dan maksimal 30 menit saat aplikasi berada di background (best-effort WorkManager) pada perangkat uji.

Laporan atau tindak lanjut yang gagal terkirim setelah proses retry otomatis (3 kali percobaan) ditandai jelas sebagai Gagal Terkirim lengkap dengan pesan penyebab, dan tersedia opsi retry manual, tanpa ada data yang hilang atau terlewat secara diam-diam.

Beranda menampilkan minimal 20 laporan terbaru dari server saat online dan tetap menampilkan cache timeline terakhir saat offline tanpa crash; kondisi jalan dan daftar tindak lanjut tampil sesuai data dari server.

Pengguna dapat membuat tindak lanjut saat offline, dan tindak lanjut tersebut otomatis terkirim serta muncul pada detail laporan setelah koneksi tersedia.

Pengguna tidak dapat mengubah atau menghapus laporan dan tindak lanjut milik pengguna lain (server menolak permintaan tersebut), dan Riwayat Saya hanya menampilkan data milik akun yang sedang login.

Seluruh 28 FR dapat didemonstrasikan dan lulus pengujian skenario utama (alur akun, alur sukses, alur gagal kirim, alur beranda, dan alur tindak lanjut) pada minimal satu perangkat Android fisik.

# 3. Scope

## 3.1 In Scope

Pembuatan UI pengumpulan data (kamera, galeri, dan form detail laporan) serta dasbor riwayat.

Perekaman titik koordinat via API Lokasi perangkat.

Manajemen database lokal (seperti SQLite/library database lokal yang relevan untuk ekosistem Dart/Flutter) dan mekanisme sinkronisasi latar belakang.

Registrasi, login, logout, dan pengelolaan profil akun; seluruh fitur aplikasi wajib login.

Penyimpanan draf dan antrean laporan, validasi data, serta pengelolaan siklus status laporan.

Sinkronisasi otomatis (background) dan manual, auto-retry, serta notifikasi lokal.

Riwayat laporan dan tindak lanjut dengan filter status, detail laporan, dan indikator koneksi/antrean.

Beranda timeline laporan (unduh data, cache offline, filter, dan detail) serta pembuatan laporan tindak lanjut oleh pengguna (termasuk saat offline) beserta notifikasi lokalnya.

## 3.2 Out of Scope

Fitur navigasi peta interaktif (routing arah menghindari jalan rusak layaknya Google Maps).

Pengembangan dashboard admin berbasis web yang kompleks (fokus pada fitur mobile terlebih dahulu).

Dukungan platform iOS (pengembangan dan jaminan fungsi background sync difokuskan pada Android).

Verifikasi email/OTP, lupa/reset password, login sosial (misalnya Google), autentikasi biometrik, dan peran khusus (misalnya akun instansi/admin).

Verifikasi/moderasi laporan dan tindak lanjut, dashboard admin, serta analitik lanjutan (misalnya clustering K-Means/DBSCAN) yang dilakukan di luar aplikasi mobile ini.

Interaksi sosial (like, komentar, share, chat) dan push notification dari server.

# 4. AI Prompt Context

ASPAL (Aplikasi Survei Pelaporan Akses Lalu-lintas) adalah aplikasi mobile Android berbasis Flutter (Dart) yang difokuskan pada pengumpulan data spasial secara offline-first. Seluruh fitur wajib login (registrasi, login, logout, profil); login pertama harus online, lalu sesi disimpan di secure storage sehingga aplikasi tetap dapat dipakai offline, dan seluruh data diikat ke user_id. Aplikasi memiliki dua transaksi: pembuatan laporan kerusakan jalan (foto dan GPS) dan laporan tindak lanjut (kondisi jalan Masih Rusak/Sedang Diperbaiki/Sudah Diperbaiki, catatan, foto opsional) yang dibuat oleh pengguna. Keduanya disimpan di database lokal (SQLite) dengan siklus sync_status Draft → Menunggu Sinyal → Mengirim → Terkirim/Gagal Terkirim, lalu dikirim secara background (WorkManager dan listener konektivitas) dengan token yang diperbarui otomatis, auto-retry maksimal 3 kali, dan sinkronisasi manual. Beranda berbentuk timeline laporan publik (di-cache untuk offline) menampilkan kondisi jalan terkini dan tindak lanjut dari pengguna. Hindari implementasi fitur visualisasi peta yang berat, verifikasi email/OTP, dan dashboard admin; fokus pada logic offline storage, manajemen sesi, kompresi media, manajemen status, sinkronisasi API, dan cache timeline.

# PRD Checklist

Problem statement jelas dan berfokus pada pengguna.

Target users spesifik.

Project goal menjawab masalah yang diidentifikasi.

Core features berjumlah sekitar 4–6 dan relevan.

User flow utama sudah dituliskan.

Data utama sudah diidentifikasi.

Constraints dan assumptions sudah dicatat.

Success criteria dapat digunakan untuk menilai hasil project.

In Scope dan Out of Scope sudah jelas.

Functional requirements menjelaskan perilaku/fungsi yang harus dilakukan aplikasi.

Non-functional requirements menjelaskan kualitas atau batasan sistem dan, jika memungkinkan, dapat diukur.

Functional requirements konsisten dengan core features.

Non-functional requirements tidak ditulis sebagai fitur baru.
