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

  Future<SelectedReportFile?> pickReportFile({
    bool allowAnyFile = false,
  }) async {
    final pickedFile = await FilePicker.pickFile(
      dialogTitle: allowAnyFile
          ? 'Select legacy report file'
          : 'Select report file',
      type: allowAnyFile ? FileType.any : FileType.custom,
      allowedExtensions: allowAnyFile ? null : supportedExtensions,
    );

    if (pickedFile == null) {
      return null;
    }

    return buildSelectedFile(
      name: pickedFile.name,
      uri: pickedFile.uri,
      bytes: await pickedFile.readAsBytes(),
      checkExtension: !allowAnyFile,
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
