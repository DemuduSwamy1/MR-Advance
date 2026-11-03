String pdfFileNameForSource(String sourceFileName) {
  final trimmed = sourceFileName.trim().isEmpty
      ? 'legacy_report'
      : sourceFileName;
  final withoutExtension = trimmed.contains('.')
      ? trimmed.substring(0, trimmed.lastIndexOf('.'))
      : trimmed;
  final safeBase = withoutExtension
      .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  return '${safeBase.isEmpty ? 'legacy_report' : safeBase}.pdf';
}
