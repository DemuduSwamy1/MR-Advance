import 'package:flutter/material.dart';

import '../../../../core/utils/amount_in_words.dart';
import '../../../../core/utils/number_format.dart';
import '../../domain/services/invoice_calculator.dart';

class InvoiceTotalsCard extends StatelessWidget {
  const InvoiceTotalsCard({super.key, required this.totals});

  final InvoiceTotals totals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final taxedSlabs = totals.slabs.where((slab) => slab.taxablePaise != 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Totals', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(context, 'Items', '${totals.itemCount}'),
            _row(context, 'Units', formatQuantity(totals.unitsMilli)),
            const Divider(height: 20),
            _row(context, 'Gross amount', formatAmount(totals.grossPaise)),
            _row(context, 'Discount', formatAmount(totals.discountPaise)),
            _row(context, 'Taxable amount', formatAmount(totals.taxablePaise)),
            for (final slab in taxedSlabs)
              _row(
                context,
                'GST ${slab.gstPercent}% on ${formatAmount(slab.taxablePaise)}',
                '${formatAmount(slab.cgstPaise)} + '
                    '${formatAmount(slab.sgstPaise)}',
                muted: true,
              ),
            _row(context, 'Total CGST', formatAmount(totals.cgstPaise)),
            _row(context, 'Total SGST', formatAmount(totals.sgstPaise)),
            _row(context, 'Round off', formatAmount(totals.roundOffPaise)),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Net amount',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '₹ ${formatAmount(totals.netPaise)}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              rupeesInWords(totals.netPaise),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool muted = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final color = muted ? Theme.of(context).colorScheme.onSurfaceVariant : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
          Text(value, style: textTheme.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
