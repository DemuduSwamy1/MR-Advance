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

/// Describes [bytes] when they are clearly not a text report, such as an app,
/// archive, document or media file, or returns null when they look like text.
String? binaryFileKind(Uint8List bytes) {
  for (final signature in _binarySignatures) {
    if (signature.matches(bytes)) {
      return signature.kind;
    }
  }

  // Printer reports contain a few control bytes (escape sequences, form feeds,
  // the odd NUL); binary data has many more, about 9% even when compressed.
  final sample = Uint8List.sublistView(bytes, 0, bytes.length.clamp(0, 65536));
  var unexpected = 0;
  for (final byte in sample) {
    if (byte < 0x20 && !_textControlBytes.contains(byte)) {
      unexpected++;
    }
  }
  return unexpected * 20 > sample.length ? 'a binary file' : null;
}

/// Backspace, tab, line feed, form feed, carriage return, shift out/in
/// (printer wide text) and escape.
const _textControlBytes = {0x08, 0x09, 0x0A, 0x0C, 0x0D, 0x0E, 0x0F, 0x1B};

const _binarySignatures = [
  _FileSignature([0x50, 0x4B, 0x03, 0x04], 'an app (APK), ZIP or Office file'),
  _FileSignature([0x25, 0x50, 0x44, 0x46, 0x2D], 'a PDF document'),
  _FileSignature([0x89, 0x50, 0x4E, 0x47], 'a PNG image'),
  _FileSignature([0xFF, 0xD8, 0xFF], 'a JPEG image'),
  _FileSignature([0x66, 0x74, 0x79, 0x70], 'a video or photo', offset: 4),
  _FileSignature([0x1F, 0x8B], 'a compressed (gzip) file'),
  _FileSignature([0x37, 0x7A, 0xBC, 0xAF], 'a 7-Zip archive'),
  _FileSignature([0xD0, 0xCF, 0x11, 0xE0], 'a Microsoft Office document'),
  _FileSignature([0x7F, 0x45, 0x4C, 0x46], 'a program file'),
];

class _FileSignature {
  const _FileSignature(this.magic, this.kind, {this.offset = 0});

  final List<int> magic;
  final String kind;
  final int offset;

  bool matches(Uint8List bytes) {
    if (bytes.length < offset + magic.length) {
      return false;
    }
    for (var i = 0; i < magic.length; i++) {
      if (bytes[offset + i] != magic[i]) {
        return false;
      }
    }
    return true;
  }
}
