import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/app/app.dart';
import 'package:legacy_report_converter/app/home_shell.dart';
import 'package:legacy_report_converter/app/theme.dart';

void main() {
  testWidgets('converter screen renders primary actions', (tester) async {
    await tester.pumpWidget(const LegacyReportConverterApp());

    expect(find.text('ReportKit'), findsOneWidget);
    expect(find.text('Convert reports to PDF'), findsOneWidget);
    expect(find.text('Select Report File'), findsOneWidget);
    expect(find.text('Browse All Files'), findsNothing);
    expect(find.text('Convert to PDF'), findsOneWidget);
  });

  testWidgets('invoice tab shows the invoice screen', (tester) async {
    await tester.pumpWidget(const LegacyReportConverterApp());

    await tester.tap(find.text('Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Create invoices'), findsOneWidget);
    expect(find.text('Bill details'), findsOneWidget);
    expect(find.text('Generate Invoice PDF'), findsOneWidget);

    await tester.tap(find.text('Convert'));
    await tester.pumpAndSettle();

    expect(find.text('Select Report File'), findsOneWidget);
  });

  testWidgets('the website shows the tabs in a left side bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const HomeShell(useSideBar: true),
      ),
    );

    expect(find.byKey(HomeShell.sideBarKey), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Bill details'), findsOneWidget);
  });

  testWidgets('the apps keep the bottom bar', (tester) async {
    await tester.pumpWidget(const LegacyReportConverterApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(HomeShell.sideBarKey), findsNothing);
  });

  testWidgets('wide screens use the two-column layout', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const HomeShell(useSideBar: true),
      ),
    );

    expect(find.text('ReportKit'), findsOneWidget);
    expect(find.text('Convert report to PDF'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);

    await tester.tap(find.text('Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Create invoice'), findsOneWidget);
    expect(find.text('Generate Invoice PDF'), findsOneWidget);
    expect(find.text('New invoice'), findsOneWidget);
  });
}
