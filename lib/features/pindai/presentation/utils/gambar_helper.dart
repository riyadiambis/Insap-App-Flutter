import 'dart:io';
import 'dart:ui' as ui;

/// Helper untuk mengecilkan citra struk menggunakan dart:ui bawaan Flutter tanpa paket tambahan (Keputusan 4, ISSUE-10).
class GambarHelper {
  static const int batasMaksimalPiksel = 1024;

  /// Mengecilkan citra jika sisi terpanjang melebihi 1024px
  static Future<String> kompresDanKecilkanCitra(String pathAsli) async {
    final fileAsli = File(pathAsli);
    if (!await fileAsli.exists()) {
      return pathAsli;
    }

    final bytesAsli = await fileAsli.readAsBytes();

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytesAsli);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    final lebarAsli = descriptor.width;
    final tinggiAsli = descriptor.height;

    // Jika ukuran sudah di bawah atau sama dengan 1024px, gunakan berkas asli
    if (lebarAsli <= batasMaksimalPiksel && tinggiAsli <= batasMaksimalPiksel) {
      return pathAsli;
    }

    int? targetWidth;
    int? targetHeight;

    if (lebarAsli >= tinggiAsli) {
      targetWidth = batasMaksimalPiksel;
    } else {
      targetHeight = batasMaksimalPiksel;
    }

    final codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return pathAsli;
    }

    final pngBytes = byteData.buffer.asUint8List();
    final pathTerkecil = '${pathAsli}_1024.png';
    final fileTerkecil = File(pathTerkecil);
    await fileTerkecil.writeAsBytes(pngBytes);

    return fileTerkecil.path;
  }
}
