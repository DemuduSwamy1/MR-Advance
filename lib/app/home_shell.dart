import 'package:flutter/material.dart';

import '../features/converter/presentation/converter_screen.dart';
import '../features/invoice/presentation/invoice_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _convertTab = 0;
  static const _tabSubtitles = ['Convert reports to PDF', 'Create invoices'];

  int _selectedIndex = _convertTab;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _HomeHeader(subtitle: _tabSubtitles[_selectedIndex]),
      // IndexedStack keeps each tab's state (selected file, results) while
      // switching between them.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ConverterScreen(
            onIncomingFile: () => setState(() => _selectedIndex = _convertTab),
          ),
          const InvoiceScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Convert',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Invoice',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const _HomeHeader({required this.subtitle});

  final String subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      toolbarHeight: preferredSize.height,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      titleSpacing: 16,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/icon/app_logo.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ReportKit',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
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
