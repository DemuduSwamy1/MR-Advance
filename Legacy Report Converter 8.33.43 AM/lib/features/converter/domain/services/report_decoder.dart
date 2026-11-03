import 'dart:convert';
import 'dart:typed_data';

class DecodedReport {
  const DecodedReport({
    required this.text,
    required this.encodingName,
    required this.warnings,
    required this.replacementCharacterCount,
  });

  final String text;
  final String encodingName;
  final List<String> warnings;
  final int replacementCharacterCount;
}

class ReportDecoder {
  const ReportDecoder();

  DecodedReport decode(Uint8List bytes) {
    try {
      return DecodedReport(
        text: const Utf8Decoder(allowMalformed: false).convert(bytes),
        encodingName: 'UTF-8',
        warnings: const [],
        replacementCharacterCount: 0,
      );
    } on FormatException {
      final malformedText = const Utf8Decoder(
        allowMalformed: true,
      ).convert(bytes);
      final replacementCount = _replacementCharacterCount(malformedText);
      final latin1Text = latin1.decode(bytes);

      if (_shouldPreferLatin1(
        malformedText: malformedText,
        latin1Text: latin1Text,
        replacementCount: replacementCount,
        byteCount: bytes.length,
      )) {
        return DecodedReport(
          text: latin1Text,
          encodingName: 'Latin-1',
          warnings: [
            'Strict UTF-8 decoding failed.',
            'Latin-1 fallback was used to avoid $replacementCount replacement character(s).',
          ],
          replacementCharacterCount: 0,
        );
      }

      return DecodedReport(
        text: malformedText,
        encodingName: 'UTF-8 with replacements',
        warnings: [
          'Strict UTF-8 decoding failed.',
          '$replacementCount undecodable byte sequence(s) were replaced.',
        ],
        replacementCharacterCount: replacementCount,
      );
    }
  }

  int _replacementCharacterCount(String text) {
    return text.runes.where((rune) => rune == 0xFFFD).length;
  }

  bool _shouldPreferLatin1({
    required String malformedText,
    required String latin1Text,
    required int replacementCount,
    required int byteCount,
  }) {
    if (replacementCount == 0) {
      return false;
    }

    final replacementRatio = replacementCount / byteCount;
    final latin1ControlCount = _unsupportedLatin1ControlCount(latin1Text);
    final utf8ControlCount = _unsupportedLatin1ControlCount(malformedText);

    return replacementRatio >= 0.005 || latin1ControlCount <= utf8ControlCount;
  }

  int _unsupportedLatin1ControlCount(String text) {
    var count = 0;
    for (final codeUnit in text.codeUnits) {
      final isC0 =
          codeUnit < 0x20 &&
          codeUnit != 0x09 &&
          codeUnit != 0x0A &&
          codeUnit != 0x0C &&
          codeUnit != 0x0D;
      final isDelete = codeUnit == 0x7F;
      final isC1 = codeUnit >= 0x80 && codeUnit <= 0x9F;

      if (isC0 || isDelete || isC1) {
        count++;
      }
    }

    return count;
  }
}
