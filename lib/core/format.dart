String formatRupiah(int nominal) {
  String nominalStr = nominal.toString();
  String result = '';
  int count = 0;
  for (int i = nominalStr.length - 1; i >= 0; i--) {
    if (count != 0 && count % 3 == 0) {
      result = '.$result';
    }
    result = nominalStr[i] + result;
    count++;
  }
  return 'Rp$result';
}
