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
