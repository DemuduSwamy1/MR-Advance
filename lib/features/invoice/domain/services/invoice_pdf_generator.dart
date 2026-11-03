import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/amount_in_words.dart';
import '../../../../core/utils/number_format.dart';
import '../models/invoice.dart';
import 'invoice_calculator.dart';

/// Builds the landscape A4 tax invoice, laid out like the pharmacy's
/// existing printed bills.
class InvoicePdfGenerator {
  const InvoicePdfGenerator({this.calculator = const InvoiceCalculator()});

  final InvoiceCalculator calculator;

  static final PdfPageFormat pageFormat = PdfPageFormat.a4.landscape.copyWith(
    marginLeft: 24,
    marginRight: 24,
    marginTop: 20,
    marginBottom: 20,
  );

  /// Item rows that fit on one page alongside the header and totals.
  static const rowsPerPage = 16;

  static const _line = pw.BorderSide(width: 0.8);
  static const _legalText =
      'E.&.O.E. * NB: This registration certificate is valid on the date of '
      'this invoice * Net amount is rounded off * We hereby give the warranty '
      'that the above goods sold by us do not contravene in any way the '
      'provisions of section 18 of the Drugs & Cosmetics Act, 1940.';

  static const _columns = [
    _ItemColumn('SL', 35),
    _ItemColumn('MFR', 55),
    _ItemColumn('HSN Code', 105),
    _ItemColumn('PRODUCT NAME', 320),
    _ItemColumn('PACK', 70, alignRight: true),
    _ItemColumn('BATCH', 165),
    _ItemColumn('Ex.Dt', 65),
    _ItemColumn('M.R.P', 95, alignRight: true),
    _ItemColumn('Rev\nM.R.P', 85, alignRight: true),
    _ItemColumn('QTY', 85, alignRight: true),
    _ItemColumn('FREE', 65, alignRight: true),
    _ItemColumn('RATE', 95, alignRight: true),
    _ItemColumn('AMOUNT', 105, alignRight: true),
    _ItemColumn('DISC', 60, alignRight: true),
    _ItemColumn('Taxable\nAmt', 105, alignRight: true),
    _ItemColumn('GST\n%', 50, alignRight: true),
    _ItemColumn('CGST\nAMT', 85, alignRight: true),
    _ItemColumn('SGST\nAMT', 85, alignRight: true),
    _ItemColumn('TOTAL', 110, alignRight: true),
  ];

  Future<Uint8List> generate(Invoice source) {
    final invoice = _latin1Only(source);
    final totals = calculator.totals(invoice.items);
    final document = pw.Document(
      title: 'Tax Invoice ${invoice.billNumber}',
      author: invoice.seller.name,
    );
    final theme = pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
    );
    final pageCount = math.max(1, (invoice.items.length / rowsPerPage).ceil());

