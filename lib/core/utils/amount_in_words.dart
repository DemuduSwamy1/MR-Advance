const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

/// Writes an amount in paise the way Indian invoices do, e.g.
/// "Rs. Twenty Eight thousand Eight hundred Fifty Two Only".
String rupeesInWords(int paise) {
  final rupees = paise.abs() ~/ 100;
  final remainder = paise.abs() % 100;
  final words = rupees == 0 ? 'Zero' : _indianWords(rupees);
  final paiseWords = remainder == 0
      ? ''
      : ' and ${_belowHundred(remainder)} Paise';
  final sign = paise < 0 ? 'Minus ' : '';
  return 'Rs. $sign$words$paiseWords Only';
}

String _indianWords(int number) {
  final parts = <String>[];
  var rest = number;

  final crore = rest ~/ 10000000;
  rest %= 10000000;
  if (crore > 0) {
    parts.add('${_indianWords(crore)} crore');
  }

  final lakh = rest ~/ 100000;
  rest %= 100000;
  if (lakh > 0) {
    parts.add('${_belowHundred(lakh)} lakh');
  }

  final thousand = rest ~/ 1000;
  rest %= 1000;
  if (thousand > 0) {
    parts.add('${_belowHundred(thousand)} thousand');
  }

  final hundred = rest ~/ 100;
  rest %= 100;
  if (hundred > 0) {
    parts.add('${_ones[hundred]} hundred');
  }

  if (rest > 0) {
    parts.add(_belowHundred(rest));
  }
  return parts.join(' ');
}

String _belowHundred(int number) {
  if (number < 20) {
    return _ones[number];
  }
  final unit = number % 10;
  return unit == 0
      ? _tens[number ~/ 10]
      : '${_tens[number ~/ 10]} ${_ones[unit]}';
}
