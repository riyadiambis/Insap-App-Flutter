import 'package:flutter/widgets.dart';

/// Kunci widget yang disorot petunjuk. Dipasang di beranda, navigasi bawah,
/// dan header, lalu dibaca lapisan petunjuk buat cari posisinya di layar.
class KunciTur {
  static final catatCepat = GlobalKey(debugLabel: 'tur_catat_cepat');
  static final pindaiStruk = GlobalKey(debugLabel: 'tur_pindai_struk');
  static final tabRefleksi = GlobalKey(debugLabel: 'tur_tab_refleksi');
  static final tabRiwayat = GlobalKey(debugLabel: 'tur_tab_riwayat');
  static final akun = GlobalKey(debugLabel: 'tur_akun');
}

class LangkahTur {
  final GlobalKey kunci;
  final String judul;
  final String isi;

  const LangkahTur({
    required this.kunci,
    required this.judul,
    required this.isi,
  });
}

/// Urutan petunjuk. Langkah terakhir selalu soal akun.
final List<LangkahTur> daftarLangkahTur = [
  LangkahTur(
    kunci: KunciTur.catatCepat,
    judul: 'Catat pengeluaran di sini',
    isi: 'Ketuk Catat Cepat, isi nominal, pilih kategori, lalu simpan. Selesai dalam hitungan detik.',
  ),
  LangkahTur(
    kunci: KunciTur.pindaiStruk,
    judul: 'Malas mengetik? Foto struknya',
    isi: 'AI membaca tiap barang di struk. Kamu cukup periksa lalu simpan. Ada kuota gratis tiap pekan.',
  ),
  LangkahTur(
    kunci: KunciTur.tabRefleksi,
    judul: 'Renungkan tiap akhir pekan',
    isi: 'Lihat ke mana uangmu pergi pekan ini, lalu tulis satu hal yang mau diperbaiki.',
  ),
  LangkahTur(
    kunci: KunciTur.tabRiwayat,
    judul: 'Semua catatan ada di sini',
    isi: 'Cari dan saring catatanmu kapan saja. Ketuk satu catatan untuk melihat rinciannya.',
  ),
  LangkahTur(
    kunci: KunciTur.akun,
    judul: 'Daftar akun biar datamu aman',
    isi: 'Catatanmu sekarang hanya tersimpan di HP ini. Daftar akun gratis supaya bisa dicadangkan dan dipulihkan kalau ganti HP.',
  ),
];

/// Teks langkah akun kalau pengguna ternyata sudah masuk.
const String judulAkunSudahMasuk = 'Akunmu ada di sini';
const String isiAkunSudahMasuk =
    'Buka untuk mencadangkan atau memulihkan catatanmu kapan saja.';
