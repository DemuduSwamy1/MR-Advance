import 'package:flutter/material.dart';

import '../../../../core/utils/byte_utils.dart';
import '../../data/file_picker_service.dart';

class FileSelectionCard extends StatelessWidget {
  const FileSelectionCard({
    super.key,
    required this.selectedFile,
    required this.detectedEncoding,
    required this.isLoading,
    required this.onSelect,
    required this.onBrowseAll,
  });

  final SelectedReportFile? selectedFile;
  final String? detectedEncoding;
  final bool isLoading;
  final VoidCallback? onSelect;
  final VoidCallback? onBrowseAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text(
                  'Source report',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: onSelect,
                      icon: isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_outlined),
                      label: Text(
                        isLoading ? 'Selecting...' : 'Select Report File',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onBrowseAll,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Browse All Files'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedFile == null)
              Text(
                'Supported files include no-extension reports and .txt, .dat, .prn, .lis, or .out files.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else
              Column(
                children: [
                  _InfoRow(
                    label: 'File name',
                    value: selectedFile!.name,
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'File size',
                    value: formatByteCount(selectedFile!.sizeInBytes),
                    icon: Icons.data_object_outlined,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Detected encoding',
                    value: detectedEncoding ?? 'Analyzing...',
                    icon: Icons.text_fields_outlined,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
