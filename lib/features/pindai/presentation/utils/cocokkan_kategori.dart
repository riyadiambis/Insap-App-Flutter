/// Mencocokkan nama usulan kategori dari Gemini dengan daftar nama kategori aktif (No 14).
/// Pencocokan sama persis setelah trim dan huruf kecil.
/// Bila tidak ada yang sama persis, mengembalikan 'lainnya'.
String cocokkanKategori(String? nama, List<String> daftar) {
  if (nama == null || nama.trim().isEmpty) {
    return 'lainnya';
  }

  final normalized = nama.trim().toLowerCase();

  for (final item in daftar) {
    if (item.trim().toLowerCase() == normalized) {
      return item.trim().toLowerCase();
    }
  }

  return 'lainnya';
}
