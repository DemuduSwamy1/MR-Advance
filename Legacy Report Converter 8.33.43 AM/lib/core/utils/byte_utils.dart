import 'dart:typed_data';

String formatByteCount(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  const units = ['KB', 'MB', 'GB'];
  var value = bytes / 1024;
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  return '${value.toStringAsFixed(value >= 10 ? 1 : 2)} ${units[unitIndex]}';
}

bool isEmptyBytes(Uint8List bytes) => bytes.isEmpty;

bool isUnusuallyLargeReport(int bytes) => bytes > 10 * 1024 * 1024;
