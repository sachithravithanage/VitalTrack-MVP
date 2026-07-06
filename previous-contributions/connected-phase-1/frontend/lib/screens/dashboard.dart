import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/state.dart';
import '../widgets/dashboard_shell.dart';
import 'caregiver.dart';
import 'profile_hotspot.dart';
import 'records.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final user = app.currentUser!;
    final List<Widget> pages = <Widget>[
      const KeepRecordsSelectorScreen(),
      RecordsListScreen(patientId: user.id, canAddFromHere: false),
      const ProfileScreen(),
      const HotspotMapScreen(forCaregiverPatientData: false),
    ];
    final List<DashboardDestination> destinations = <DashboardDestination>[
      DashboardDestination(icon: Icons.edit_note, label: app.t('keep_records')),
      DashboardDestination(icon: Icons.list_alt, label: app.t('show_records')),
      DashboardDestination(icon: Icons.person, label: app.t('profile')),
      DashboardDestination(icon: Icons.map, label: app.t('hotspot_map')),
    ];

    return AdaptiveDashboardShell(
      title: 'VitalTrack',
      selectedIndex: _index,
      onDestinationSelected: (int value) => setState(() => _index = value),
      destinations: destinations,
      pages: pages,
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

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final List<Widget> pages = const <Widget>[
      CaregiverPatientsScreen(),
      ProfileScreen(),
      HotspotMapScreen(forCaregiverPatientData: true),
    ];
    final List<DashboardDestination> destinations = <DashboardDestination>[
      DashboardDestination(icon: Icons.people, label: app.t('patients')),
      DashboardDestination(icon: Icons.person, label: app.t('profile')),
      DashboardDestination(icon: Icons.map, label: app.t('hotspot_map')),
    ];

    return AdaptiveDashboardShell(
      title: 'VitalTrack',
      selectedIndex: _index,
      onDestinationSelected: (int value) => setState(() => _index = value),
      destinations: destinations,
      pages: pages,
    );
  }
}
