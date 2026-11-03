// Money is handled as whole paise and quantities as thousandths so invoice
// arithmetic is exact. These helpers convert between those integers and text.

/// Divides with commercial rounding: halves round away from zero.
int roundHalfUpDiv(int numerator, int denominator) {
  if (numerator < 0) {
    return -roundHalfUpDiv(-numerator, denominator);
  }
  return (numerator * 2 + denominator) ~/ (denominator * 2);
}

/// Parses text such as "1,234.5" into an integer scaled by 10^[decimals].
/// Returns null for empty or invalid text, or too many decimal places.
int? parseScaled(String text, {required int decimals}) {
  final cleaned = text.replaceAll(',', '').trim();
  final match = RegExp(r'^(\d*)(?:\.(\d*))?$').firstMatch(cleaned);
  if (match == null) {
    return null;
  }

  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if ((whole.isEmpty && fraction.isEmpty) || fraction.length > decimals) {
    return null;
  }

  var scale = 1;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  final wholeValue = whole.isEmpty ? 0 : int.parse(whole);
  return wholeValue * scale + int.parse(fraction.padRight(decimals, '0'));
}

/// Formats paise as rupees with Indian digit grouping, e.g. "1,23,456.78".
String formatAmount(int paise) {
  final sign = paise < 0 ? '-' : '';
  final absolute = paise.abs();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign${_groupIndian('${absolute ~/ 100}')}.$fraction';
}

/// Formats a quantity in thousandths with at least one decimal, e.g. "20.0".
String formatQuantity(int milli) {
  final fraction = _trimZeros((milli % 1000).toString().padLeft(3, '0'));
  return '${milli ~/ 1000}.${fraction.isEmpty ? '0' : fraction}';
}

/// Formats a scaled integer for editing, without grouping or trailing zeros.
String formatEditable(int value, {required int decimals}) {
  var scale = 1;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  final fraction = _trimZeros(
    (value % scale).toString().padLeft(decimals, '0'),
  );
  return fraction.isEmpty ? '${value ~/ scale}' : '${value ~/ scale}.$fraction';
}

String _trimZeros(String digits) => digits.replaceFirst(RegExp(r'0+$'), '');

String _groupIndian(String digits) {
  if (digits.length <= 3) {
    return digits;
  }

  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) {
    groups.insert(0, rest);
  }
  return '${groups.join(',')},$lastThree';
}
