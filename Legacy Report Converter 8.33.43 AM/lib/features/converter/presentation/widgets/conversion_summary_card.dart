import 'package:flutter/material.dart';

import '../../../../core/utils/byte_utils.dart';
import '../../domain/models/conversion_result.dart';

class ConversionSummaryCard extends StatelessWidget {
  const ConversionSummaryCard({super.key, required this.result});

  final ConversionResult result;

  @override
  Widget build(BuildContext context) {
    final validation = result.validation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversion result',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  label: 'Source bytes',
                  value: formatByteCount(validation.sourceByteCount),
                  icon: Icons.sd_storage_outlined,
                ),
                _MetricTile(
                  label: 'Source lines',
                  value: validation.sourceLineCount.toString(),
                  icon: Icons.format_list_numbered_outlined,
                ),
                _MetricTile(
                  label: 'Converted lines',
                  value: validation.convertedLineCount.toString(),
                  icon: Icons.subject_outlined,
                ),
                _MetricTile(
                  label: 'Pages',
                  value: validation.pageCount.toString(),
                  icon: Icons.library_books_outlined,
                ),
                _MetricTile(
                  label: 'Grand Total',
                  value: validation.grandTotalDetected
                      ? 'Detected'
                      : 'Not detected',
                  icon: Icons.functions_outlined,
                ),
                _MetricTile(
                  label: 'Controls removed',
                  value: validation.removedControlCharacterCount.toString(),
                  icon: Icons.cleaning_services_outlined,
                ),
                _MetricTile(
                  label: 'Encoding',
                  value: validation.encodingName,
                  icon: Icons.translate_outlined,
                ),
                _MetricTile(
                  label: 'Replacements',
                  value: validation.replacementCharacterCount.toString(),
                  icon: Icons.find_replace_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 210,
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
