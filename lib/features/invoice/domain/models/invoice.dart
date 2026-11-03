/// Seller details printed on every invoice. Only the address and GSTIN can be
/// changed per invoice; they start from [defaultAddress] and [defaultGstin].
class SellerProfile {
  const SellerProfile({
    required this.name,
    required this.pan,
    required this.phone,
    required this.telephone,
    required this.dl20b,
    required this.dl21b,
    required this.bankName,
    required this.bankBranch,
    required this.bankAccountNumber,
    required this.bankIfsc,
    required this.defaultAddress,
    required this.defaultGstin,
    required this.defaultState,
  });

  static const ravitejaMedicals = SellerProfile(
    name: 'RAVITEJA MEDICALS.',
    pan: 'AAOFR6325',
    phone: '9885962929 / 7032546429',
    telephone: '9885962929',
    dl20b: '21/AP/VZ/2012/W/RL',
    dl21b: '21/AP/VZ/2012/W/RL',
    bankName: 'The State Bank Of India',
    bankBranch: 'SME Branch, Vizianagaram.',
    bankAccountNumber: '45011073835',
    bankIfsc: 'SBIN0063651',
    defaultAddress: '16-7-1, GURAJADAAPPRAO ROAD, VIZIANAGARAM',
    defaultGstin: '37AAOFR6325H1ZU',
    defaultState: 'Andhra Pradesh',
  );

  final String name;
  final String pan;
  final String phone;
  final String telephone;
  final String dl20b;
  final String dl21b;
  final String bankName;
  final String bankBranch;
  final String bankAccountNumber;
  final String bankIfsc;
  final String defaultAddress;
  final String defaultGstin;
  final String defaultState;
}

class BuyerDetails {
  const BuyerDetails({
    required this.name,
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phone = '',
    this.gstin = '',
    this.pan = '',
    this.dl20b = '',
    this.dl21b = '',
    this.partyCode = '',
    this.state = '',
  });

  final String name;
  final String addressLine1;
  final String addressLine2;
  final String phone;
  final String gstin;
  final String pan;
  final String dl20b;
  final String dl21b;
  final String partyCode;
  final String state;
}

enum PaymentMode {
  credit('CREDIT'),
  cash('CASH');

  const PaymentMode(this.label);

  final String label;
}

/// One medicine row. Money is in paise, quantities in thousandths and the
/// discount and margin in basis points (1% = 100) so calculations stay exact.
/// [marginBasisPoints] and [scheme] only drive the automatic rate and free
/// quantity while editing; they are not printed.
class InvoiceItem {
  const InvoiceItem({
    required this.productName,
    required this.quantityMilli,
    required this.ratePaise,
    this.hsnCode = '',
    this.manufacturer = '',
    this.pack = '',
    this.batch = '',
    this.expiry = '',
    this.mrpPaise = 0,
    this.revisedMrpPaise = 0,
    this.freeMilli = 0,
    this.discountBasisPoints = 0,
    this.gstPercent = 5,
    this.marginBasisPoints = InvoiceItem.defaultMarginBasisPoints,
    this.scheme = '',
  });

  /// Usual retailer margin on pharma bills: 20%.
  static const defaultMarginBasisPoints = 2000;

  final String productName;
  final String hsnCode;
  final String manufacturer;
  final String pack;
  final String batch;
  final String expiry;
  final int mrpPaise;
  final int revisedMrpPaise;
  final int quantityMilli;
  final int freeMilli;
  final int ratePaise;
  final int discountBasisPoints;
  final int gstPercent;
  final int marginBasisPoints;
  final String scheme;
}

class Invoice {
  const Invoice({
    required this.seller,
    required this.sellerAddress,
    required this.sellerGstin,
    required this.billNumber,
    required this.date,
    required this.mode,
    required this.buyer,
    required this.items,
    this.message = '',
  });

  final SellerProfile seller;
  final String sellerAddress;
  final String sellerGstin;
  final String billNumber;
  final DateTime date;
  final PaymentMode mode;
  final BuyerDetails buyer;
  final List<InvoiceItem> items;
  final String message;
}

const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a date as printed on the invoice, e.g. "29/Jul/2026".
String formatInvoiceDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  return '$day/${_monthAbbreviations[date.month - 1]}/${date.year}';
}
