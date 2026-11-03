import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'theme.dart';

class LegacyReportConverterApp extends StatelessWidget {
  const LegacyReportConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReportKit',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: const HomeShell(),
    );
  }
}
