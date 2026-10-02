# Insap: Yuk Sadar Boncos

Aplikasi pencatat keuangan pribadi berbasis AI untuk mahasiswa.

## Tim Pengembang

| Nama | NIM | Peran |
|---|---|---|
| Riyadi | 2409106074 | Project Manager, pemegang fondasi |
| Daffa | 2309106063 | Pemegang fitur |
| Luthfi | (NIM menyusul) | Pemegang fitur |

Mata kuliah Pemrograman Piranti Bergerak, Informatika, Universitas Mulawarman.

## Tentang Aplikasi

Insap adalah aplikasi pencatat keuangan pribadi yang dirancang khusus untuk mahasiswa dengan mengadaptasi metode refleksi Kakeibo. Insap berfokus pada pembentukan kebiasaan sadar finansial secara bertahap dan menempatkan pengguna sebagai pengendali utama keuangannya.

### Masalah yang Diselesaikan

1. Pengeluaran mahasiswa didominasi oleh transaksi bernominal kecil tetapi frekuensinya sering (jajan daring, transportasi, top up game, dan patungan kos) sehingga sulit diingat pada akhir bulan.
2. Proses pencatatan manual terasa merepotkan dan melelahkan, membuat kebiasaan mencatat sering terhenti hanya dalam beberapa hari.
3. Aplikasi keuangan yang tersedia di pasaran umumnya hanya berfokus pada rekapitulasi angka tanpa membantu mendorong perubahan perilaku nyata penggunanya.
4. Aplikasi sejenis kebanyakan berbahasa Inggris atau bernuansa korporat, tidak menggunakan kategori maupun gaya bahasa yang dekat dengan keseharian mahasiswa Indonesia.

### Sasaran Pengguna

- **Target utama:** Mahasiswa (rentang usia 18 sampai 25 tahun), baik mahasiswa yang menerima uang kiriman bulanan dari orang tua maupun mahasiswa indekos yang memiliki penghasilan tambahan dan mengelola pengeluaran bersama atau patungan.
- **Bukan target pengguna:** Pelaku usaha yang membutuhkan sistem akuntansi ganda atau perpajakan, karyawan yang memerlukan sistem penggantian biaya kantor (reimbursement), serta pengguna yang menginginkan integrasi otomatis dengan rekening perbankan.

## Fitur dan Status

Pengembangan aplikasi Insap dilakukan secara bertahap per versi sesuai dengan jadwal dan kriteria selesai pada dokumen ROADMAP.

### v0.1 Fondasi

| Kode | Nama Fitur | Keterangan singkat | Pemilik | Status |
|---|---|---|---|---|
| F-01 | Input transaksi manual | Form isian jumlah, kategori, tanggal, catatan singkat | Riyadi | selesai |
| F-02 | Riwayat transaksi | Daftar transaksi yang dapat disaring per tanggal dan kategori | Dafa | sedang dikerjakan |
| F-03 | Kategori khas mahasiswa | Sembilan kategori bawaan, lihat KATEGORI.md | Luthfi | sebagian |
| F-04 | Penyimpanan lokal | Seluruh data tersimpan di perangkat menggunakan SQLite | Riyadi | selesai |
| F-05 | Ringkasan periodik | Total pengeluaran per kategori untuk rentang mingguan dan bulanan | Riyadi | sebagian |
| F-06 | Format Rupiah | Penulisan mata uang yang benar, misalnya Rp15.000 | Riyadi | selesai |
| F-16 | Perkenalan dan keadaan kosong | Layar sambutan tiga langkah dan tampilan saat belum ada data | Luthfi | sebagian |

### v0.2 Pembeda

| Kode | Nama Fitur | Keterangan singkat | Pemilik | Status |
|---|---|---|---|---|
| F-07 | Tanya niat belanja | Pertanyaan "butuh atau pengen" untuk kategori opsional dan hiburan | Luthfi | belum dimulai |
| F-08 | Refleksi mingguan | Ritual akhir pekan: rencana versus realisasi, plus catatan perbaikan | Luthfi | belum dimulai |

### v0.3 Kecerdasan

| Kode | Nama Fitur | Keterangan singkat | Pemilik | Status |
|---|---|---|---|---|
| F-09 | Pindai struk | Foto struk dikirim ke Gemini untuk diekstrak toko, tanggal, total | Dafa | belum dimulai |
| F-10 | Konfirmasi hasil pindai | Hasil AI ditampilkan sebagai draf yang wajib disetujui pengguna | Dafa | belum dimulai |
| F-11 | Kuota pindai gratis | Pembatasan sepuluh pemindaian per minggu untuk pengguna gratis | Dafa | belum dimulai |

### v0.4 Pemantapan

| Kode | Nama Fitur | Keterangan singkat | Pemilik | Status |
|---|---|---|---|---|
| F-14 | Ekspor laporan | Unduh rekap bulanan dalam bentuk berkas PDF | - | belum dimulai |

### v1.0 Rilis

| Kode | Nama Fitur | Keterangan singkat | Pemilik | Status |
|---|---|---|---|---|
| F-12 | Laporan AI bulanan | Ringkasan naratif berbahasa santai tentang pola belanja sebulan | - | belum dimulai |

### Fitur Bersyarat

Fitur-fitur ini baru akan dikerjakan apabila gerbang mutu pada akhir Pertemuan 13 terpenuhi; jika tidak terpenuhi, fitur F-17 dan F-13 diganti dengan mekanisme ekspor dan impor cadangan berkas manual tanpa akun, sedangkan fitur F-18 dan F-15 tidak diimplementasikan dengan kuota gratis sepuluh pindaian per minggu berlaku untuk semua pengguna.

