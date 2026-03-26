import 'dart:async';

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/state.dart';
import '../widgets/dashboard_shell.dart';
import 'caregiver.dart';
import 'notifications.dart';
import 'profile_hotspot.dart';
import 'records.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _index = 0;
  Timer? _notificationTimer;
  bool _didInitNotifications = false;
  final Set<String> _seenNotificationIds = <String>{};
  List<Widget>? _pages;
  String? _pagesForUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitNotifications) return;
    _didInitNotifications = true;
    unawaited(_initializeNotificationPopups());
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotificationPopups() async {
    final AppState app = AppScope.of(context);
    try {
      await app.loadNotificationHistory();
      _seenNotificationIds
        ..clear()
        ..addAll(app.notifications.map((n) => n.id));
    } catch (_) {
      // Keep UI usable even if the initial fetch fails.
    }

    _notificationTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (!mounted) return;
      unawaited(_checkForNewNotifications());
    });
  }

  Future<void> _checkForNewNotifications() async {
    final AppState app = AppScope.of(context);
    try {
      await app.loadNotificationHistory();
      final newItems = app.notifications
          .where((n) => !_seenNotificationIds.contains(n.id))
          .toList();

      if (newItems.isEmpty) return;

      _seenNotificationIds.addAll(newItems.map((n) => n.id));

      if (!mounted) return;
      final latest = newItems.first;
      _showInAppNotificationBanner(
        context,
        title: latest.title,
        body: latest.body,
      );
    } catch (_) {
      // Silence background polling failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final user = app.currentUser!;

    if (_pages == null || _pagesForUserId != user.id) {
      _pagesForUserId = user.id;
      _pages = <Widget>[
        const KeepRecordsSelectorScreen(),
        RecordsListScreen(patientId: user.id, canAddFromHere: false),
        const ProfileScreen(),
        const HotspotMapScreen(forCaregiverPatientData: false),
      ];
    }

    final List<DashboardDestination> destinations = <DashboardDestination>[
      DashboardDestination(icon: Icons.edit_note, label: app.t('keep_records')),
      DashboardDestination(icon: Icons.list_alt, label: app.t('show_records')),
      DashboardDestination(icon: Icons.person_outline, label: app.t('profile')),
      DashboardDestination(icon: Icons.map, label: app.t('hotspot_map')),
    ];

    return AdaptiveDashboardShell(
      title: app.t('app_title'),
      selectedIndex: _index,
      onDestinationSelected: (int value) => setState(() => _index = value),
      onNotificationsPressed: () async {
        unawaited(app.loadNotificationHistory());
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
        );
        if (!context.mounted) return;
        unawaited(app.loadNotificationHistory());
      },
      unreadNotificationCount: app.unreadNotificationCount,
      destinations: destinations,
      pages: _pages!,
    );
  }
}

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  int _index = 0;
  Timer? _notificationTimer;
  bool _didInitNotifications = false;
  final Set<String> _seenNotificationIds = <String>{};
  late final List<Widget> _pages = const <Widget>[
    CaregiverPatientsScreen(),
    ProfileScreen(),
    HotspotMapScreen(forCaregiverPatientData: true),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitNotifications) return;
    _didInitNotifications = true;
    unawaited(_initializeNotificationPopups());
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotificationPopups() async {
    final AppState app = AppScope.of(context);
    try {
      await app.loadNotificationHistory();
      _seenNotificationIds
        ..clear()
        ..addAll(app.notifications.map((n) => n.id));
    } catch (_) {
      // Keep UI usable even if the initial fetch fails.
    }

    _notificationTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (!mounted) return;
      unawaited(_checkForNewNotifications());
    });
  }

  Future<void> _checkForNewNotifications() async {
    final AppState app = AppScope.of(context);
    try {
      await app.loadNotificationHistory();
      final newItems = app.notifications
          .where((n) => !_seenNotificationIds.contains(n.id))
          .toList();

      if (newItems.isEmpty) return;

      _seenNotificationIds.addAll(newItems.map((n) => n.id));

      if (!mounted) return;
      final latest = newItems.first;
      _showInAppNotificationBanner(
        context,
        title: latest.title,
        body: latest.body,
      );
    } catch (_) {
      // Silence background polling failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final List<DashboardDestination> destinations = <DashboardDestination>[
      DashboardDestination(icon: Icons.people, label: app.t('patients')),
      DashboardDestination(icon: Icons.person_outline, label: app.t('profile')),
      DashboardDestination(icon: Icons.map, label: app.t('hotspot_map')),
    ];

    return AdaptiveDashboardShell(
      title: app.t('app_title'),
      selectedIndex: _index,
      onDestinationSelected: (int value) => setState(() => _index = value),
      onNotificationsPressed: () async {
        unawaited(app.loadNotificationHistory());
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
        );
        if (!context.mounted) return;
        unawaited(app.loadNotificationHistory());
      },
      unreadNotificationCount: app.unreadNotificationCount,
      destinations: destinations,
      pages: _pages,
    );
  }
}

void _showInAppNotificationBanner(
  BuildContext context, {
  required String title,
  required String body,
}) {
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..clearSnackBars()
    ..clearMaterialBanners()
    ..showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFFEAF3FF),
        dividerColor: Colors.transparent,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDCEAFE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Color(0xFF1E73D8),
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A1430),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF405676)),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: messenger.clearMaterialBanners,
            child: Text(AppScope.of(context).t('dismiss')),
          ),
        ],
      ),
    );

  Future<void>.delayed(const Duration(seconds: 5), () {
    messenger.clearMaterialBanners();
  });
}
