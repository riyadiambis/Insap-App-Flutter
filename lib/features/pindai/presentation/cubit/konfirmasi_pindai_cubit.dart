import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transaksi/domain/entities/transaksi_entity.dart';
import '../../domain/entities/barang_pindai.dart';
import '../../domain/entities/hasil_pindai_entity.dart';
import '../../domain/usecases/simpan_transaksi_pindai.dart';
import 'konfirmasi_pindai_state.dart';

/// Cubit pengelola logika layar konfirmasi multi-barang pemindaian struk (F-10, Tahap 2C).
class KonfirmasiPindaiCubit extends Cubit<KonfirmasiPindaiState> {
  final SimpanTransaksiPindai simpanTransaksiPindai;

  KonfirmasiPindaiCubit({
    required this.simpanTransaksiPindai,
    required HasilPindaiEntity hasilPindai,
  }) : super(
          KonfirmasiPindaiState(
            daftarBarang: List<BarangPindai>.from(hasilPindai.barang),
            namaToko: hasilPindai.namaToko ?? '',
            tanggal: hasilPindai.tanggal ??
                DateTime.now().toIso8601String().substring(0, 10),
            totalStruk: hasilPindai.total ?? 0,
            keyakinan: hasilPindai.keyakinan,
            totalDihitungDariBarang: hasilPindai.totalDihitungDariBarang,
          ),
        );

  /// Mengubah centang pada barang berdasarkan indeks aslinya di daftarBarang
  void centang(int index, bool dicentang) {
    if (index < 0 || index >= state.daftarBarang.length) return;
    final listBaru = List<BarangPindai>.from(state.daftarBarang);
    listBaru[index] = listBaru[index].copyWith(dicentang: dicentang);
    emit(state.copyWith(daftarBarang: listBaru));
  }

  /// Mengubah harga barang pada indeks tertentu
  void ubahHarga(int index, int hargaBaru) {
    if (index < 0 || index >= state.daftarBarang.length) return;
    final listBaru = List<BarangPindai>.from(state.daftarBarang);
    listBaru[index] = listBaru[index].copyWith(harga: hargaBaru);
    emit(state.copyWith(daftarBarang: listBaru));
  }

  /// Mengubah kategori barang pada indeks tertentu (memindahkan barang ke kelompok baru)
  void ubahKategori(int index, int kategoriIdBaru) {
    if (index < 0 || index >= state.daftarBarang.length) return;
    final listBaru = List<BarangPindai>.from(state.daftarBarang);
    listBaru[index] = listBaru[index].copyWith(kategoriId: kategoriIdBaru);
    emit(state.copyWith(daftarBarang: listBaru));
  }

  /// Mengubah pilihan Butuh/Pengen untuk suatu kategori
  void ubahTipeKebutuhan(int kategoriId, String? tipe) {
    final mapBaru = Map<int, String>.from(state.tipeKebutuhan);
    if (tipe == null || tipe.isEmpty) {
      mapBaru.remove(kategoriId);
    } else {
      mapBaru[kategoriId] = tipe;
    }
    emit(state.copyWith(tipeKebutuhan: mapBaru));
  }

  /// Mengubah nama toko
  void ubahNamaToko(String nama) {
    emit(state.copyWith(namaToko: nama.trim()));
  }

  /// Mengubah tanggal transaksi
  void ubahTanggal(String tanggal) {
    emit(state.copyWith(tanggal: tanggal.trim()));
  }

  /// Menampilkan semua barang tanpa batasan 10 baris
  void tampilkanSemuaBarang() {
    emit(state.copyWith(tampilkanSemua: true));
  }

  /// Menyimpan seluruh kelompok barang tercentang sebagai transaksi-transaksi atomik (Tahap 2D)
  Future<bool> simpanSemua() async {
    if (!state.bolehSimpan) return false;

    emit(state.copyWith(status: KonfirmasiPindaiStatus.menyimpan));

    try {
      final List<TransaksiEntity> daftarTrx = [];
      final sekarang = DateTime.now().toIso8601String();

      for (final kelompok in state.kelompokList) {
        // Ambil barang yang dicentang di kelompok ini
        final barangDicentang =
            kelompok.items.where((b) => b.dicentang).toList();
        if (barangDicentang.isEmpty || kelompok.subtotal <= 0) continue;

        // Catatan adalah nama barang dipisah koma tanpa baris selisih, dipotong 100 karakter
        final nonSelisih = barangDicentang
            .where((b) => !b.adalahSelisih)
            .map((b) => b.nama)
            .join(', ');

        String catatan = nonSelisih.isNotEmpty ? nonSelisih : 'Total struk';
        if (catatan.length > 100) {
          catatan = catatan.substring(0, 100);
        }

        final trx = TransaksiEntity(
          jumlah: kelompok.subtotal,
          kategoriId: kelompok.kategoriId,
          tanggal: state.tanggal,
          catatan: catatan,
          tipeKebutuhan: state.tipeKebutuhan[kelompok.kategoriId],
          sumber: 'pindai',
          namaToko: state.namaToko.isEmpty ? null : state.namaToko,
          dibuatPada: sekarang,
        );

        daftarTrx.add(trx);
      }

      if (daftarTrx.isEmpty) {
        emit(
          state.copyWith(
            status: KonfirmasiPindaiStatus.gagal,
            pesanGalat: 'Tidak ada transaksi yang dapat disimpan',
          ),
        );
        return false;
      }

      await simpanTransaksiPindai(daftarTrx);

      emit(
        state.copyWith(
          status: KonfirmasiPindaiStatus.sukses,
          jumlahTransaksiTersimpan: daftarTrx.length,
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: KonfirmasiPindaiStatus.gagal,
          pesanGalat: 'Gagal menyimpan transaksi: $e',
        ),
      );
      return false;
    }
  }
}
