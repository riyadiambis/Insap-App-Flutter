import 'package:flutter_test/flutter_test.dart';
import 'package:insap/core/utils/rupiah_extension.dart';

void main() {
  test('toRupiah memformat int menjadi String Rupiah', () {
    expect(150000.toRupiah(), 'Rp150.000');
    expect((-50000).toRupiah(), '-Rp50.000');
    expect(0.toRupiah(), 'Rp0');
  });
}
