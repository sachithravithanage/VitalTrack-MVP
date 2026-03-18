import 'package:flutter/material.dart';

import '../app/ui.dart';

class DashboardDestination {
  const DashboardDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class AdaptiveDashboardShell extends StatelessWidget {
  const AdaptiveDashboardShell({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.pages,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<DashboardDestination> destinations;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    final bool wide = isWide(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/vitaltrack_logo_symbol.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.monitor_heart),
              ),
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE7ECF6)),
        ),
      ),
      body: wide
          ? Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        (DashboardDestination d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[selectedIndex]),
              ],
            )
          : pages[selectedIndex],
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE7ECF6))),
              ),
              child: NavigationBar(
                height: 72,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: destinations
                    .map(
                      (DashboardDestination d) => NavigationDestination(
                        icon: Icon(d.icon),
                        label: d.label,
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}
