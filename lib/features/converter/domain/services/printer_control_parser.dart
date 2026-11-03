class PrinterControlParseResult {
  const PrinterControlParseResult({
    required this.text,
    required this.removedControlCharacterCount,
    required this.warnings,
  });

  final String text;
  final int removedControlCharacterCount;
  final List<String> warnings;
}

class PrinterControlParser {
  const PrinterControlParser({this.tabStop = 8});

  final int tabStop;

  PrinterControlParseResult parse(String input) {
    final output = StringBuffer();
    final warnings = <String>[];
    var removedCount = 0;
    var column = 0;
    var index = 0;

    while (index < input.length) {
      final codeUnit = input.codeUnitAt(index);

      switch (codeUnit) {
        case 0x00:
        case 0x08:
        case 0x7F:
          removedCount++;
          index++;
        case 0x09:
          final spaces = tabStop - (column % tabStop);
          output.write(' ' * spaces);
          column += spaces;
          index++;
        case 0x0A:
          output.write('\n');
          column = 0;
          index++;
        case 0x0C:
          output.write('\f');
          column = 0;
          index++;
        case 0x0D:
          output.write('\n');
          column = 0;
          index += _isNext(input, index, 0x0A) ? 2 : 1;
        case 0x1B:
          final consumed = _escapeSequenceLength(input, index);
          removedCount++;
          if (consumed == 1) {
            warnings.add(
              'Unknown escape sequence near character ${index + 1}.',
            );
          }
          index += consumed;
        default:
          if (_isUnsupportedControl(codeUnit)) {
            removedCount++;
          } else {
            output.writeCharCode(codeUnit);
            column++;
          }
          index++;
      }
    }

    return PrinterControlParseResult(
      text: output.toString(),
      removedControlCharacterCount: removedCount,
      warnings: warnings,
    );
  }

  bool _isNext(String input, int index, int codeUnit) {
    return index + 1 < input.length && input.codeUnitAt(index + 1) == codeUnit;
  }

  bool _isUnsupportedControl(int codeUnit) {
    final isC0 =
        codeUnit < 0x20 &&
        codeUnit != 0x09 &&
        codeUnit != 0x0A &&
        codeUnit != 0x0C &&
        codeUnit != 0x0D &&
        codeUnit != 0x1B;
    final isC1 = codeUnit >= 0x80 && codeUnit <= 0x9F;

    return isC0 || isC1;
  }

  int _escapeSequenceLength(String input, int escapeIndex) {
    if (escapeIndex + 1 >= input.length) {
      return 1;
    }

    final commandIndex = escapeIndex + 1;
    final command = input.codeUnitAt(commandIndex);

    if (command == 0x5B) {
      return _ansiSequenceLength(input, escapeIndex);
    }

    if (_oneByteEscpCommands.contains(command)) {
      return 2;
    }

    if (_oneParameterEscpCommands.contains(command)) {
      return escapeIndex + 2 < input.length ? 3 : 2;
    }

    if (command == 0x42 || command == 0x44) {
      return _consumeUntilNull(input, escapeIndex);
    }

    if (_twoByteLengthGraphicsCommands.contains(command)) {
      return _consumeEscpGraphics(input, escapeIndex, commandIndex + 1);
    }

    if (command == 0x2A) {
      return _consumeEscpGraphics(input, escapeIndex, commandIndex + 2);
    }

    if (command == 0x28) {
      return _consumeEscpParenthesized(input, escapeIndex);
    }

    return 1;
  }

  int _ansiSequenceLength(String input, int escapeIndex) {
    var index = escapeIndex + 2;
    while (index < input.length) {
      final codeUnit = input.codeUnitAt(index);
      if (codeUnit >= 0x40 && codeUnit <= 0x7E) {
        return index - escapeIndex + 1;
      }
      index++;
    }

    return 1;
  }

  int _consumeUntilNull(String input, int escapeIndex) {
    var index = escapeIndex + 2;
    while (index < input.length) {
      if (input.codeUnitAt(index) == 0x00) {
        return index - escapeIndex + 1;
      }
      index++;
    }

    return input.length - escapeIndex;
  }

  int _consumeEscpGraphics(
    String input,
    int escapeIndex,
    int lengthLowByteIndex,
  ) {
    if (lengthLowByteIndex + 1 >= input.length) {
      return input.length - escapeIndex;
    }

    final low = input.codeUnitAt(lengthLowByteIndex);
    final high = input.codeUnitAt(lengthLowByteIndex + 1);
    final dataLength = low + (high * 256);
    final totalLength = lengthLowByteIndex - escapeIndex + 2 + dataLength;

    return totalLength.clamp(1, input.length - escapeIndex);
  }

  int _consumeEscpParenthesized(String input, int escapeIndex) {
    if (escapeIndex + 4 >= input.length) {
      return input.length - escapeIndex;
    }

    final low = input.codeUnitAt(escapeIndex + 3);
    final high = input.codeUnitAt(escapeIndex + 4);
    final dataLength = low + (high * 256);
    final totalLength = 5 + dataLength;

    return totalLength.clamp(1, input.length - escapeIndex);
  }

  static const _oneByteEscpCommands = <int>{
    0x30,
    0x31,
    0x32,
    0x34,
    0x35,
    0x36,
    0x37,
    0x38,
    0x39,
    0x3C,
    0x3D,
    0x3E,
    0x40,
    0x45,
    0x46,
    0x47,
    0x48,
    0x4D,
    0x50,
    0x67,
    0x78,
  };

  static const _oneParameterEscpCommands = <int>{
    0x21,
    0x2D,
    0x41,
    0x43,
    0x4A,
    0x51,
    0x52,
    0x53,
    0x55,
    0x57,
    0x6A,
    0x6B,
    0x6C,
    0x70,
    0x74,
  };

  static const _twoByteLengthGraphicsCommands = <int>{0x4B, 0x4C, 0x59, 0x5A};
}
