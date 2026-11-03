import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/number_format.dart';
import '../../../../core/widgets/month_year_picker.dart';
import '../../domain/models/invoice.dart';
import '../../domain/services/invoice_calculator.dart';

/// Opens a bottom sheet for adding or editing one medicine row. A new item
/// starts with the HSN code, GST and margin of [defaults], usually the
/// previous item.
Future<InvoiceItem?> showInvoiceItemSheet(
  BuildContext context, {
  InvoiceItem? initial,
  InvoiceItem? defaults,
}) {
  return showModalBottomSheet<InvoiceItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => InvoiceItemSheet(initial: initial, defaults: defaults),
  );
}

class InvoiceItemSheet extends StatefulWidget {
  const InvoiceItemSheet({super.key, this.initial, this.defaults});

  final InvoiceItem? initial;
  final InvoiceItem? defaults;

  @override
  State<InvoiceItemSheet> createState() => _InvoiceItemSheetState();
}

class _InvoiceItemSheetState extends State<InvoiceItemSheet> {
  static const _defaultHsnCode = '300490';
  static const _calculator = InvoiceCalculator();

  final _formKey = GlobalKey<FormState>();
  late final _productName = TextEditingController(
    text: widget.initial?.productName,
  );
  late final _hsnCode = TextEditingController(
    text:
        widget.initial?.hsnCode ?? widget.defaults?.hsnCode ?? _defaultHsnCode,
  );
  late final _manufacturer = TextEditingController(
    text: widget.initial?.manufacturer,
  );
  late final _pack = TextEditingController(text: widget.initial?.pack);
  late final _batch = TextEditingController(text: widget.initial?.batch);
  late final _expiry = TextEditingController(text: widget.initial?.expiry);
  late final _mrp = _scaledController(widget.initial?.mrpPaise, 2);
  late final _revisedMrp = _scaledController(
    widget.initial?.revisedMrpPaise,
    2,
  );
  late final _margin = TextEditingController(
    text: formatEditable(
      widget.initial?.marginBasisPoints ??
          widget.defaults?.marginBasisPoints ??
          InvoiceItem.defaultMarginBasisPoints,
      decimals: 2,
    ),
  );
  late final _quantity = _scaledController(widget.initial?.quantityMilli, 3);
  late final _scheme = TextEditingController(text: widget.initial?.scheme);
  late final _free = _scaledController(widget.initial?.freeMilli, 3);
  late final _rate = TextEditingController(
    text: widget.initial == null ? '' : _plainAmount(widget.initial!.ratePaise),
  );
  late final _discount = _scaledController(
    widget.initial?.discountBasisPoints,
    2,
  );
  late int _gstPercent =
      widget.initial?.gstPercent ?? widget.defaults?.gstPercent ?? 5;

  // Rate and free quantity follow the other fields until the user types
  // their own value; the refresh button switches back to the calculation.
  late bool _rateIsManual = _initialRateIsManual();
  late bool _freeIsManual = _initialFreeIsManual();

