import 'package:flutter/material.dart';

import '../features/converter/presentation/converter_screen.dart';
import 'theme.dart';

class LegacyReportConverterApp extends StatelessWidget {
  const LegacyReportConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legacy Report to PDF Converter',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: const ConverterScreen(),
    );
  }
}
