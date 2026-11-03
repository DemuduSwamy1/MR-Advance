# ReportKit

A local-only Flutter application for converting fixed-width legacy printer report files into clean, searchable PDF documents.

The app supports files with no extension and common report extensions such as `.txt`, `.dat`, `.prn`, `.lis`, and `.out`. It decodes UTF-8 and Latin-1 content, removes printer-control sequences, preserves fixed-width spacing and page breaks, and generates A4 landscape PDFs with monospaced report text.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
