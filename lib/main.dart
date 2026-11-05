import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/cloud/cloud_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase starts in the background so the app opens without waiting for
  // the network.
  CloudSync.instance.start();
  runApp(const LegacyReportConverterApp());
}
