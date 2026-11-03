import 'package:flutter/material.dart';

const _monthLabels = [
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

/// Asks for a month and year, e.g. a medicine expiry. Returns the first day of
/// the chosen month, or null if cancelled.
Future<DateTime?> showMonthYearPicker(
  BuildContext context, {
  DateTime? initial,
  String title = 'Select month',
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) =>
        _MonthYearDialog(initial: initial ?? DateTime.now(), title: title),
  );
}

/// Formats a month as "MM/YY", the way expiry dates are printed.
String formatMonthYear(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final year = (date.year % 100).toString().padLeft(2, '0');
  return '$month/$year';
}

/// Parses "MM/YY" (or "MM/YYYY") back to a date, or null if it isn't one.
DateTime? parseMonthYear(String text) {
  final match = RegExp(
    r'^\s*(\d{1,2})\s*/\s*(\d{2}|\d{4})\s*$',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  final month = int.parse(match.group(1)!);
  final year = int.parse(match.group(2)!);
  if (month < 1 || month > 12) {
    return null;
  }
  return DateTime(year < 100 ? 2000 + year : year, month);
}

class _MonthYearDialog extends StatefulWidget {
  const _MonthYearDialog({required this.initial, required this.title});

  final DateTime initial;
  final String title;

  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous year',
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '$_year',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next year',
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var month = 1; month <= 12; month++)
                  _isSelected(month)
                      ? FilledButton(
                          onPressed: () => _select(month),
                          style: _monthButtonStyle,
                          child: Text(_monthLabels[month - 1]),
                        )
                      : OutlinedButton(
                          onPressed: () => _select(month),
                          style: _monthButtonStyle.copyWith(
                            foregroundColor: WidgetStatePropertyAll(
                              colorScheme.onSurface,
                            ),
                          ),
                          child: Text(_monthLabels[month - 1]),
                        ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  static final _monthButtonStyle = ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    minimumSize: const WidgetStatePropertyAll(Size.zero),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  bool _isSelected(int month) =>
      widget.initial.year == _year && widget.initial.month == month;

  void _select(int month) => Navigator.of(context).pop(DateTime(_year, month));
}
