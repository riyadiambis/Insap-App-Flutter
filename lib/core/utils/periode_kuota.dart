/// Menghitung tanggal Senin pekan berjalan dalam format ISO (`yyyy-MM-dd`).
String hitungSeninPeriodeKuotaIso(DateTime sekarang) {
  final seninPekanIni = sekarang.subtract(Duration(days: sekarang.weekday - 1));
  return '${seninPekanIni.year.toString().padLeft(4, '0')}-'
      '${seninPekanIni.month.toString().padLeft(2, '0')}-'
      '${seninPekanIni.day.toString().padLeft(2, '0')}';
}
