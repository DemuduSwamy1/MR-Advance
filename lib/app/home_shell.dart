import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/converter/presentation/converter_screen.dart';
import '../features/invoice/presentation/invoice_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.useSideBar = kIsWeb});

  /// Shows the tabs in a left side bar (the website) instead of a bottom bar
  /// (the apps).
  final bool useSideBar;

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

    // IndexedStack keeps each tab's state (selected file, results) while
    // switching between them.
    final tabs = IndexedStack(
      index: _selectedIndex,
      children: [
        ConverterScreen(
          onIncomingFile: () => setState(() => _selectedIndex = _convertTab),
        ),
        const InvoiceScreen(),
      ],
    );

    return Scaffold(
      appBar: _HomeHeader(subtitle: _tabSubtitles[_selectedIndex]),
      body: widget.useSideBar
          ? Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectTab,
                    labelType: NavigationRailLabelType.all,
                    minWidth: 88,
                    destinations: [
                      for (final tab in _tabs)
                        NavigationRailDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.selectedIcon),
                          label: Text(tab.label),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                    ],
                  ),
                ),
                Expanded(child: tabs),
              ],
            )
          : tabs,
      bottomNavigationBar: widget.useSideBar
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectTab,
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: tab.label,
                    ),
                ],
              ),
            ),
    );
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _Tab('Convert', Icons.description_outlined, Icons.description),
  _Tab('Invoice', Icons.receipt_long_outlined, Icons.receipt_long),
];

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
