import 'dart:typed_data';

import '../../../../core/exceptions/conversion_exception.dart';
import '../../../../core/utils/file_name_utils.dart';
import '../models/conversion_result.dart';
import '../models/report_validation.dart';
import 'pdf_generator.dart';
import 'printer_control_parser.dart';
import 'report_decoder.dart';
import 'report_page_parser.dart';

class ConversionService {
  const ConversionService({
    this.decoder = const ReportDecoder(),
    this.controlParser = const PrinterControlParser(),
    this.pageParser = const ReportPageParser(),
    this.pdfGenerator = const PdfGenerator(),
  });

  final ReportDecoder decoder;
  final PrinterControlParser controlParser;
  final ReportPageParser pageParser;
  final PdfGenerator pdfGenerator;

  Future<ConversionResult> convert({
    required Uint8List sourceBytes,
    required String sourceFileName,
    List<String> fileWarnings = const [],
  }) async {
    if (sourceBytes.isEmpty) {
      throw const ConversionException('The selected file is empty.');
    }

    final decoded = decoder.decode(sourceBytes);
    final parsed = controlParser.parse(decoded.text);
    final pages = pageParser.splitIntoPages(parsed.text);

    if (pages.isEmpty) {
      throw const ConversionException(
        'No printable report content was found after removing printer controls.',
      );
    }

    final outputFileName = pdfFileNameForSource(sourceFileName);
    final generatedAt = DateTime.now();
    final pdfBytes = await pdfGenerator.generate(
      pages: pages,
      outputFileName: outputFileName,
      generatedAt: generatedAt,
    );

    final warnings = <String>{
      ...fileWarnings,
      ...decoded.warnings,
      ...parsed.warnings,
    }.toList();

    return ConversionResult(
      sourceFileName: sourceFileName,
      outputFileName: outputFileName,
      pdfBytes: pdfBytes,
      pages: pages,
      generatedAt: generatedAt,
      validation: ReportValidation(
        sourceByteCount: sourceBytes.length,
        sourceLineCount: _lineCount(decoded.text),
        convertedLineCount: pages.fold<int>(
          0,
          (total, page) => total + page.lineCount,
        ),
        pageCount: pages.length,
        grandTotalDetected: _containsGrandTotal(parsed.text),
        removedControlCharacterCount: parsed.removedControlCharacterCount,
        encodingName: decoded.encodingName,
        replacementCharacterCount: decoded.replacementCharacterCount,
        warnings: warnings,
      ),
    );
  }

  int _lineCount(String text) {
    if (text.isEmpty) {
      return 0;
    }

    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.length > 1 && lines.last.isEmpty) {
      return lines.length - 1;
    }

    return lines.length;
  }

  bool _containsGrandTotal(String text) {
    return RegExp(r'\bgrand\s+total\b', caseSensitive: false).hasMatch(text);
  }
}
