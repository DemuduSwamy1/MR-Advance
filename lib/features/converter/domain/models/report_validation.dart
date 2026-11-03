class ReportValidation {
  const ReportValidation({
    required this.sourceByteCount,
    required this.sourceLineCount,
    required this.convertedLineCount,
    required this.pageCount,
    required this.grandTotalDetected,
    required this.removedControlCharacterCount,
    required this.encodingName,
    required this.replacementCharacterCount,
    required this.warnings,
  });

  final int sourceByteCount;
  final int sourceLineCount;
  final int convertedLineCount;
  final int pageCount;
  final bool grandTotalDetected;
  final int removedControlCharacterCount;
  final String encodingName;
  final int replacementCharacterCount;
  final List<String> warnings;
}
