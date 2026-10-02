import 'models/pengaturan.dart';

List<Pengaturan> buatSeedPengaturan() {
  final DateTime sekarang = DateTime.now();
  final DateTime seninPekanIni =
      sekarang.subtract(Duration(days: sekarang.weekday - 1));
  final String kuotaPeriodeMulai =
      '${seninPekanIni.year.toString().padLeft(4, '0')}-'
      '${seninPekanIni.month.toString().padLeft(2, '0')}-'
      '${seninPekanIni.day.toString().padLeft(2, '0')}';

  return [
    Pengaturan(kunci: 'versi_skema', nilai: '1'),
    Pengaturan(kunci: 'onboarding_selesai', nilai: '0'),
    Pengaturan(kunci: 'kuota_pindai_sisa', nilai: '10'),
    Pengaturan(kunci: 'kuota_periode_mulai', nilai: kuotaPeriodeMulai),
    Pengaturan(kunci: 'status_langganan', nilai: 'gratis'),
    Pengaturan(kunci: 'kategori_terakhir', nilai: ''),
  ];
}
