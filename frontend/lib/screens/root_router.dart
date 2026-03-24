import 'package:flutter/material.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import 'auth.dart';
import 'dashboard.dart';

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final UserProfileData? user = app.currentUser;
    if (user == null) return const LoginScreen();
    if (user.role == UserRole.patient) return const PatientDashboard();
    return const CaregiverDashboard();
  }
}
