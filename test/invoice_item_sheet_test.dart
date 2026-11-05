import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/features/invoice/presentation/widgets/invoice_item_sheet.dart';

void main() {
  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InvoiceItemSheet())),
    );
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label).first;

  testWidgets('fields follow the order of the bill columns', (tester) async {
    await pumpSheet(tester);

    const labels = [
      'MFR',
      'HSN code',
      'Product name *',
      'Pack',
      'Batch',
      'Expiry',
      'M.R.P',
      'Rev. M.R.P',
      'Qty *',
      'Scheme',
      'Free',
      'Margin %',
      'Rate *',
      'Amount',
      'Disc (₹)',
      'Taxable amt',
      'GST %',
      'CGST amt',
      'SGST amt',
      'Total',
    ];
    final positions = [
      for (final label in labels)
        tester.getTopLeft(
          find
              .ancestor(
                of: find.text(label).first,
                matching: find.byType(InputDecorator),
              )
              .first,
        ),
    ];
    for (var i = 1; i < positions.length; i++) {
      final before = positions[i - 1];
      final after = positions[i];
      final inOrder =
          after.dy > before.dy + 1 ||
          ((after.dy - before.dy).abs() <= 1 && after.dx > before.dx);
      expect(
        inOrder,
        isTrue,
        reason: '${labels[i]} comes after ${labels[i - 1]}',
      );
    }
  });

  testWidgets('calculated fields fill in as the item is typed', (tester) async {
    await pumpSheet(tester);
    expect(find.text('—'), findsNWidgets(5));

    await tester.enterText(field('Qty *'), '30');
    await tester.enterText(field('Rate *'), '192.03');
    await tester.pump();

    expect(find.text('₹ 5,760.90'), findsNWidgets(2)); // Amount and taxable
    expect(find.text('₹ 144.02'), findsNWidgets(2)); // CGST and SGST
    expect(find.text('₹ 6,048.95'), findsOneWidget);

    await tester.enterText(field('Disc (₹)'), '60.90');
    await tester.pump();

    expect(find.text('₹ 5,760.90'), findsOneWidget);
    expect(find.text('₹ 5,700.00'), findsOneWidget);
  });
}
