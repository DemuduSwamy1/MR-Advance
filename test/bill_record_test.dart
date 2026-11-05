import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/core/cloud/cloud_sync.dart';
import 'package:legacy_report_converter/features/invoice/data/bill_record.dart';
import 'package:legacy_report_converter/features/invoice/domain/models/invoice.dart';
import 'package:legacy_report_converter/features/invoice/domain/services/invoice_calculator.dart';

void main() {
  const items = [
    InvoiceItem(
      productName: 'INDITEL H 40',
      quantityMilli: 20000,
      ratePaise: 14463,
      discountPaise: 5000,
      batch: 'B123',
      expiry: '08/27',
    ),
  ];
  final invoice = Invoice(
    seller: SellerProfile.ravitejaMedicals,
    sellerAddress: SellerProfile.ravitejaMedicals.defaultAddress,
    sellerGstin: SellerProfile.ravitejaMedicals.defaultGstin,
    billNumber: 'RS 3387',
    date: DateTime(2026, 7, 29),
    mode: PaymentMode.credit,
    buyer: const BuyerDetails(name: 'PADMAVATHI MED & GEN STORES'),
    items: items,
  );
  final totals = const InvoiceCalculator().totals(items);

  test('bill record holds the bill, customer, items and totals', () {
    final record = billRecord(invoice, totals);

    expect(record['billNumber'], 'RS 3387');
    expect(record['billDate'], '2026-07-29');
    expect(record['mode'], 'CREDIT');
    expect((record['customer']! as Map)['name'], 'PADMAVATHI MED & GEN STORES');

    final item = (record['items']! as List).single as Map;
    expect(item['productName'], 'INDITEL H 40');
    expect(item['quantity'], 20.0);
    expect(item['discountPaise'], 5000);
    expect(item['taxablePaise'], 284260);
    expect(item['totalPaise'], totals.lines.single.totalPaise);

    expect((record['totals']! as Map)['netPaise'], totals.netPaise);
    expect(record['netAmount'], totals.netPaise / 100);
  });

  test('bill document ID is the same each time a bill is generated', () {
    String id(String billNumber) => billDocumentId(
      userId: 'abc123',
      billNumber: billNumber,
      date: DateTime(2026, 7, 29, 18, 30),
    );

    expect(id('RS 3387'), 'abc123_RS-3387_2026-07-29');
    expect(id(' RS 3387 '), id('RS 3387'));
    expect(id('RS/3387'), 'abc123_RS-3387_2026-07-29');
  });

  test('saving a bill is skipped when cloud sync has not started', () async {
    expect(await CloudSync.instance.saveBill(invoice, totals), isFalse);
  });
}