| Kode | Nama Fitur | Keterangan singkat | Pemilik | Status |
|---|---|---|---|---|
| F-17 | Masuk dengan akun Google | Firebase Auth, prasyarat wajib bagi F-13 | - | belum dimulai |
| F-13 | Cadangan awan | Sinkronisasi ke Firestore, bergantung pada F-17 | - | belum dimulai |
| F-18 | Langganan premium | Penagihan lewat Google Play Billing, bergantung pada F-17 | - | belum dimulai |
| F-15 | Pindai tanpa batas | Menghapus kuota mingguan bagi pelanggan, bergantung pada F-18 | - | belum dimulai |

## Teknologi

Aplikasi ini dibangun menggunakan tumpukan teknologi berikut:

- **Kerangka Kerja:** Flutter (Dart SDK `^3.13.1`)
- **Arsitektur:** Clean Architecture dengan pendekatan *feature-first*
- **Manajemen State:** `flutter_bloc` (`^9.1.1`) menggunakan pola Cubit
- **Injeksi Dependensi:** `get_it` (`^9.3.0`) sebagai penyedia layanan (*service locator*)
- **Navigasi:** `go_router` (`^18.0.1`) dengan dukungan `StatefulShellRoute`
- **Basis Data Lokal:** SQLite melalui pustaka `sqflite` (`^2.4.4`) dan `path` (`^1.9.1`)
- **Pustaka Pendukung:** `equatable` (`^3.0.0`) untuk perbandingan objek state dan `google_fonts` (`^8.2.1`) untuk tipografi

## Cara Menjalankan

> **CATATAN PENTING: Aplikasi HANYA jalan di Android (emulator atau HP fisik). Chrome, Edge, dan Windows tidak didukung karena sqflite tidak berjalan di sana.**

Ikuti langkah-langkah berikut untuk menjalankan aplikasi:

1. Unduh seluruh dependensi proyek:
   ```bash
   flutter pub get
   ```
2. Nyalakan emulator Android melalui Android Studio, atau hubungkan HP Android ke komputer dengan mengaktifkan mode *USB Debugging*.
3. Periksa perangkat yang terhubung dan catat ID perangkat target:
   ```bash
   flutter devices
   ```
4. Jalankan aplikasi ke perangkat Android yang dipilih:
   ```bash
   flutter run -d <id-perangkat>
   ```

## Struktur Folder

Struktur folder utama di dalam direktori `lib/` disusun sebagai berikut:

- `lib/core/`: Fondasi aplikasi lintas fitur yang mencakup tema, basis data lokal, navigasi, injeksi dependensi, utilitas, dan widget global.
  - `lib/core/bloc/`: Pengamat (*observer*) global untuk memantau perubahan state Cubit.
  - `lib/core/database/`: Pengelola SQLite (DatabaseHelper), model tabel, dan data awal (*seeding*).
  - `lib/core/di/`: Konfigurasi pendaftaran injeksi dependensi menggunakan get_it.
  - `lib/core/router/`: Konfigurasi rute navigasi dan tata letak utama (AppShell) menggunakan go_router.
  - `lib/core/utils/`: Fungsi pembantu umum seperti ekstensi format mata uang Rupiah dan penanggalan pekan ISO.
  - `lib/core/widgets/`: Komponen antarmuka yang dapat digunakan bersama di berbagai fitur.
- `lib/features/`: Modul fungsionalitas aplikasi yang masing-masing dipisahkan per fitur.
  - `lib/features/beranda/`: Antarmuka layar utama serta Cubit ringkasan pengeluaran mingguan dan status kuota.
  - `lib/features/transaksi/`: Lapisan data, domain (use case), dan presentasi untuk form catat transaksi serta riwayat transaksi.
  - `lib/features/kategori/`: Lapisan data, domain, dan presentasi untuk pengelolaan kategori pengeluaran.
  - `lib/features/perkenalan/`: Antarmuka alur perkenalan awal (*onboarding*) untuk pengguna baru.
  - `lib/features/refleksi/`: Antarmuka dan alur evaluasi pengeluaran mingguan berbasis metode Kakeibo.

## Alur Kerja Tim

Sesuai aturan di `ATURAN-GIT.md`:

- **Satu branch per ISSUE:** Setiap pekerjaan dikerjakan pada branch terpisah dengan format `feat/issue-XX-nama-fitur`.
- **Dilarang push langsung ke main:** Semua anggota tim dilarang melakukan push langsung ke branch `main`.
- **Wajib melalui Pull Request:** Integrasi kode ke branch `main` hanya dapat dilakukan melalui Pull Request yang telah ditinjau oleh Project Manager (Riyadi).
- **Kerapian kode dan uji otomatis:** Sebelum membuka Pull Request, pengembang wajib memastikan perintah `flutter analyze` dan `flutter test` berjalan bersih tanpa galat.
- **Peta kepemilikan berkas:** Setiap pengembang hanya boleh mengubah berkas yang menjadi tanggung jawabnya sesuai tabel kepemilikan berkas guna menghindari konflik Git.

## Dokumen Perencanaan

Dokumen perencanaan teknis dan produk (PRD, ROADMAP, dan berkas ISSUE) dikelola pada repositori terpisah bernama `insap-docs` yang dapat diakses pada tautan berikut:

- Repositori Dokumen: [https://github.com/riyadiambis/insap-docs.git](https://github.com/riyadiambis/insap-docs.git)

Di lingkungan lokal pengembang, repositori tersebut di-clone ke dalam direktori `docs/` dan secara otomatis diabaikan oleh `.gitignore` pada repositori kode aplikasi.
