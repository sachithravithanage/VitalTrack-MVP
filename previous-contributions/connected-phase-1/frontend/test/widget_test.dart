import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vitaltrack/widgets/dashboard_shell.dart';
import 'package:vitaltrack/widgets/form_screen_scaffold.dart';

void main() {
  testWidgets('AdaptiveDashboardShell shows bottom nav on compact width', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveDashboardShell(
          title: 'Shell',
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const <DashboardDestination>[
            DashboardDestination(icon: Icons.home, label: 'Home'),
            DashboardDestination(icon: Icons.person, label: 'Profile'),
          ],
          pages: const <Widget>[Text('Page A'), Text('Page B')],
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Page A'), findsOneWidget);
  });

  testWidgets('AdaptiveDashboardShell shows rail and handles tap on wide width', (
    WidgetTester tester,
  ) async {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(1400, 900)
      ..devicePixelRatio = 1.0;
    addTearDown(() {
      binding.platformDispatcher.views.first
        ..physicalSize = const Size(800, 600)
        ..devicePixelRatio = 1.0;
    });

    int selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AdaptiveDashboardShell(
              title: 'Shell',
              selectedIndex: selected,
              onDestinationSelected: (int i) => setState(() => selected = i),
              destinations: const <DashboardDestination>[
                DashboardDestination(icon: Icons.home, label: 'Home'),
                DashboardDestination(icon: Icons.person, label: 'Profile'),
              ],
              pages: const <Widget>[Text('Page A'), Text('Page B')],
            );
          },
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Page A'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Page B'), findsOneWidget);
  });

  testWidgets('FormScreenScaffold renders title and content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FormScreenScaffold(
          title: 'Form Title',
          child: Text('Form Content'),
        ),
      ),
    );

    expect(find.text('Form Title'), findsOneWidget);
    expect(find.text('Form Content'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
