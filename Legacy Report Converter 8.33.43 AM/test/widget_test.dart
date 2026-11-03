import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/app/app.dart';

void main() {
  testWidgets('converter screen renders primary actions', (tester) async {
    await tester.pumpWidget(const LegacyReportConverterApp());

    expect(find.text('Legacy Report Converter'), findsOneWidget);
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
    expect(find.text('Invoice generation is coming soon'), findsOneWidget);

    await tester.tap(find.text('Convert'));
    await tester.pumpAndSettle();

    expect(find.text('Select Report File'), findsOneWidget);
  });
}
