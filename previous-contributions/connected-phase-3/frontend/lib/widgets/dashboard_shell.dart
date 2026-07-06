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
    this.onNotificationsPressed,
    this.unreadNotificationCount = 0,
  });

  final String title;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<DashboardDestination> destinations;
  final List<Widget> pages;
  final VoidCallback? onNotificationsPressed;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    final bool wide = isWide(context);
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1, 1.3);
    final double navBarHeight = 74 + ((textScale - 1) * 12);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 14,
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/vitaltrack_logo_symbol.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.monitor_heart),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: onNotificationsPressed,
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF111827),
                    size: 22,
                  ),
                ),
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 6,
                  top: 2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE34B5B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadNotificationCount > 99
                          ? '99+'
                          : unreadNotificationCount.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEF2F5)),
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
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
              ],
            )
          : IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: wide
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEEF2F5), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: NavigationBar(
                height: navBarHeight,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: destinations
                    .map(
                      (DashboardDestination d) => NavigationDestination(
                        icon: Icon(d.icon, size: 22),
                        selectedIcon: Icon(d.icon, size: 22),
                        label: d.label,
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}
