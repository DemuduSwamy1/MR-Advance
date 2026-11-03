import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/features/converter/domain/services/conversion_service.dart';
import 'package:legacy_report_converter/features/converter/domain/services/printer_control_parser.dart';
import 'package:legacy_report_converter/features/converter/domain/services/report_decoder.dart';
import 'package:legacy_report_converter/features/converter/domain/services/report_page_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(ReportDecoder, () {
    test('decodes strict UTF-8 without warnings', () {
      final decoded = const ReportDecoder().decode(utf8.encode('Grand Total'));

      expect(decoded.encodingName, 'UTF-8');
      expect(decoded.text, 'Grand Total');
      expect(decoded.replacementCharacterCount, 0);
      expect(decoded.warnings, isEmpty);
    });

    test('falls back to Latin-1 when strict UTF-8 fails', () {
      final decoded = const ReportDecoder().decode(
        Uint8List.fromList([0x43, 0xE9]),
      );

      expect(decoded.encodingName, 'Latin-1');
      expect(decoded.text, 'C\u00E9');
      expect(decoded.replacementCharacterCount, 0);
      expect(decoded.warnings, isNotEmpty);
    });
  });

  group(PrinterControlParser, () {
    test('normalizes line endings and preserves form feeds', () {
      final parsed = const PrinterControlParser().parse('A\r\nB\rC\fD');

      expect(parsed.text, 'A\nB\nC\fD');
    });

    test('removes known printer and ANSI control sequences', () {
      final parsed = const PrinterControlParser().parse(
        'A\u001bEbold\u001bF \u001b[31mred\u001b[0m',
      );

      expect(parsed.text, 'Abold red');
      expect(parsed.removedControlCharacterCount, 4);
      expect(parsed.warnings, isEmpty);
    });

    test('removes only unknown escape byte and keeps printable text', () {
      final parsed = const PrinterControlParser().parse('A\u001b#B');

      expect(parsed.text, 'A#B');
      expect(parsed.warnings, hasLength(1));
    });

    test('expands tabs to configured stops', () {
      final parsed = const PrinterControlParser(tabStop: 4).parse('AB\tC');

      expect(parsed.text, 'AB  C');
    });
  });

  group(ReportPageParser, () {
    test('splits on form feeds without creating empty edge pages', () {
      final pages = const ReportPageParser().splitIntoPages('\fA\n\fB\n\f');

      expect(pages, hasLength(2));
      expect(pages.first.text, 'A');
      expect(pages.last.text, 'B');
    });

    test('splits by line count when no form feeds exist', () {
      final pages = const ReportPageParser(
        defaultMaxLinesPerPage: 2,
      ).splitIntoPages('A\nB\nC');

      expect(pages, hasLength(2));
      expect(pages.first.lines, ['A', 'B']);
      expect(pages.last.lines, ['C']);
    });
  });

  group(ConversionService, () {
    test('creates searchable PDF bytes and validation summary', () async {
      final result = await const ConversionService().convert(
        sourceBytes: Uint8List.fromList(
          utf8.encode('Header\nGrand Total 10\n'),
        ),
        sourceFileName: 'report.prn',
      );

      expect(result.outputFileName, 'report.pdf');
      expect(result.pdfBytes.length, greaterThan(100));
      expect(result.validation.sourceLineCount, 2);
      expect(result.validation.convertedLineCount, 2);
      expect(result.validation.pageCount, 1);
      expect(result.validation.grandTotalDetected, isTrue);
    });
  });
}
