import '../../../../core/network/gemini_client.dart';
import '../../domain/entities/barang_pindai.dart';
import '../../domain/entities/hasil_pindai_entity.dart';
import '../../presentation/utils/cocokkan_kategori.dart';

const Map<String, int> _defaultKategoriIdMap = {
  'makan': 1,
  'transport': 2,
  'kos': 3,
  'kuliah': 4,
  'jajan daring': 5,
  'nongkrong': 6,
  'top up': 7,
  'darurat': 8,
  'lainnya': 9,
};

/// Model data untuk memetakan balasan JSON dari Gemini API ke entitas domain (GEMINI-CONTRACT.md).
class HasilPindaiModel extends HasilPindaiEntity {
  const HasilPindaiModel({
    required super.adalahStruk,
    super.namaToko,
    super.tanggal,
    super.total,
    super.kategoriUsulan,
    required super.keyakinan,
    super.barang = const [],
    super.totalDihitungDariBarang = false,
  });

  /// Factory untuk memetakan Map JSON dari Gemini API secara aman sesuai GEMINI-CONTRACT.md (F-10).
  factory HasilPindaiModel.fromJson(
    Map<String, dynamic> json, {
    List<String> daftarKategori = const [],
    Map<String, int>? petaKategoriId,
  }) {
    // 1. Parsing adalah_struk (wajib boolean, No 15)
    final rawStruk = json['adalah_struk'];
    if (rawStruk is! bool) {
      throw const GeminiException('Gagal membaca struk, coba lagi');
    }
    final bool adalahStruk = rawStruk;

    // Jika bukan struk, kembalikan entitas kosong
    if (!adalahStruk) {
      return const HasilPindaiModel(
        adalahStruk: false,
        keyakinan: 0.0,
        barang: [],
      );
    }

    // 2. Parsing nama_toko
    String? namaToko;
    final rawToko = json['nama_toko'];
    if (rawToko is String && rawToko.trim().isNotEmpty) {
      namaToko = rawToko.trim();
    }

    // 3. Parsing tanggal (format YYYY-MM-DD)
    String? tanggal;
    final rawTanggal = json['tanggal'];
    if (rawTanggal is String && rawTanggal.trim().isNotEmpty) {
      tanggal = rawTanggal.trim();
    }

    // 4. Parsing total nominal
    int? total;
    final rawTotal = json['total'];
    if (rawTotal is int) {
      total = rawTotal;
    } else if (rawTotal is num) {
      total = rawTotal.toInt();
    } else if (rawTotal is String) {
      final angkaSaja = rawTotal.replaceAll(RegExp(r'[^\d]'), '');
      total = int.tryParse(angkaSaja);
    }

    // 5. Parsing kategori_usulan
    String? kategoriUsulan;
    final rawKategori = json['kategori_usulan'];
    if (rawKategori is String && rawKategori.trim().isNotEmpty) {
      kategoriUsulan = rawKategori.trim().toLowerCase();
    }

    // 6. Parsing keyakinan (angka 0.0 sampai 1.0)
    double keyakinan = 0.0;
    final rawKeyakinan = json['keyakinan'];
    if (rawKeyakinan is num) {
      keyakinan = rawKeyakinan.toDouble();
    } else if (rawKeyakinan is String) {
      keyakinan = double.tryParse(rawKeyakinan.trim()) ?? 0.0;
    }

    // 7. Parsing rincian barang per baris (Tahap 2B)
    final List<BarangPindai> barangList = [];
    bool totalDihitungDariBarang = false;

    int cariKategoriId(String? namaKategori) {
      final cocok = cocokkanKategori(namaKategori, daftarKategori);
      if (petaKategoriId != null && petaKategoriId.containsKey(cocok)) {
        return petaKategoriId[cocok]!;
      }
      return _defaultKategoriIdMap[cocok] ?? 9;
    }

    final rawBarang = json['barang'];
    if (rawBarang is List && rawBarang.isNotEmpty) {
      for (final item in rawBarang) {
        if (item is Map<String, dynamic>) {
          final nama = (item['nama'] as String?)?.trim() ?? 'Barang';
          int harga = 0;
          final rawHarga = item['harga'];
          if (rawHarga is int) {
            harga = rawHarga;
          } else if (rawHarga is num) {
            harga = rawHarga.toInt();
          } else if (rawHarga is String) {
            harga =
                int.tryParse(rawHarga.replaceAll(RegExp(r'[^\d-]'), '')) ?? 0;
          }
          final kategoriNama = item['kategori'] as String?;
          final katId = cariKategoriId(kategoriNama);

          barangList.add(
            BarangPindai(
              nama: nama.isEmpty ? 'Barang' : nama,
              harga: harga,
              kategoriId: katId,
              dicentang: true,
              adalahSelisih: false,
            ),
          );
        }
      }
    }

    if (barangList.isEmpty) {
      // "barang" null atau kosong -> satu baris "Total struk", harga = total, kategori = kategori_usulan
      final katId = cariKategoriId(kategoriUsulan);
      barangList.add(
        BarangPindai(
          nama: 'Total struk',
          harga: total ?? 0,
          kategoriId: katId,
          dicentang: true,
          adalahSelisih: false,
        ),
      );
    } else {
      // Penjumlahan SELALU di kode Dart (fold), tidak dipercayakan ke model
      final int totalHargaBarang =
          barangList.fold<int>(0, (sum, b) => sum + b.harga);

      if (total == null) {
        // total null tapi barang ada -> total = jumlah harga barang, tampilkan peringatan halus
        total = totalHargaBarang;
        totalDihitungDariBarang = true;
      } else {
        final selisih = total - totalHargaBarang;
        if (selisih != 0) {
          // Cari kategori kelompok dengan subtotal terbesar saat diurai
          final Map<int, int> subtotalPerKat = {};
          for (final b in barangList) {
            subtotalPerKat[b.kategoriId] =
                (subtotalPerKat[b.kategoriId] ?? 0) + b.harga;
          }

          int kategoriIdTerbesar = barangList.first.kategoriId;
          int maxSubtotal = -1 << 31;
          for (final entry in subtotalPerKat.entries) {
            if (entry.value > maxSubtotal) {
              maxSubtotal = entry.value;
              kategoriIdTerbesar = entry.key;
            }
          }

          barangList.add(
            BarangPindai(
              nama: 'Pajak/diskon/pembulatan',
              harga: selisih,
              kategoriId: kategoriIdTerbesar,
              dicentang: true,
              adalahSelisih: true,
            ),
          );
        }
      }
    }

    return HasilPindaiModel(
      adalahStruk: adalahStruk,
      namaToko: namaToko,
      tanggal: tanggal,
      total: total,
      kategoriUsulan: kategoriUsulan,
      keyakinan: keyakinan.clamp(0.0, 1.0),
      barang: barangList,
      totalDihitungDariBarang: totalDihitungDariBarang,
    );
  }

  /// Mengonversi model ke Map JSON
  Map<String, dynamic> toJson() {
    return {
      'adalah_struk': adalahStruk,
      'nama_toko': namaToko,
      'tanggal': tanggal,
      'total': total,
      'kategori_usulan': kategoriUsulan,
      'keyakinan': keyakinan,
      'barang': barang
          .map((b) => {
                'nama': b.nama,
                'harga': b.harga,
                'kategori_id': b.kategoriId,
                'dicentang': b.dicentang,
                'adalah_selisih': b.adalahSelisih,
              })
          .toList(),
      'total_dihitung_dari_barang': totalDihitungDariBarang,
    };
  }
}
