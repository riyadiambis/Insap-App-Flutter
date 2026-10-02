class Pengaturan {
  final String kunci;
  final String nilai;

  Pengaturan({
    required this.kunci,
    required this.nilai,
  });

  Map<String, dynamic> toMap() {
    return {
      'kunci': kunci,
      'nilai': nilai,
    };
  }

  factory Pengaturan.fromMap(Map<String, dynamic> map) {
    return Pengaturan(
      kunci: map['kunci'] as String,
      nilai: map['nilai'] as String,
    );
  }
}
