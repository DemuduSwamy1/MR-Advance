import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/app/app.dart';

void main() {
  testWidgets('converter screen renders primary actions', (tester) async {
    await tester.pumpWidget(const LegacyReportConverterApp());

    expect(find.text('Legacy Report to PDF Converter'), findsOneWidget);
    expect(find.text('Select Report File'), findsOneWidget);
    expect(find.text('Browse All Files'), findsOneWidget);
    expect(find.text('Convert to PDF'), findsOneWidget);
  });

  testWidgets('invoice tab shows the invoice screen', (tester) async {
    await tester.pumpWidget(const LegacyReportConverterApp());

    await tester.tap(find.text('Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Generate Invoice'), findsOneWidget);

    await tester.tap(find.text('Convert'));
    await tester.pumpAndSettle();

    expect(find.text('Select Report File'), findsOneWidget);
  });
}
