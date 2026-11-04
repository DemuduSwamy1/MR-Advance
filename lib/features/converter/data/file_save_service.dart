import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileSaveService {
  /// Asks where to save the PDF and saves it there. In a browser the PDF is
  /// downloaded straight away. Returns false if the user cancelled.
  Future<bool> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save converted PDF',
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
    );
    // The web download has no save dialog to cancel and returns no location.
    return kIsWeb || uri != null;
  }

  /// A PDF ready for the share sheet. On a device it is written to a temporary
  /// file; in a browser there is no file system, so it stays in memory.
  Future<XFile> shareablePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    const mimeType = 'application/pdf';
    if (kIsWeb) {
      return XFile.fromData(bytes, name: fileName, mimeType: mimeType);
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return XFile(file.path, name: fileName, mimeType: mimeType);
  }
}
