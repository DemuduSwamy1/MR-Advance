import 'dart:typed_data';

import 'report_page.dart';
import 'report_validation.dart';

class ConversionResult {
  const ConversionResult({
    required this.sourceFileName,
    required this.outputFileName,
    required this.pdfBytes,
    required this.pages,
    required this.validation,
    required this.generatedAt,
  });

  final String sourceFileName;
  final String outputFileName;
  final Uint8List pdfBytes;
  final List<ReportPage> pages;
  final ReportValidation validation;
  final DateTime generatedAt;
}
