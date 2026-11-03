import '../models/report_page.dart';

class ReportPageParser {
  const ReportPageParser({this.defaultMaxLinesPerPage = 60});

  final int defaultMaxLinesPerPage;

  List<ReportPage> splitIntoPages(String text, {int? maxLinesPerPage}) {
    final lineLimit = maxLinesPerPage ?? defaultMaxLinesPerPage;
    final normalizedText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    if (normalizedText.contains('\f')) {
      return _splitByFormFeed(normalizedText);
    }

    return _splitByLineLimit(normalizedText, lineLimit);
  }

  List<ReportPage> _splitByFormFeed(String text) {
    final pages = <ReportPage>[];
    final rawPages = text.split('\f');

    for (final rawPage in rawPages) {
      if (rawPage.isEmpty) {
        continue;
      }

      pages.add(
        ReportPage(pageNumber: pages.length + 1, lines: _linesForPage(rawPage)),
      );
    }

    return pages;
  }

  List<ReportPage> _splitByLineLimit(String text, int lineLimit) {
    final lines = _linesForPage(text);
    if (lines.isEmpty) {
      return const [];
    }

    final pages = <ReportPage>[];
    for (var start = 0; start < lines.length; start += lineLimit) {
      final end = (start + lineLimit).clamp(0, lines.length);
      pages.add(
        ReportPage(
          pageNumber: pages.length + 1,
          lines: lines.sublist(start, end),
        ),
      );
    }

    return pages;
  }

  List<String> _linesForPage(String text) {
    final lines = text.split('\n');
    if (lines.length > 1 && lines.last.isEmpty) {
      return lines.sublist(0, lines.length - 1);
    }

    if (lines.length == 1 && lines.first.isEmpty) {
      return const [];
    }

    return lines;
  }
}
