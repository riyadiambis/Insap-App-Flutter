# Panduan Kontribusi

Terima kasih sudah tertarik dengan Insap. Repo ini dikelola oleh Ofisharu Labs. Kode bersifat publik untuk dilihat, tetapi tidak berlisensi terbuka (lihat [LICENSE](LICENSE)), jadi setiap kontribusi yang diterima menjadi bagian dari produk Ofisharu Labs.

## Melapor bug atau mengusulkan fitur

Buka issue baru dan pilih templat **Laporan bug** atau **Usulan fitur**. Sertakan versi aplikasi, perangkat, dan langkah yang bisa diulang. Celah keamanan jangan dilaporkan lewat issue publik, ikuti [SECURITY.md](SECURITY.md).

## Alur kerja

1. Buat branch dari `main` dengan pola `feat/issue-NN-ringkas`, `fix/issue-NN-ringkas`, atau `docs/...`.
2. Jalankan sebelum membuka PR:
   ```bash
   flutter analyze
   flutter test
   ```
3. Buka pull request ke `main` dan isi templatnya. Jangan push langsung ke `main`.
4. PR digabung oleh pengelola setelah CI hijau dan ditinjau.

## Gaya

- Kode mengikuti `analysis_options.yaml` (`flutter_lints`) dan struktur fitur yang ada: `data`, `domain`, `presentation` per fitur, state dengan Cubit.
- Nama berkas, kelas, dan teks antarmuka memakai bahasa Indonesia, sesuai kode yang sudah ada.
- Pesan commit singkat dengan awalan `feat:`, `fix:`, `docs:`, `chore:`, atau `test:`.
- Jangan pernah meng-commit `.env`, `key.properties`, keystore, atau kunci API.
