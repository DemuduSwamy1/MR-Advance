import '../domain/models/invoice.dart';
import '../domain/services/invoice_calculator.dart';

/// Converts a generated invoice into the record saved in the cloud.
///
/// Money is kept in whole paise (as calculated) and also as rupees, which are
/// easier to read in the Firebase console.
Map<String, Object?> billRecord(Invoice invoice, InvoiceTotals totals) {
  final buyer = invoice.buyer;

  return {
    'billNumber': invoice.billNumber,
    'billDate': _dateOnly(invoice.date),
    'mode': invoice.mode.label,
    'seller': {
      'name': invoice.seller.name,
      'address': invoice.sellerAddress,
      'gstin': invoice.sellerGstin,
    },
    'customer': {
      'name': buyer.name,
      'addressLine1': buyer.addressLine1,
      'addressLine2': buyer.addressLine2,
      'phone': buyer.phone,
      'gstin': buyer.gstin,
      'pan': buyer.pan,
      'dl20b': buyer.dl20b,
      'dl21b': buyer.dl21b,
      'partyCode': buyer.partyCode,
      'state': buyer.state,
    },
    'items': [
      for (var i = 0; i < invoice.items.length; i++)
        _itemRecord(invoice.items[i], totals.lines[i]),
    ],
    'totals': {
      'itemCount': totals.itemCount,
      'units': totals.unitsMilli / 1000,
      'grossPaise': totals.grossPaise,
      'discountPaise': totals.discountPaise,
      'taxablePaise': totals.taxablePaise,
      'cgstPaise': totals.cgstPaise,
      'sgstPaise': totals.sgstPaise,
      'roundOffPaise': totals.roundOffPaise,
      'netPaise': totals.netPaise,
    },
    'netAmount': totals.netPaise / 100,
    'message': invoice.message,
  };
}

Map<String, Object?> _itemRecord(InvoiceItem item, InvoiceLineTotals line) {
  return {
    'productName': item.productName,
    'hsnCode': item.hsnCode,
    'manufacturer': item.manufacturer,
    'pack': item.pack,
    'batch': item.batch,
    'expiry': item.expiry,
    'mrpPaise': item.mrpPaise,
    'revisedMrpPaise': item.revisedMrpPaise,
    'quantity': item.quantityMilli / 1000,
    'free': item.freeMilli / 1000,
    'ratePaise': item.ratePaise,
    'discountPaise': item.discountPaise,
    'gstPercent': item.gstPercent,
    'taxablePaise': line.taxablePaise,
    'cgstPaise': line.cgstPaise,
    'sgstPaise': line.sgstPaise,
    'totalPaise': line.totalPaise,
  };
}

/// One document per bill and device: generating the same bill again (for
/// example after a correction) updates it instead of adding a duplicate.
String billDocumentId({
  required String userId,
  required String billNumber,
  required DateTime date,
}) {
  final safeBill = billNumber.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
  return '${userId}_${safeBill}_${_dateOnly(date)}';
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
