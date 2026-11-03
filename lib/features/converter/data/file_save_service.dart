import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileSaveService {
  Future<Uri?> savePdf({required String fileName, required Uint8List bytes}) {
    return FilePicker.saveFile(
      dialogTitle: 'Save converted PDF',
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
    );
  }

  Future<File> writeTemporaryPdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }
}
