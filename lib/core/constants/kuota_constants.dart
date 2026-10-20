const int _kuotaEnv =
    int.fromEnvironment('KUOTA_PINDAI_PEKANAN', defaultValue: 10);

/// Jatah kuota pemindaian struk per pekan (F-11, ISSUE-26).
///
/// Bawaan bernilai 10. Untuk build demo pameran, jatah dapat diatur
/// melalui flag build `--dart-define=KUOTA_PINDAI_PEKANAN=200`.
/// Jika nilai yang diberikan kurang dari 1, otomatis memakai 10.
const int kuotaPindaiPekanan = _kuotaEnv < 1 ? 10 : _kuotaEnv;
