import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:insap/features/pindai/presentation/utils/gambar_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mengukur ukuran berkas PNG hasil pengecilan 1024 piksel untuk ../uji-pindai/lurus.jpeg', () async {
    const pathUji = '../uji-pindai/lurus.jpeg';
    final fileUji = File(pathUji);

    if (await fileUji.exists()) {
      final ukuranAsliByte = await fileUji.length();
      final ukuranAsliKb = ukuranAsliByte / 1024.0;
      final pathHasil = await GambarHelper.kompresDanKecilkanCitra(pathUji);
      final fileHasil = File(pathHasil);
      final ukuranHasilByte = await fileHasil.length();
      final ukuranHasilKb = ukuranHasilByte / 1024.0;

      // Cetak informasi untuk laporan
      // ignore: avoid_print
      print('=== HASIL DIAGNOSTIK PENULISAN CITRA PNG 1024px ===');
      // ignore: avoid_print
      print('Berkas Asli: $pathUji');
      // ignore: avoid_print
      print('Ukuran Asli: ${ukuranAsliByte} byte (${ukuranAsliKb.toStringAsFixed(2)} KB)');
      // ignore: avoid_print
      print('Berkas Hasil: $pathHasil');
      // ignore: avoid_print
      print('Ukuran Hasil PNG 1024px: ${ukuranHasilByte} byte (${ukuranHasilKb.toStringAsFixed(2)} KB)');
      // ignore: avoid_print
      print('====================================================');

      // Hapus berkas sementara hasil uji
      await GambarHelper.hapusBerkasSementara(pathHasil);
      expect(ukuranHasilByte, greaterThan(0));
    } else {
      // ignore: avoid_print
      print('Berkas ../uji-pindai/lurus.jpeg tidak ditemukan');
    }
  });
}
