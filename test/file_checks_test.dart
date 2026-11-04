import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/core/exceptions/conversion_exception.dart';
import 'package:legacy_report_converter/core/utils/byte_utils.dart';
import 'package:legacy_report_converter/features/converter/data/file_picker_service.dart';

Uint8List _bytes(List<int> header, {int length = 2048, int fill = 0x00}) {
  return Uint8List.fromList([
    ...header,
    ...List.filled(length - header.length, fill),
  ]);
}

void main() {
  group('binaryFileKind', () {
    test('recognises app, document and media files', () {
      expect(
        binaryFileKind(_bytes([0x50, 0x4B, 0x03, 0x04])),
        'an app (APK), ZIP or Office file',
      );
      expect(
        binaryFileKind(_bytes(ascii.encode('%PDF-1.7\n'), fill: 0x41)),
        'a PDF document',
      );
      expect(binaryFileKind(_bytes([0x89, 0x50, 0x4E, 0x47])), 'a PNG image');
      expect(binaryFileKind(_bytes([0xFF, 0xD8, 0xFF, 0xE0])), 'a JPEG image');
      expect(
        binaryFileKind(
          _bytes([0x00, 0x00, 0x00, 0x18, ...ascii.encode('ftyp')]),
        ),
        'a video or photo',
      );
    });

    test('treats data full of control bytes as binary', () {
      final noise = Uint8List.fromList(
        List.generate(4096, (i) => (i * 37) % 256),
      );

      expect(binaryFileKind(noise), 'a binary file');
    });

    test('accepts plain and printer-formatted reports', () {
      final plain = utf8.encode(
        'MONTHLY SALES REPORT      PAGE 1\n'
        'REGION      UNITS     AMOUNT\n'
        'NORTH         120   12,400.00\n',
      );
      final printer = Uint8List.fromList([
        0x1B, 0x40, // ESC @ (reset)
        0x1B, 0x45, // ESC E (bold)
        ...ascii.encode('INVOICE REGISTER\r\n'),
        0x0E, ...ascii.encode('WIDE TITLE'), 0x0F, 0x0D, 0x0A,
        0x1B, 0x33, 0x18, // ESC 3 n (line spacing)
        ...ascii.encode('ITEM\tQTY\tAMOUNT\r\n' * 40),
        0x00,
        0x0C, // form feed
        ...latin1.encode('CAFÉ TOTAL   1,234.50\r\n'),
      ]);

      expect(binaryFileKind(plain), isNull);
      expect(binaryFileKind(printer), isNull);
    });
  });

  group('FilePickerService.buildSelectedFile', () {
    test('rejects binary files with a clear message', () {
      expect(
        () => FilePickerService().buildSelectedFile(
          name: 'reportkit-1.0.0.apk',
          uri: Uri.parse('content://files/1'),
          bytes: _bytes([0x50, 0x4B, 0x03, 0x04]),
        ),
        throwsA(
          isA<ConversionException>().having(
            (error) => error.message,
            'message',
            contains('"reportkit-1.0.0.apk" is not a text report'),
          ),
        ),
      );
    });

    test('accepts text reports', () {
      final file = FilePickerService().buildSelectedFile(
        name: 'sales.prn',
        uri: Uri.parse('content://files/2'),
        bytes: Uint8List.fromList(utf8.encode('TOTAL  100.00\n')),
      );

      expect(file.name, 'sales.prn');
      expect(file.warnings, isEmpty);
    });
  });
}
