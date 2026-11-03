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
}
