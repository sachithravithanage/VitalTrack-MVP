import 'package:flutter/material.dart';

import '../app/ui.dart';

class DashboardDestination {
  const DashboardDestination({
    required this.icon,
    required this.label,
  });

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
      appBar: AppBar(title: Text(title)),
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
          : NavigationBar(
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
    );
  }
}
