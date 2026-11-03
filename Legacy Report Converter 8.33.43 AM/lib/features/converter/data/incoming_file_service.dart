import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/exceptions/conversion_exception.dart';
import 'file_picker_service.dart';

/// Receives report files that other apps (WhatsApp, Files, Gmail) open with
/// or share to this app on Android.
class IncomingFileService {
  IncomingFileService({FilePickerService? filePickerService})
    : _filePickerService = filePickerService ?? FilePickerService();

  static const _channel = MethodChannel(
    'legacy_report_converter/incoming_file',
  );

  final FilePickerService _filePickerService;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Calls [onFile] for the file that launched the app, if any, and for every
  /// file shared while the app is running.
  Future<void> listen(void Function(Uri uri) onFile) async {
    if (!_isSupported) {
      return;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'fileReceived') {
        onFile(Uri.parse(call.arguments as String));
      }
    });

    try {
      final initialUri = await _channel.invokeMethod<String>(
        'getInitialFileUri',
      );
      if (initialUri != null) {
        onFile(Uri.parse(initialUri));
      }
    } on MissingPluginException {
      // No native handler, e.g. in widget tests.
    }
  }

  void dispose() {
    if (_isSupported) {
      _channel.setMethodCallHandler(null);
    }
  }

  Future<SelectedReportFile> readFile(Uri uri) async {
    final Map<Object?, Object?>? file;
    try {
      file = await _channel.invokeMapMethod<Object?, Object?>(
        'readFile',
        uri.toString(),
      );
    } on PlatformException catch (error) {
      throw ConversionException(
        'Could not open the shared file. ${error.message ?? ''}'.trim(),
      );
    }

    if (file == null) {
      throw const ConversionException('Could not open the shared file.');
    }

    return _filePickerService.buildSelectedFile(
      name: file['name'] as String,
      uri: uri,
      bytes: file['bytes'] as Uint8List,
      checkExtension: false,
    );
  }
}
