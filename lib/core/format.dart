String formatRupiah(int nominal) {
  final bool negatif = nominal < 0;
  String nominalStr = nominal.abs().toString();
  String result = '';
  int count = 0;
  for (int i = nominalStr.length - 1; i >= 0; i--) {
    if (count != 0 && count % 3 == 0) {
      result = '.$result';
    }
    result = nominalStr[i] + result;
    count++;
  }
  return negatif ? '-Rp$result' : 'Rp$result';
}
