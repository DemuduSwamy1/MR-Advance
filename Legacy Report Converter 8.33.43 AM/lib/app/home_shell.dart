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

  int _selectedIndex = _convertTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