  late final _controllers = [
    _productName,
    _hsnCode,
    _manufacturer,
    _pack,
    _batch,
    _expiry,
    _mrp,
    _revisedMrp,
    _margin,
    _quantity,
    _scheme,
    _free,
    _rate,
    _discount,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.initial != null;
    final preview = _tryBuildItem();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit item' : 'Add item',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _textField(_productName, 'Medicine name', required: true),
              _row([
                _textField(_hsnCode, 'HSN code', numeric: true),
                _textField(_manufacturer, 'MFR'),
              ]),
              _row([
                _textField(_pack, 'Pack'),
                _textField(_batch, 'Batch'),
                _expiryField(),
              ]),
              _row([
                _numberField(
                  _mrp,
                  'M.R.P',
                  decimals: 2,
                  onChanged: (_) => _recalculate(),
                ),
                _gstField(),
              ]),
              _row([
                _numberField(
                  _margin,
                  'Margin %',
                  decimals: 2,
                  maximum: 10000,
                  onChanged: (_) => _recalculate(),
                ),
                _rateField(),
              ]),
              _row([
                _numberField(
                  _quantity,
                  'Qty',
                  decimals: 3,
                  required: true,
                  positive: true,
                  onChanged: (_) => _recalculate(),
                ),
                _schemeField(),
                _freeField(),
              ]),
              _row([
                _numberField(_discount, 'Disc %', decimals: 2, maximum: 10000),
                _numberField(_revisedMrp, 'Rev. M.R.P', decimals: 2),
              ]),
              const SizedBox(height: 4),
              if (preview != null) _LinePreview(item: preview),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEditing ? Icons.check : Icons.add),
                label: Text(isEditing ? 'Save item' : 'Add item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> fields) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: fields[i]),
        ],
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.characters,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        textInputAction: TextInputAction.next,
        validator: required
            ? (value) => (value ?? '').trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required int decimals,
    bool required = false,
    bool positive = false,
    int? maximum,
    ValueChanged<String>? onChanged,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          helperText: helperText,
          helperMaxLines: 2,
          suffixIcon: suffixIcon,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onChanged: onChanged ?? (_) => setState(() {}),
        validator: (value) {
          final text = (value ?? '').trim();
          if (text.isEmpty) {
            return required ? 'Required' : null;
          }
          final parsed = parseScaled(text, decimals: decimals);
          if (parsed == null) {
            return 'Max $decimals decimals';
          }
          if (positive && parsed == 0) {
            return 'Must be more than 0';
          }
          if (maximum != null && parsed > maximum) {
            return 'Too large';
          }
          return null;
        },
      ),
    );
  }

  Widget _gstField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: _gstPercent,
        decoration: const InputDecoration(
          labelText: 'GST %',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final rate in InvoiceCalculator.gstRates)
            DropdownMenuItem(value: rate, child: Text('$rate %')),
        ],
        onChanged: (value) {
          _gstPercent = value ?? _gstPercent;
          _recalculate();
        },
      ),
    );
  }

  Widget _rateField() {
    final canCalculate = _autoRate != null;

    return _numberField(
      _rate,
      'Rate',
      decimals: 2,
      required: true,
      helperText: _rateIsManual
          ? 'Entered manually'
          : 'Auto: MRP less GST and margin',
      suffixIcon: _rateIsManual && canCalculate
          ? IconButton(
              tooltip: 'Calculate from MRP',
              icon: const Icon(Icons.autorenew),
              onPressed: () {
                _rateIsManual = false;
                _recalculate();
              },
            )
          : null,
      onChanged: (_) => setState(() => _rateIsManual = true),
    );
  }

  Widget _schemeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _scheme,
        decoration: const InputDecoration(
          labelText: 'Scheme',
          hintText: '10+1',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]'))],
        onChanged: (_) => _recalculate(),
        validator: (value) {
          final text = (value ?? '').trim();
          if (text.isEmpty) {
            return null;
          }
          return _calculator.freeForScheme(quantityMilli: 0, scheme: text) ==
                  null
              ? 'Like 10+1'
              : null;
        },
      ),
    );
  }

  Widget _freeField() {
    final canCalculate = _autoFree != null;

    return _numberField(
      _free,
      'Free',
      decimals: 3,
      helperText: canCalculate && !_freeIsManual ? 'From scheme' : null,
      suffixIcon: _freeIsManual && canCalculate
          ? IconButton(
              tooltip: 'Calculate from scheme',
              icon: const Icon(Icons.autorenew),
              onPressed: () {
                _freeIsManual = false;
                _recalculate();
              },
            )
          : null,
      onChanged: (_) => setState(() => _freeIsManual = true),
    );
  }

  Widget _expiryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _expiry,
        readOnly: true,
        onTap: _pickExpiry,
        decoration: InputDecoration(
          labelText: 'Expiry',
          hintText: 'MM/YY',
          border: const OutlineInputBorder(),
          suffixIcon: _expiry.text.isEmpty
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: 'Clear expiry',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_expiry.clear),
                ),
        ),
      ),
    );
  }

  Future<void> _pickExpiry() async {
    final picked = await showMonthYearPicker(
      context,
      initial: parseMonthYear(_expiry.text),
      title: 'Expiry month',
    );
    if (picked != null) {
      setState(() => _expiry.text = formatMonthYear(picked));
    }
  }

  TextEditingController _scaledController(int? value, int decimals) {
    return TextEditingController(
      text: value == null || value == 0
          ? ''
          : formatEditable(value, decimals: decimals),
    );
  }

  /// Rate from MRP, GST and margin, or null until there is an MRP.
  int? get _autoRate {
    final mrp = parseScaled(_mrp.text, decimals: 2);
    final margin = _margin.text.trim().isEmpty
        ? 0
        : parseScaled(_margin.text, decimals: 2);
    if (mrp == null || mrp == 0 || margin == null || margin > 10000) {
      return null;
    }
    return _calculator.rateFromMrp(
      mrpPaise: mrp,
      gstPercent: _gstPercent,
      marginBasisPoints: margin,
    );
  }

  /// Free quantity from the scheme, or null without a valid scheme and qty.
  int? get _autoFree {
    final quantity = parseScaled(_quantity.text, decimals: 3);
    if (quantity == null) {
      return null;
    }
    return _calculator.freeForScheme(
      quantityMilli: quantity,
      scheme: _scheme.text,
    );
  }

  void _recalculate() {
    setState(() {
      if (!_rateIsManual) {
        final rate = _autoRate;
        _rate.text = rate == null ? '' : _plainAmount(rate);
      }
      if (!_freeIsManual) {
        final free = _autoFree;
        _free.text = free == null || free == 0
            ? ''
            : formatEditable(free, decimals: 3);
      }
    });
  }

  bool _initialRateIsManual() {
    final item = widget.initial;
    if (item == null) {
      return false;
    }
    return item.mrpPaise == 0 ||
        item.ratePaise !=
            _calculator.rateFromMrp(
              mrpPaise: item.mrpPaise,
              gstPercent: item.gstPercent,
              marginBasisPoints: item.marginBasisPoints,
            );
  }

  bool _initialFreeIsManual() {
    final item = widget.initial;
    if (item == null) {
      return false;
    }
    final free = _calculator.freeForScheme(
      quantityMilli: item.quantityMilli,
      scheme: item.scheme,
    );
    return free == null ? item.freeMilli != 0 : free != item.freeMilli;
  }

  static String _plainAmount(int paise) =>
      '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';

  /// Builds the item from the current input, or null while it is incomplete.
  InvoiceItem? _tryBuildItem() {
    int? optional(TextEditingController controller, int decimals) {
      final text = controller.text.trim();
      return text.isEmpty ? 0 : parseScaled(text, decimals: decimals);
    }

    final quantity = parseScaled(_quantity.text, decimals: 3);
    final rate = parseScaled(_rate.text, decimals: 2);
    final mrp = optional(_mrp, 2);
    final revisedMrp = optional(_revisedMrp, 2);
    final free = optional(_free, 3);
    final discount = optional(_discount, 2);
    final margin = optional(_margin, 2);
    if (quantity == null ||
        quantity == 0 ||
        rate == null ||
        mrp == null ||
        revisedMrp == null ||
        free == null ||
        discount == null ||
        discount > 10000 ||
        margin == null ||
        margin > 10000) {
      return null;
    }

    return InvoiceItem(
      productName: _productName.text.trim().toUpperCase(),
      hsnCode: _hsnCode.text.trim(),
      manufacturer: _manufacturer.text.trim().toUpperCase(),
      pack: _pack.text.trim().toUpperCase(),
      batch: _batch.text.trim().toUpperCase(),
      expiry: _expiry.text.trim(),
      mrpPaise: mrp,
      revisedMrpPaise: revisedMrp,
      quantityMilli: quantity,
      freeMilli: free,
      ratePaise: rate,
      discountBasisPoints: discount,
      gstPercent: _gstPercent,
      marginBasisPoints: margin,
      scheme: _scheme.text.replaceAll(' ', ''),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final item = _tryBuildItem();
    if (item != null) {
      Navigator.of(context).pop(item);
    }
  }
}

/// Shows the calculated values for the item being edited.
class _LinePreview extends StatelessWidget {
  const _LinePreview({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final line = const InvoiceCalculator().lineTotals(item);

    Widget value(String label, int paise) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(formatAmount(paise), style: textTheme.bodyMedium),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              value('Amount', line.amountPaise),
              value('Discount', line.discountPaise),
              value('Taxable', line.taxablePaise),
              value('CGST', line.cgstPaise),
              value('SGST', line.sgstPaise),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Line total  ₹ ${formatAmount(line.totalPaise)}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
