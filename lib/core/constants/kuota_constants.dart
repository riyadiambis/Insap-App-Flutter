const int _kuotaEnv =
    int.fromEnvironment('KUOTA_PINDAI_PEKANAN', defaultValue: 5);

/// Jatah kuota pemindaian struk per pekan (F-11, ISSUE-26, Model Ekonomi v2.0).
///
/// Bawaan bernilai 5 sesuai Model Ekonomi v2.0. Untuk build demo pameran,
/// jatah dapat diatur melalui flag build `--dart-define=KUOTA_PINDAI_PEKANAN=200`.
/// Jika nilai yang diberikan kurang dari 1, otomatis memakai 5.
const int kuotaPindaiPekanan = _kuotaEnv < 1 ? 5 : _kuotaEnv;