    for (var page = 0; page < pageCount; page++) {
      final start = page * rowsPerPage;
      final end = math.min(start + rowsPerPage, invoice.items.length);
      final isLastPage = page == pageCount - 1;

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: theme,
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _title(),
              _header(invoice),
              pw.Expanded(
                child: _itemsTable(
                  invoice.items.sublist(start, end),
                  totals.lines.sublist(start, end),
                  firstSerial: start + 1,
                ),
              ),
              if (isLastPage) ...[
                _summary(invoice, totals),
                _footer(invoice, totals),
              ] else
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text(
                    'Continued on next page...',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              if (pageCount > 1)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'Page ${page + 1} of $pageCount',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return document.save();
  }

  /// The built-in Times font only covers Latin-1, so other characters typed
  /// into the form are replaced instead of breaking the PDF.
  Invoice _latin1Only(Invoice invoice) {
    String safe(String text) => text.replaceAll(RegExp(r'[^\x00-\xFF]'), '?');
    final buyer = invoice.buyer;

    return Invoice(
      seller: invoice.seller,
      sellerAddress: safe(invoice.sellerAddress),
      sellerGstin: safe(invoice.sellerGstin),
      billNumber: safe(invoice.billNumber),
      date: invoice.date,
      mode: invoice.mode,
      message: safe(invoice.message),
      buyer: BuyerDetails(
        name: safe(buyer.name),
        addressLine1: safe(buyer.addressLine1),
        addressLine2: safe(buyer.addressLine2),
        phone: safe(buyer.phone),
        gstin: safe(buyer.gstin),
        pan: safe(buyer.pan),
        dl20b: safe(buyer.dl20b),
        dl21b: safe(buyer.dl21b),
        partyCode: safe(buyer.partyCode),
        state: safe(buyer.state),
      ),
      items: [
        for (final item in invoice.items)
          InvoiceItem(
            productName: safe(item.productName),
            hsnCode: safe(item.hsnCode),
            manufacturer: safe(item.manufacturer),
            pack: safe(item.pack),
            batch: safe(item.batch),
            expiry: safe(item.expiry),
            mrpPaise: item.mrpPaise,
            revisedMrpPaise: item.revisedMrpPaise,
            quantityMilli: item.quantityMilli,
            freeMilli: item.freeMilli,
            ratePaise: item.ratePaise,
            discountBasisPoints: item.discountBasisPoints,
            gstPercent: item.gstPercent,
            marginBasisPoints: item.marginBasisPoints,
            scheme: item.scheme,
          ),
      ],
    );
  }

  pw.Widget _title() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Center(
        child: pw.Text(
          'TAX INVOICE',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  pw.Widget _header(Invoice invoice) {
    final seller = invoice.seller;
    final buyer = invoice.buyer;
    const text = pw.TextStyle(fontSize: 9);

    return pw.Table(
      border: pw.TableBorder.all(width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(870),
        1: pw.FlexColumnWidth(665),
        2: pw.FlexColumnWidth(330),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    seller.name,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(invoice.sellerAddress, style: text),
                  _twoUp(
                    _pair('PAN :', seller.pan),
                    pw.Text('Phone: ${seller.phone}', style: text),
                  ),
                  _twoUp(
                    _pair('D20B :', seller.dl20b),
                    _pair('D21B :', seller.dl21b),
                  ),
                  _twoUp(
                    _pair('GSTN:', invoice.sellerGstin, bold: true),
                    pw.Text('Tel -${seller.telephone}', style: text),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TO :  ', style: text),
                      pw.Expanded(
                        child: pw.Text(
                          buyer.name,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(buyer.addressLine1, style: text),
                  _twoUp(
                    pw.Text(buyer.addressLine2, style: text),
                    _pair('Ph No :', buyer.phone),
                  ),
                  _twoUp(
                    _pair('GSTN:', buyer.gstin),
                    _pair('Pan No:', buyer.pan),
                  ),
                  _twoUp(
                    _pair('DL.No. 20B:', buyer.dl20b, labelWidth: 52),
                    _pair('21B:', buyer.dl21b, boldLabel: true),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _metaRow('Party Code', buyer.partyCode),
                  pw.SizedBox(height: 8),
                  _metaRow('Mode', invoice.mode.label),
                  _metaRow('Bill No', invoice.billNumber, bold: true),
                  _metaRow('Date', formatInvoiceDate(invoice.date), bold: true),
                  pw.Text('State : ${buyer.state}', style: text),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _itemsTable(
    List<InvoiceItem> items,
    List<InvoiceLineTotals> lines, {
    required int firstSerial,
  }) {
    final width = pageFormat.availableWidth;
    final totalWeight = _columns.fold<double>(
      0,
      (sum, column) => sum + column.weight,
    );
    final widths = [
      for (final column in _columns) width * column.weight / totalWeight,
    ];
    final dividers = <double>[];
    var x = 0.0;
    for (var i = 0; i < widths.length - 1; i++) {
      x += widths[i];
      dividers.add(x);
    }

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: _line, right: _line, bottom: _line),
      ),
      child: pw.Stack(
        fit: pw.StackFit.expand,
        children: [
          // Column dividers run the full height, as on the printed bills.
          for (final divider in dividers)
            pw.Positioned(
              left: divider - 0.3,
              top: 0,
              bottom: 0,
              child: pw.Container(width: 0.6, color: PdfColors.black),
            ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 26,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: _line),
                ),
                child: pw.Row(
                  children: [
                    for (var i = 0; i < _columns.length; i++)
                      pw.SizedBox(
                        width: widths[i],
                        child: pw.Center(
                          child: pw.Text(
                            _columns[i].label,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              for (var row = 0; row < items.length; row++)
                pw.SizedBox(
                  height: 14,
                  child: pw.Row(
                    children: [
                      for (final (i, value) in _cells(
                        firstSerial + row,
                        items[row],
                        lines[row],
                      ).indexed)
                        pw.SizedBox(
                          width: widths[i],
                          child: pw.ClipRect(
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: pw.Align(
                                alignment: _columns[i].alignRight
                                    ? pw.Alignment.centerRight
                                    : pw.Alignment.centerLeft,
                                child: pw.Text(
                                  value,
                                  maxLines: 1,
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _cells(int serial, InvoiceItem item, InvoiceLineTotals line) {
    return [
      '$serial',
      item.manufacturer,
      item.hsnCode,
      item.productName,
      item.pack,
      item.batch,
      item.expiry,
      formatAmount(item.mrpPaise),
      formatAmount(item.revisedMrpPaise),
      formatQuantity(item.quantityMilli),
      item.freeMilli == 0 ? '' : formatQuantity(item.freeMilli),
      formatAmount(item.ratePaise),
      formatAmount(line.amountPaise),
      formatAmount(line.discountPaise),
      formatAmount(line.taxablePaise),
      '${item.gstPercent}',
      formatAmount(line.cgstPaise),
      formatAmount(line.sgstPaise),
      formatAmount(line.totalPaise),
    ];
  }

  pw.Widget _summary(Invoice invoice, InvoiceTotals totals) {
    const text = pw.TextStyle(fontSize: 9);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 90),
            child: pw.Text(
              'No.of Items :  ${totals.itemCount}'
              '                         '
              'No of Units :  ${formatQuantity(totals.unitsMilli)}',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 40),
              pw.Expanded(flex: 850, child: _slabTable(totals)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 420,
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Adj  ${formatAmount(totals.adjustmentPaise)}',
                          style: text,
                        ),
                        pw.Text(
                          'Roundoff  ${formatAmount(totals.roundOffPaise)}',
                          style: text,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    _bankBox(invoice.seller),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 520,
                child: pw.Column(
                  children: [
                    _totalRow('Gross Amount', totals.grossPaise),
                    _totalRow('Total Discount', totals.discountPaise),
                    _totalRow('Total Taxable Amount', totals.taxablePaise),
                    _totalRow('Total CGST', totals.cgstPaise),
                    _totalRow('Total SGST', totals.sgstPaise),
                    _totalRow('NET AMOUNT', totals.netPaise, emphasize: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Text(
                'Message : ',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(invoice.message, style: text),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _slabTable(InvoiceTotals totals) {
    const header = pw.TextStyle(fontSize: 10);
    const text = pw.TextStyle(fontSize: 8.5);

    pw.Widget row(List<String> values, pw.TextStyle style) {
      return pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              values[0],
              textAlign: pw.TextAlign.center,
              style: style,
            ),
          ),
          for (var i = 1; i < values.length; i++) ...[
            pw.SizedBox(
              width: 10,
              child: pw.Text(
                style == header ? '' : ':',
                textAlign: pw.TextAlign.center,
                style: style,
              ),
            ),
            pw.Expanded(
              flex: i == 1 ? 3 : 2,
              child: pw.Text(
                values[i],
                textAlign: style == header
                    ? pw.TextAlign.center
                    : pw.TextAlign.right,
                style: style,
              ),
            ),
          ],
        ],
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 1, horizontal: 3),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: _line),
            ),
            child: row([
              'Tax Rate',
              'Taxable Amount',
              'CGST Amt',
              'SGST Amt',
            ], header),
          ),
          for (final slab in totals.slabs)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 0.5,
                horizontal: 3,
              ),
              child: row(
                slab.taxablePaise == 0
                    ? ['${slab.gstPercent} %', '', '', '']
                    : [
                        '${slab.gstPercent} %',
                        formatAmount(slab.taxablePaise),
                        formatAmount(slab.cgstPaise),
                        formatAmount(slab.sgstPaise),
                      ],
                text,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _bankBox(SellerProfile seller) {
    const text = pw.TextStyle(fontSize: 8.5);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
      child: pw.Column(
        children: [
          pw.Text('Our Bank:', style: text),
          pw.Text(seller.bankName, style: text),
          pw.Text(seller.bankBranch, style: text),
          pw.Text('A/c No: ${seller.bankAccountNumber}', style: text),
          pw.Text('IFSC : ${seller.bankIfsc}', style: text),
        ],
      ),
    );
  }

  pw.Widget _totalRow(String label, int paise, {bool emphasize = false}) {
    final style = pw.TextStyle(
      fontSize: emphasize ? 10 : 9,
      fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 14, child: pw.Text(':', style: style)),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              formatAmount(paise),
              textAlign: pw.TextAlign.right,
              style: emphasize
                  ? pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)
                  : pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(Invoice invoice, InvoiceTotals totals) {
    const height = 54.0;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1280,
            child: pw.SizedBox(
              height: height,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'In Words :  ${rupeesInWords(totals.netPaise)}',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ),
                  pw.Container(height: 0.8, color: PdfColors.black),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      _legalText,
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Container(width: 0.8, height: height, color: PdfColors.black),
          pw.Expanded(
            flex: 590,
            child: pw.SizedBox(
              height: height,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          'For',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            invoice.seller.name,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      'Authorised Signatory',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _twoUp(pw.Widget left, pw.Widget right) {
    return pw.Row(
      children: [
        pw.Expanded(child: left),
        pw.Expanded(child: right),
      ],
    );
  }

  pw.Widget _pair(
    String label,
    String value, {
    bool bold = false,
    bool boldLabel = false,
    double labelWidth = 42,
  }) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: labelWidth,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold || boldLabel
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _metaRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 52,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Expanded(
          child: pw.Text(
            ': $value',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemColumn {
  const _ItemColumn(this.label, this.weight, {this.alignRight = false});

  final String label;
  final double weight;
  final bool alignRight;
}
