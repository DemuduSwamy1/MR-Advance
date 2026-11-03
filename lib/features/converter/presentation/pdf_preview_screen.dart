import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../domain/models/conversion_result.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key, required this.result});

  final ConversionResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(result.outputFileName)),
      body: PdfPreview(
        build: (_) async => result.pdfBytes,
        initialPageFormat: PdfPageFormat.a4.landscape,
        pdfFileName: result.outputFileName,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
