class ReportPage {
  const ReportPage({required this.pageNumber, required this.lines});

  final int pageNumber;
  final List<String> lines;

  String get text => lines.join('\n');

  int get lineCount => lines.length;
}
