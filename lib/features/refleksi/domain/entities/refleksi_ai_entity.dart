import 'package:equatable/equatable.dart';

/// Ringkasan agregat per kategori untuk dikirim ke Gemini AI.
/// Sengaja tidak memuat nama barang, catatan, nama toko, atau data pribadi.
class AgregatKategoriAi extends Equatable {
  final String nama;
  final int totalPekanIni;
  final int totalPekanLalu;
  final int jumlahTransaksi;

  const AgregatKategoriAi({
    required this.nama,
    required this.totalPekanIni,
    required this.totalPekanLalu,
    required this.jumlahTransaksi,
  });

  Map<String, dynamic> toPayloadMap() {
    return {
      'nama': nama,
      'total_pekan_ini': totalPekanIni,
      'total_pekan_lalu': totalPekanLalu,
      'jumlah_transaksi': jumlahTransaksi,
    };
  }

  @override
  List<Object?> get props => [
    nama,
    totalPekanIni,
    totalPekanLalu,
    jumlahTransaksi,
  ];
}

/// Payload ringkasan pekan untuk permintaan refleksi AI.
class RingkasanRefleksiAiInput extends Equatable {
  final String rentangPekan;
  final String tanggalSeninIso;
  final int totalPekanIni;
  final int? targetPekanan;
  final int totalPekanLalu;
  final List<AgregatKategoriAi> daftarKategori;

  const RingkasanRefleksiAiInput({
    required this.rentangPekan,
    required this.tanggalSeninIso,
    required this.totalPekanIni,
    this.targetPekanan,
    required this.totalPekanLalu,
    required this.daftarKategori,
  });

  Map<String, dynamic> toPayloadMap() {
    return {
      'rentang_pekan': rentangPekan,
      'total_pekan_ini': totalPekanIni,
      'target_pekanan': targetPekanan,
      'total_pekan_lalu': totalPekanLalu,
      'kategori': daftarKategori.map((k) => k.toPayloadMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    rentangPekan,
    tanggalSeninIso,
    totalPekanIni,
    targetPekanan,
    totalPekanLalu,
    daftarKategori,
  ];
}

/// Satu butir saran mentah yang dikembalikan oleh Gemini AI.
class SaranRefleksiAi extends Equatable {
  final String kategori;
  final String teks;

  const SaranRefleksiAi({required this.kategori, required this.teks});

  @override
  List<Object?> get props => [kategori, teks];
}

/// Butir saran AI yang sudah dipasangkan dengan metadata ikon & warna kategori lokal.
/// Bila kategori tidak dikenal atau umum, [ikon] dan [warna] bernilai null (ikon umum).
class SaranRefleksiItem extends Equatable {
  final String kategori;
  final String teks;
  final String? ikon;
  final String? warna;

  const SaranRefleksiItem({
    required this.kategori,
    required this.teks,
    this.ikon,
    this.warna,
  });

  @override
  List<Object?> get props => [kategori, teks, ikon, warna];
}

/// Hasil evaluasi lokal hemat vs boncos untuk kartu atas halaman hasil refleksi.
class EvaluasiHematBoncos extends Equatable {
  final bool hemat;
  final bool pakaiTarget;
  final int selisih;
  final int? pembanding;

  const EvaluasiHematBoncos({
    required this.hemat,
    required this.pakaiTarget,
    required this.selisih,
    this.pembanding,
  });

  /// Menghitung status hemat/boncos secara lokal.
  /// Menggunakan target pekanan `(targetBulanan / 4).round()` seperti Beranda.
  /// Bila belum ada target bulanan, membandingkan terhadap total pekan lalu.
  factory EvaluasiHematBoncos.hitung({
    required int totalPekanIni,
    int? targetBulanan,
    required int totalPekanLalu,
  }) {
    final int? targetPekanan = (targetBulanan != null && targetBulanan > 0)
        ? (targetBulanan / 4).round()
        : null;

    if (targetPekanan != null && targetPekanan > 0) {
      final int selisih = totalPekanIni - targetPekanan;
      return EvaluasiHematBoncos(
        hemat: selisih <= 0,
        pakaiTarget: true,
        selisih: selisih,
        pembanding: targetPekanan,
      );
    }

    if (totalPekanLalu > 0) {
      final int selisih = totalPekanIni - totalPekanLalu;
      return EvaluasiHematBoncos(
        hemat: selisih <= 0,
        pakaiTarget: false,
        selisih: selisih,
        pembanding: totalPekanLalu,
      );
    }

    return const EvaluasiHematBoncos(
      hemat: true,
      pakaiTarget: false,
      selisih: 0,
      pembanding: null,
    );
  }

  @override
  List<Object?> get props => [hemat, pakaiTarget, selisih, pembanding];
}

/// Hasil lengkap refleksi pekan ini untuk ditampilkan pada halaman hasil.
class HasilRefleksiAi extends Equatable {
  final String rentangPekan;
  final EvaluasiHematBoncos evaluasi;
  final List<SaranRefleksiItem> saran;

  const HasilRefleksiAi({
    required this.rentangPekan,
    required this.evaluasi,
    required this.saran,
  });

  @override
  List<Object?> get props => [rentangPekan, evaluasi, saran];
}
