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

// format yyyy-MM-dd doang, tanpa jam. jangan pakai toIso8601String()
// mentah, nanti kebawa jam dan bikin BETWEEN meleset (Jebakan 1, ISSUE-02)
String formatTanggalIso(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

const List<String> _namaBulanSingkat = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Memformat rentang tanggal pekan ISO menjadi teks singkat bahasa Indonesia.
///
/// Contoh:
/// - Beda bulan: "28 Sep - 4 Okt"
/// - Sebulan: "5 - 11 Okt"
String formatRentangTanggal(DateTime awal, DateTime akhir) {
  final namaBulanAwal = _namaBulanSingkat[awal.month];
  final namaBulanAkhir = _namaBulanSingkat[akhir.month];

  if (awal.month == akhir.month && awal.year == akhir.year) {
    return '${awal.day} - ${akhir.day} $namaBulanAkhir';
  } else {
    return '${awal.day} $namaBulanAwal - ${akhir.day} $namaBulanAkhir';
  }
}

/// Helper untuk memformat objek [RentangMinggu].
String formatRentangMinggu(RentangMinggu rentang) {
  return formatRentangTanggal(rentang.awal, rentang.akhir);
}

