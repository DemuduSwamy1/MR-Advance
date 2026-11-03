import 'package:flutter/material.dart';

import '../../../core/utils/file_name_utils.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import '../../../core/widgets/primary_action_button.dart';
import '../domain/models/invoice.dart';
import '../domain/services/invoice_calculator.dart';
import '../domain/services/invoice_pdf_generator.dart';
import 'widgets/invoice_item_sheet.dart';
import 'widgets/invoice_totals_card.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  static const _seller = SellerProfile.ravitejaMedicals;
  static const _billPrefix = 'RS ';

  final _formKey = GlobalKey<FormState>();
  final _calculator = const InvoiceCalculator();
  final _pdfGenerator = const InvoicePdfGenerator();

  final _billNumber = TextEditingController(text: _billPrefix);
  final _sellerAddress = TextEditingController(text: _seller.defaultAddress);
  final _sellerGstin = TextEditingController(text: _seller.defaultGstin);
  final _buyerName = TextEditingController();
  final _buyerAddressLine1 = TextEditingController();
  final _buyerAddressLine2 = TextEditingController();
  final _buyerGstin = TextEditingController();
  final _buyerPhone = TextEditingController();
  final _buyerPan = TextEditingController();
  final _buyerDl20b = TextEditingController();
  final _buyerDl21b = TextEditingController();
  final _partyCode = TextEditingController();
  final _state = TextEditingController(text: _seller.defaultState);
  final _message = TextEditingController();

  late final _controllers = [
    _billNumber,
    _sellerAddress,
    _sellerGstin,
    _buyerName,
    _buyerAddressLine1,
    _buyerAddressLine2,
    _buyerGstin,
    _buyerPhone,
    _buyerPan,
    _buyerDl20b,
    _buyerDl21b,
    _partyCode,
    _state,
    _message,
  ];

  DateTime _date = DateTime.now();
  PaymentMode _mode = PaymentMode.credit;
  final List<InvoiceItem> _items = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculator.totals(_items);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          // A scroll view (not a lazy ListView) keeps every field built, so
          // validation also covers fields scrolled out of view.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: 'Bill details',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _field(
                                _billNumber,
                                'Bill No',
                                capitalize: true,
                                validator: (value) =>
                                    RegExp(r'\d').hasMatch(value ?? '')
                                    ? null
                                    : 'Enter the bill number',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _dateField()),
                          ],
                        ),
                        SegmentedButton<PaymentMode>(
                          segments: const [
                            ButtonSegment(
                              value: PaymentMode.credit,
                              label: Text('Credit'),
                            ),
                            ButtonSegment(
                              value: PaymentMode.cash,
                              label: Text('Cash'),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (selection) =>
                              setState(() => _mode = selection.first),
                        ),
                      ],
                    ),
                    _Section(
                      title: 'From: ${_seller.name}',
                      children: [
                        _field(
                          _sellerAddress,
                          'Address',
                          required: true,
                          maxLines: 2,
                          capitalize: true,
                        ),
                        _field(
                          _sellerGstin,
                          'GSTIN',
                          required: true,
                          capitalize: true,
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Bill to',
                      children: [
                        _field(
                          _buyerName,
                          'Customer name',
                          required: true,
                          capitalize: true,
                        ),
                        _field(
                          _buyerAddressLine1,
                          'Address line 1',
                          capitalize: true,
                        ),
                        _field(
                          _buyerAddressLine2,
                          'Address line 2',
                          capitalize: true,
                        ),
                        _field(_buyerGstin, 'GSTIN', capitalize: true),
                        ExpansionTile(
                          title: const Text('More customer details'),
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 8),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          children: [
                            _field(
                              _buyerPhone,
                              'Phone',
                              keyboardType: TextInputType.phone,
                            ),
                            _field(_buyerPan, 'PAN', capitalize: true),
                            Row(
                              children: [
                                Expanded(
                                  child: _field(
                                    _buyerDl20b,
                                    'DL No. 20B',
                                    capitalize: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field(
                                    _buyerDl21b,
                                    'DL No. 21B',
                                    capitalize: true,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _field(_partyCode, 'Party code'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: _field(_state, 'State')),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Items (${_items.length})',
                      children: [
                        if (_items.isEmpty)
                          Text(
                            'No items yet. Add the medicines on this bill.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        for (var i = 0; i < _items.length; i++)
                          _ItemTile(
                            serial: i + 1,
                            item: _items[i],
                            line: totals.lines[i],
                            onTap: () => _editItem(i),
                            onDelete: () => setState(() => _items.removeAt(i)),
                          ),
                        OutlinedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add item'),
                        ),
                      ],
                    ),
                    InvoiceTotalsCard(totals: totals),
                    const SizedBox(height: 16),
                    _field(_message, 'Message (optional)'),
                    PrimaryActionButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: _isGenerating
                          ? 'Generating...'
                          : 'Generate Invoice PDF',
                      onPressed: _isGenerating ? null : _generate,
                      isLoading: _isGenerating,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isGenerating ? null : _confirmNewInvoice,
                      icon: const Icon(Icons.note_add_outlined),
                      label: const Text('New invoice'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool capitalize = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: required || validator != null ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: capitalize
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
        validator:
            validator ??
            (required
                ? (value) => (value ?? '').trim().isEmpty ? 'Required' : null
                : null),
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
          child: Text(formatInvoiceDate(_date)),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _addItem() async {
    final item = await showInvoiceItemSheet(
      context,
      defaults: _items.isEmpty ? null : _items.last,
    );
    if (item != null) {
      setState(() => _items.add(item));
    }
  }

  Future<void> _editItem(int index) async {
    final item = await showInvoiceItemSheet(context, initial: _items[index]);
    if (item != null) {
      setState(() => _items[index] = item);
    }
  }

  Invoice _buildInvoice() {
    return Invoice(
      seller: _seller,
      sellerAddress: _sellerAddress.text.trim(),
      sellerGstin: _sellerGstin.text.trim(),
      billNumber: _billNumber.text.trim(),
      date: _date,
      mode: _mode,
      message: _message.text.trim(),
      buyer: BuyerDetails(
        name: _buyerName.text.trim(),
        addressLine1: _buyerAddressLine1.text.trim(),
        addressLine2: _buyerAddressLine2.text.trim(),
        phone: _buyerPhone.text.trim(),
        gstin: _buyerGstin.text.trim(),
        pan: _buyerPan.text.trim(),
        dl20b: _buyerDl20b.text.trim(),
        dl21b: _buyerDl21b.text.trim(),
        partyCode: _partyCode.text.trim(),
        state: _state.text.trim(),
      ),
      items: List.unmodifiable(_items),
    );
  }

  Future<void> _generate() async {
    final invalidFields = _formKey.currentState!.validateGranularly();
    if (invalidFields.isNotEmpty) {
      // The first problem may be scrolled out of view, so bring it back.
      Scrollable.ensureVisible(
        invalidFields.first.context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 300),
      );
      _showMessage('Fill in the required fields.');
      return;
    }
    if (_items.isEmpty) {
      _showMessage('Add at least one item.');
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final invoice = _buildInvoice();
      final bytes = await _pdfGenerator.generate(invoice);
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            pdfBytes: bytes,
            fileName: pdfFileNameForSource('Invoice ${invoice.billNumber}.pdf'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not generate the invoice: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _confirmNewInvoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new invoice?'),
        content: const Text(
          'This clears the customer, items and message. Seller details are '
          'kept and the bill number moves to the next one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('New invoice'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      for (final controller in [
        _buyerName,
        _buyerAddressLine1,
        _buyerAddressLine2,
        _buyerGstin,
        _buyerPhone,
        _buyerPan,
        _buyerDl20b,
        _buyerDl21b,
        _partyCode,
        _message,
      ]) {
        controller.clear();
      }
      _state.text = _seller.defaultState;
      _billNumber.text = _nextBillNumber(_billNumber.text);
      _date = DateTime.now();
      _mode = PaymentMode.credit;
      _items.clear();
    });
  }

  /// "RS 3387" becomes "RS 3388"; anything without a trailing number resets
  /// to the prefix.
  String _nextBillNumber(String current) {
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(current.trim());
    if (match == null) {
      return _billPrefix;
    }
    final digits = match.group(2)!;
    final next = (int.parse(digits) + 1).toString().padLeft(digits.length, '0');
    return '${match.group(1)}$next';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.serial,
    required this.item,
    required this.line,
    required this.onTap,
    required this.onDelete,
  });

  final int serial;
  final InvoiceItem item;
  final InvoiceLineTotals line;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final details = [
      if (item.hsnCode.isNotEmpty) 'HSN ${item.hsnCode}',
      'Qty ${formatQuantity(item.quantityMilli)}'
          '${item.freeMilli > 0 ? ' + ${formatQuantity(item.freeMilli)} free' : ''}',
      'Rate ${formatAmount(item.ratePaise)}',
      'GST ${item.gstPercent}%',
    ].join('  ·  ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(radius: 14, child: Text('$serial')),
      title: Text(item.productName),
      subtitle: Text(details),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatAmount(line.totalPaise),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Remove item',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
