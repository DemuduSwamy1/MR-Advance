import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/converter/presentation/converter_screen.dart';
import '../features/invoice/presentation/invoice_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.useSideBar = kIsWeb});

  /// Shows the tabs in a left side bar (the website) instead of a bottom bar
  /// (the apps).
  final bool useSideBar;

  /// Finds the side bar in tests.
  static const sideBarKey = ValueKey('side-bar');

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _convertTab = 0;

  int _selectedIndex = _convertTab;

  @override
  Widget build(BuildContext context) {
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

    return widget.useSideBar ? _buildWebLayout(tabs) : _buildAppLayout(tabs);
  }

  Widget _buildAppLayout(Widget tabs) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _HomeHeader(subtitle: _tabs[_selectedIndex].description),
      body: tabs,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
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

  /// The website: a branded side bar, with the pages on a tinted background so
  /// their cards stand out.
  Widget _buildWebLayout(Widget tabs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final extended = constraints.maxWidth >= 960;
          return Row(
            children: [
              _SideBar(
                key: HomeShell.sideBarKey,
                extended: extended,
                selectedIndex: _selectedIndex,
                onSelect: _selectTab,
              ),
              Expanded(
                child: Theme(
                  data: theme.copyWith(
                    scaffoldBackgroundColor: colorScheme.surfaceContainerLow,
                    cardTheme: theme.cardTheme.copyWith(
                      color: colorScheme.surface,
                    ),
                  ),
                  child: tabs,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);
}

class _Tab {
  const _Tab(this.label, this.description, this.icon, this.selectedIcon);

  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _Tab(
    'Convert',
    'Convert reports to PDF',
    Icons.description_outlined,
    Icons.description,
  ),
  _Tab(
    'Invoice',
    'Create invoices',
    Icons.receipt_long_outlined,
    Icons.receipt_long,
  ),
];

/// Deep teal from the app icon, a shade darker than the header colour.
const _sideBarColor = Color(0xFF1C574C);

class _SideBar extends StatelessWidget {
  const _SideBar({
    super.key,
    required this.extended,
    required this.selectedIndex,
    required this.onSelect,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: extended ? 252 : 92,
      color: _sideBarColor,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 16 : 10,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: extended
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              _Brand(extended: extended),
              const SizedBox(height: 32),
              if (extended)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'TOOLS',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              for (var i = 0; i < _tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SideBarItem(
                    tab: _tabs[i],
                    selected: i == selectedIndex,
                    extended: extended,
                    onTap: () => onSelect(i),
                  ),
                ),
              const Spacer(),
              if (extended)
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reports and invoices stay on this device.',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Tooltip(
                  message: 'Reports and invoices stay on this device.',
                  child: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Colors.white60,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset('assets/icon/app_logo.png', width: 44, height: 44),
    );

    if (!extended) {
      return Tooltip(message: 'ReportKit', child: logo);
    }

    return Row(
      children: [
        logo,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ReportKit',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'RAVITEJA MEDICALS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideBarItem extends StatelessWidget {
  const _SideBarItem({
    required this.tab,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? Colors.white : Colors.white70;
    final icon = Icon(
      selected ? tab.selectedIcon : tab.icon,
      color: foreground,
      size: 22,
    );

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 12 : 4,
              vertical: extended ? 10 : 8,
            ),
            child: extended
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tab.label,
                              style: textTheme.titleSmall?.copyWith(
                                color: foreground,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            Text(
                              tab.description,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      icon,
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
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
