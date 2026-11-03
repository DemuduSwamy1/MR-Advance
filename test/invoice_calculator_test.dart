import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_report_converter/core/utils/amount_in_words.dart';
import 'package:legacy_report_converter/core/utils/number_format.dart';
import 'package:legacy_report_converter/features/invoice/domain/models/invoice.dart';
import 'package:legacy_report_converter/features/invoice/domain/services/invoice_calculator.dart';
import 'package:legacy_report_converter/features/invoice/domain/services/invoice_pdf_generator.dart';

// The four rows of the sample invoice e13.pdf (bill RS 3387).
const _sampleItems = [
  InvoiceItem(
    productName: 'INDITEL H 40',
    quantityMilli: 20000,
    ratePaise: 14463,
  ),
  InvoiceItem(
    productName: 'INDITEL H 40',
    quantityMilli: 10000,
    ratePaise: 13149,
  ),
  InvoiceItem(
    productName: 'ZOMELIS MET 50/500',
    quantityMilli: 130000,
    freeMilli: 13000,
    ratePaise: 15514,
  ),
  InvoiceItem(
    productName: 'ZOMELIS 50 MG',
    quantityMilli: 20000,
    freeMilli: 2000,
    ratePaise: 15514,
  ),
];

void main() {
  const calculator = InvoiceCalculator();

  group('InvoiceCalculator', () {
    test('matches the line amounts and taxes of the sample invoice', () {
      final lines = _sampleItems.map(calculator.lineTotals).toList();

      expect(lines.map((line) => line.amountPaise), [
        289260,
        131490,
        2016820,
        310280,
      ]);
      expect(lines.map((line) => line.cgstPaise), [7232, 3287, 50421, 7757]);
      expect(lines.map((line) => line.totalPaise), [
        303723,
        138065,
        2117661,
        325794,
      ]);
    });

    test('matches the sample invoice totals and round off', () {
      final totals = calculator.totals(_sampleItems);
      final fivePercent = totals.slabs.firstWhere(
        (slab) => slab.gstPercent == 5,
      );

      expect(totals.itemCount, 4);
      expect(formatQuantity(totals.unitsMilli), '195.0');
      expect(formatAmount(totals.grossPaise), '27,478.50');
      expect(formatAmount(totals.taxablePaise), '27,478.50');
      expect(formatAmount(fivePercent.cgstPaise), '686.96');
      expect(formatAmount(totals.cgstPaise), '686.96');
      expect(formatAmount(totals.sgstPaise), '686.96');
      expect(formatAmount(totals.roundOffPaise), '-0.42');
      expect(formatAmount(totals.netPaise), '28,852.00');
      expect(
        rupeesInWords(totals.netPaise),
        'Rs. Twenty Eight thousand Eight hundred Fifty Two Only',
      );
    });

    test('derives the sample rates from MRP, GST and a 20% margin', () {
      int rate(int mrpPaise) => calculator.rateFromMrp(
        mrpPaise: mrpPaise,
        gstPercent: 5,
        marginBasisPoints: InvoiceItem.defaultMarginBasisPoints,
      );

      expect(rate(18983), 14463);
      expect(rate(17258), 13149);
      expect(rate(20362), 15514);
      expect(
        calculator.rateFromMrp(
          mrpPaise: 11800,
          gstPercent: 18,
          marginBasisPoints: 0,
        ),
        10000,
      );
    });

    test('derives free quantity from a buy + free scheme', () {
      int? free(int quantity, String scheme) => calculator.freeForScheme(
        quantityMilli: quantity * 1000,
        scheme: scheme,
      );

      expect(free(130, '10+1'), 13000);
      expect(free(20, '10 + 1'), 2000);
      expect(free(9, '10+1'), 0);
      expect(free(24, '12+2'), 4000);
      expect(free(20, ''), isNull);
      expect(free(20, '10'), isNull);
      expect(free(20, '0+1'), isNull);
    });

    test('applies discounts before tax', () {
      final line = calculator.lineTotals(
        const InvoiceItem(
          productName: 'TEST',
          quantityMilli: 10000,
          ratePaise: 10000,
          discountBasisPoints: 1000,
          gstPercent: 12,
        ),
      );

      expect(line.amountPaise, 100000);
      expect(line.discountPaise, 10000);
      expect(line.taxablePaise, 90000);
      expect(line.cgstPaise, 5400);
      expect(line.totalPaise, 100800);
    });
  });

  group('number formatting', () {
    test('uses Indian digit grouping', () {
      expect(formatAmount(0), '0.00');
      expect(formatAmount(99999), '999.99');
      expect(formatAmount(12345678), '1,23,456.78');
      expect(formatAmount(1234567890), '1,23,45,678.90');
    });

    test('parses and formats editable values', () {
      expect(parseScaled('144.63', decimals: 2), 14463);
      expect(parseScaled('1,314.9', decimals: 2), 131490);
      expect(parseScaled('20', decimals: 3), 20000);
      expect(parseScaled('1.234', decimals: 2), isNull);
      expect(parseScaled('abc', decimals: 2), isNull);
      expect(parseScaled('', decimals: 2), isNull);
      expect(formatEditable(14460, decimals: 2), '144.6');
      expect(formatEditable(20000, decimals: 3), '20');
    });

    test('writes lakhs and crores in words', () {
      expect(rupeesInWords(1050000000), 'Rs. One crore Five lakh Only');
      expect(rupeesInWords(10050), 'Rs. One hundred and Fifty Paise Only');
      expect(formatInvoiceDate(DateTime(2026, 7, 29)), '29/Jul/2026');
    });
  });

  group('InvoicePdfGenerator', () {
    Invoice invoiceWith(List<InvoiceItem> items) => Invoice(
      seller: SellerProfile.ravitejaMedicals,
      sellerAddress: SellerProfile.ravitejaMedicals.defaultAddress,
      sellerGstin: SellerProfile.ravitejaMedicals.defaultGstin,
      billNumber: 'RS 3387',
      date: DateTime(2026, 7, 29),
      mode: PaymentMode.credit,
      buyer: const BuyerDetails(name: 'PADMAVATHI MED & GEN STORES'),
      items: items,
    );

    test('creates a PDF for the sample invoice', () async {
      final bytes = await const InvoicePdfGenerator().generate(
        invoiceWith(_sampleItems),
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('splits long invoices across pages', () async {
      final items = List.generate(40, (_) => _sampleItems.first);
      final bytes = await const InvoicePdfGenerator().generate(
        invoiceWith(items),
      );
      final pageCount = RegExp(
        r'/Type\s*/Page[^s]',
      ).allMatches(String.fromCharCodes(bytes)).length;

      expect(pageCount, 3);
    });
  });
}
