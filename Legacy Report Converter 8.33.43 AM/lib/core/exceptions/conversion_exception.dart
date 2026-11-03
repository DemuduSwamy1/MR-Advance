class ConversionException implements Exception {
  const ConversionException(this.message);

  final String message;

  @override
  String toString() => message;
}
