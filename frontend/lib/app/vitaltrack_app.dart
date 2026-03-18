import 'package:flutter/material.dart';

import '../screens/splash_language.dart';
import 'scope.dart';
import 'state.dart';
import 'ui.dart';

class VitalTrackApp extends StatefulWidget {
  const VitalTrackApp({super.key});

  @override
  State<VitalTrackApp> createState() => _VitalTrackAppState();
}

class _VitalTrackAppState extends State<VitalTrackApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    // Initialize user from local storage on app startup
    _state.initializeUser();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (BuildContext context, _) {
          final double controlHeight = adaptiveControlHeight(context);
          final double iconSize = adaptiveIconSize(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'VitalTrack',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF6FBFB),
              appBarTheme: const AppBarTheme(centerTitle: false),
              cardTheme: const CardThemeData(
                elevation: 0,
                margin: EdgeInsets.symmetric(vertical: 6),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              final ThemeData baseTheme = Theme.of(context);
              final ThemeData adaptiveTheme = baseTheme.copyWith(
                iconTheme: baseTheme.iconTheme.copyWith(size: iconSize),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(controlHeight),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(controlHeight),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: adaptiveTextScaler(context)),
                child: Theme(
                  data: adaptiveTheme,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
