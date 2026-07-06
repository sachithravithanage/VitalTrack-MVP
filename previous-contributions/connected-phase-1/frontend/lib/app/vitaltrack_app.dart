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

  static const Color _brandBlue = Color(0xFF1E5AA8);
  static const Color _bg = Color(0xFFF4F7FC);

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
              useMaterial3: true,
              colorScheme: const ColorScheme.light(
                primary: _brandBlue,
                secondary: _brandBlue,
                surface: Colors.white,
                onSurface: Color(0xFF1A1F36),
                onPrimary: Colors.white,
                outline: Color(0xFFD9E2F2),
              ),
              scaffoldBackgroundColor: _bg,
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF1A1F36),
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE5EBF5)),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD9E2F2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD9E2F2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _brandBlue, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                labelStyle: const TextStyle(color: Color(0xFF5D6785)),
              ),
              navigationBarTheme: const NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: Color(0x1F1E5AA8),
                labelTextStyle: WidgetStatePropertyAll(
                  TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: Colors.white,
                indicatorColor: Color(0x1F1E5AA8),
                selectedIconTheme: IconThemeData(color: _brandBlue),
                selectedLabelTextStyle: TextStyle(
                  color: _brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              final ThemeData baseTheme = Theme.of(context);
              final ThemeData adaptiveTheme = baseTheme.copyWith(
                iconTheme: baseTheme.iconTheme.copyWith(size: iconSize),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size.fromHeight(controlHeight),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: _brandBlue,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1F36),
                    side: const BorderSide(color: Color(0xFFD9E2F2)),
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
                dividerTheme: const DividerThemeData(
                  color: Color(0xFFE7ECF6),
                  thickness: 1,
                  space: 1,
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
