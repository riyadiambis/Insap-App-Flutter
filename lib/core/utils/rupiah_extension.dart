import '../format.dart';

extension RupiahExtension on int {
  String toRupiah() => formatRupiah(this);
}
