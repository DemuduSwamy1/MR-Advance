import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../core/exceptions/conversion_exception.dart';
import '../../../core/utils/byte_utils.dart';

class SelectedReportFile {
  const SelectedReportFile({
    required this.name,
    required this.uri,
    required this.bytes,
    required this.sizeInBytes,
    required this.warnings,
  });

  final String name;
  final Uri uri;
  final Uint8List bytes;
  final int sizeInBytes;
  final List<String> warnings;

  String? get path => uri.scheme == 'file' ? uri.toFilePath() : null;
}

class FilePickerService {
  static const supportedExtensions = ['txt', 'dat', 'prn', 'lis', 'out'];

  /// Lets the user pick any file, since many legacy reports have no
  /// extension; uncommon extensions only produce a warning.
  Future<SelectedReportFile?> pickReportFile() async {
    final pickedFile = await FilePicker.pickFile(
      dialogTitle: 'Select report file',
      type: FileType.any,
    );

    if (pickedFile == null) {
      return null;
    }

    return buildSelectedFile(
      name: pickedFile.name,
      uri: pickedFile.uri,
      bytes: await pickedFile.readAsBytes(),
    );
  }

  /// Validates file contents and collects warnings, for files from the picker
  /// or shared into the app from another app.
  SelectedReportFile buildSelectedFile({
    required String name,
    required Uri uri,
    required Uint8List bytes,
    bool checkExtension = true,
  }) {
    if (isEmptyBytes(bytes)) {
      throw const ConversionException('The selected file is empty.');
    }

    final binaryKind = binaryFileKind(bytes);
    if (binaryKind != null) {
      throw ConversionException(
        '"$name" is not a text report; it looks like $binaryKind. '
        'Choose the report file itself, such as a .txt, .prn, .dat, .lis, '
        '.out or extension-less report.',
      );
    }

    final warnings = <String>[];
    if (isUnusuallyLargeReport(bytes.length)) {
      warnings.add(
        'This file is unusually large. Conversion may take longer than usual.',
      );
    }

    final extension = _extensionFor(name);
    if (checkExtension &&
        extension.isNotEmpty &&
        !supportedExtensions.contains(extension)) {
      warnings.add(
        'The selected extension is uncommon for legacy reports. The file will still be processed.',
      );
    }

    return SelectedReportFile(
      name: name,
      uri: uri,
      bytes: bytes,
      sizeInBytes: bytes.length,
      warnings: warnings,
    );
  }

  String _extensionFor(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }
}
