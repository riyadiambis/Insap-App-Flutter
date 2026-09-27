class RentangMinggu {
  final DateTime awal;
  final DateTime akhir;

  const RentangMinggu({required this.awal, required this.akhir});
}

int isoWeekNumber(DateTime date) {
  // Normalize date to its Thursday
  int day = date.weekday;
  DateTime thursday = DateTime(date.year, date.month, date.day).add(Duration(days: 4 - day));
  
  // First Thursday of the year
  DateTime firstThursday = DateTime(thursday.year, 1, 4);
  int firstDayWeekday = firstThursday.weekday;
  firstThursday = firstThursday.add(Duration(days: 4 - firstDayWeekday));
  
  // Calculate difference
  int daysDifference = thursday.difference(firstThursday).inDays;
  return (daysDifference ~/ 7) + 1;
}

RentangMinggu rentangMingguIso(DateTime date) {
  int day = date.weekday; // 1 = Monday, 7 = Sunday
  DateTime awal = DateTime(date.year, date.month, date.day).subtract(Duration(days: day - 1));
  // 6 days later, at 23:59:59.999
  DateTime akhir = DateTime(awal.year, awal.month, awal.day, 23, 59, 59, 999).add(const Duration(days: 6));
  return RentangMinggu(awal: awal, akhir: akhir);
}

/// Format bagian tanggal saja, `yyyy-MM-dd`, tanpa jam. Kolom `tanggal` di
/// tabel `transaksi` disimpan dalam format ini (lihat SCHEMA.sql), jadi
/// rentang dari [rentangMingguIso] harus diformat lewat fungsi ini sebelum
/// dikirim ke repository. Memakai `toIso8601String()` mentah akan
/// menyisipkan jam dan membuat perbandingan BETWEEN meleset (Jebakan 1,
/// ISSUE-02).
String formatTanggalIso(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
