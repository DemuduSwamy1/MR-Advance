import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_page.dart';

class PdfGenerator {
  const PdfGenerator();

  static final PdfPageFormat pageFormat = PdfPageFormat.a4.landscape.copyWith(
    marginLeft: 20,
    marginRight: 20,
    marginTop: 18,
    marginBottom: 30,
  );

  Future<Uint8List> generate({
    required List<ReportPage> pages,
    required String outputFileName,
    required DateTime generatedAt,
  }) async {
    final document = pw.Document();
    final fontData = await rootBundle.load(
      'assets/fonts/RobotoMono-Regular.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final longestLineLength = _longestLineLength(pages);
    final fontSize = _fontSizeFor(longestLineLength);
    final lineHeight = fontSize * 1.18;
    final printableCharacterLimit = _characterLimitFor(fontSize);
    final style = pw.TextStyle(font: font, fontSize: fontSize, height: 1.18);

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        footer: (context) => _Footer(
          outputFileName: outputFileName,
          generatedAt: generatedAt,
          font: font,
          pageNumber: context.pageNumber,
          pageCount: context.pagesCount,
        ),
        build: (context) {
          final widgets = <pw.Widget>[];
          for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
            if (pageIndex > 0) {
              widgets.add(pw.NewPage());
            }

            widgets.addAll(
              _lineWidgets(
                pages[pageIndex].lines,
                style: style,
                lineHeight: lineHeight,
                printableCharacterLimit: printableCharacterLimit,
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return document.save();
  }

  int _longestLineLength(List<ReportPage> pages) {
    var longest = 0;
    for (final page in pages) {
      for (final line in page.lines) {
        longest = math.max(longest, line.length);
      }
    }

    return longest;
  }

  double _fontSizeFor(int longestLineLength) {
    if (longestLineLength == 0) {
      return 8;
    }

    const startingFontSize = 8.0;
    const minimumFontSize = 5.0;
    const courierWidthFactor = 0.6;
    final fittingSize =
        pageFormat.availableWidth / (longestLineLength * courierWidthFactor);

    return fittingSize.clamp(minimumFontSize, startingFontSize);
  }

  int _characterLimitFor(double fontSize) {
    const courierWidthFactor = 0.6;
    return (pageFormat.availableWidth / (fontSize * courierWidthFactor))
        .floor()
        .clamp(1, 10000);
  }

  List<pw.Widget> _lineWidgets(
    List<String> lines, {
    required pw.TextStyle style,
    required double lineHeight,
    required int printableCharacterLimit,
  }) {
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      if (line.isEmpty) {
        widgets.add(pw.SizedBox(height: lineHeight));
        continue;
      }

      for (final segment in _segmentsFor(line, printableCharacterLimit)) {
        widgets.add(
          pw.Text(
            segment.isEmpty ? ' ' : segment,
            style: style,
            softWrap: false,
          ),
        );
      }
    }

    return widgets;
  }

  Iterable<String> _segmentsFor(String line, int limit) sync* {
    if (line.length <= limit) {
      yield line;
      return;
    }

    for (var index = 0; index < line.length; index += limit) {
      final end = math.min(index + limit, line.length);
      yield line.substring(index, end);
    }
  }
}

class _Footer extends pw.StatelessWidget {
  _Footer({
    required this.outputFileName,
    required this.generatedAt,
    required this.font,
    required this.pageNumber,
    required this.pageCount,
  });

  final String outputFileName;
  final DateTime generatedAt;
  final pw.Font font;
  final int pageNumber;
  final int pageCount;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey500, width: 0.4),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            outputFileName,
            style: pw.TextStyle(
              font: font,
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            '${_formatDateTime(generatedAt)}    Page $pageNumber of $pageCount',
            style: pw.TextStyle(
              font: font,
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }
}
