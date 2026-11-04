import '../../../../core/utils/number_format.dart';
import '../models/invoice.dart';

class InvoiceLineTotals {
  const InvoiceLineTotals({
    required this.amountPaise,
    required this.discountPaise,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.totalPaise,
  });

  final int amountPaise;
  final int discountPaise;
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int totalPaise;
}

class TaxSlabTotals {
  const TaxSlabTotals({
    required this.gstPercent,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
  });

  final int gstPercent;
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
}

class InvoiceTotals {
  const InvoiceTotals({
    required this.lines,
    required this.slabs,
    required this.itemCount,
    required this.unitsMilli,
    required this.grossPaise,
    required this.discountPaise,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.adjustmentPaise,
    required this.roundOffPaise,
    required this.netPaise,
  });

  final List<InvoiceLineTotals> lines;
  final List<TaxSlabTotals> slabs;
  final int itemCount;
  final int unitsMilli;
  final int grossPaise;
  final int discountPaise;
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int adjustmentPaise;
  final int roundOffPaise;
  final int netPaise;
}

/// Applies the tax invoice rules: CGST and SGST are each half the GST rate,
/// invoice tax is computed per GST slab, and the net amount is rounded to the
/// nearest rupee.
class InvoiceCalculator {
  const InvoiceCalculator();

  static const gstRates = [0, 5, 12, 18, 28];

  InvoiceLineTotals lineTotals(InvoiceItem item) {
    final amount = roundHalfUpDiv(item.ratePaise * item.quantityMilli, 1000);
    // The discount is an amount typed in by hand, not a percentage.
    final discount = item.discountPaise;
    final taxable = amount - discount;
    final halfTax = roundHalfUpDiv(taxable * item.gstPercent, 200);

    return InvoiceLineTotals(
      amountPaise: amount,
      discountPaise: discount,
      taxablePaise: taxable,
      cgstPaise: halfTax,
      sgstPaise: halfTax,
      totalPaise: taxable + roundHalfUpDiv(taxable * item.gstPercent, 100),
    );
  }

  /// Rate to the retailer: the MRP without GST, less the retailer margin.
  /// With 5% GST and a 20% margin, an MRP of 189.83 gives 144.63.
  int rateFromMrp({
    required int mrpPaise,
    required int gstPercent,
    required int marginBasisPoints,
  }) {
    return roundHalfUpDiv(
      mrpPaise * 100 * (10000 - marginBasisPoints),
      (100 + gstPercent) * 10000,
    );
  }

  /// Free quantity for a "buy + free" scheme such as "10+1": buying 130 gives
  /// 13 free. Returns null when [scheme] is not in that form.
  int? freeForScheme({required int quantityMilli, required String scheme}) {
    final match = schemePattern.firstMatch(scheme);
    if (match == null) {
      return null;
    }
    final buy = int.parse(match.group(1)!);
    final free = int.parse(match.group(2)!);
    if (buy == 0) {
      return null;
    }
    return quantityMilli ~/ (buy * 1000) * free * 1000;
  }

  static final schemePattern = RegExp(r'^\s*(\d+)\s*\+\s*(\d+)\s*$');

  InvoiceTotals totals(List<InvoiceItem> items, {int adjustmentPaise = 0}) {
    final lines = items.map(lineTotals).toList();
    final taxableByRate = {for (final rate in gstRates) rate: 0};
    for (var i = 0; i < items.length; i++) {
      taxableByRate.update(
        items[i].gstPercent,
        (value) => value + lines[i].taxablePaise,
        ifAbsent: () => lines[i].taxablePaise,
      );
    }

    final rates = taxableByRate.keys.toList()..sort();
    final slabs = [
      for (final rate in rates)
        TaxSlabTotals(
          gstPercent: rate,
          taxablePaise: taxableByRate[rate]!,
          cgstPaise: roundHalfUpDiv(taxableByRate[rate]! * rate, 200),
          sgstPaise: roundHalfUpDiv(taxableByRate[rate]! * rate, 200),
        ),
    ];

    final gross = _sum(lines.map((line) => line.amountPaise));
    final discount = _sum(lines.map((line) => line.discountPaise));
    final taxable = _sum(lines.map((line) => line.taxablePaise));
    final cgst = _sum(slabs.map((slab) => slab.cgstPaise));
    final sgst = _sum(slabs.map((slab) => slab.sgstPaise));
    final beforeRounding = taxable + cgst + sgst + adjustmentPaise;
    final net = roundHalfUpDiv(beforeRounding, 100) * 100;

    return InvoiceTotals(
      lines: lines,
      slabs: slabs,
      itemCount: items.length,
      unitsMilli: _sum(
        items.map((item) => item.quantityMilli + item.freeMilli),
      ),
      grossPaise: gross,
      discountPaise: discount,
      taxablePaise: taxable,
      cgstPaise: cgst,
      sgstPaise: sgst,
      adjustmentPaise: adjustmentPaise,
      roundOffPaise: net - beforeRounding,
      netPaise: net,
    );
  }

  int _sum(Iterable<int> values) => values.fold(0, (sum, value) => sum + value);
}
