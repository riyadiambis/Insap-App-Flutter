import '../../domain/entities/cadangan_info.dart';

abstract class CadanganState {
  const CadanganState();
}

class CadanganAwal extends CadanganState {
  const CadanganAwal();
}

class CadanganMemuat extends CadanganState {
  final String pesan;
  const CadanganMemuat(this.pesan);
}

class CadanganSukses extends CadanganState {
  final String pesan;
  const CadanganSukses(this.pesan);
}

class CadanganPulihSukses extends CadanganState {
  final CadanganInfo info;
  const CadanganPulihSukses(this.info);
}

class CadanganGalat extends CadanganState {
  final String pesan;
  const CadanganGalat(this.pesan);
}
