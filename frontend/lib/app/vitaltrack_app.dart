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

  // Enterprise Color Palette
  static const Color _primary = Color(0xFF0F66D9);
  static const Color _primaryDark = Color(0xFF0052A3);
  static const Color _secondary = Color(0xFF00A699);
  static const Color _accent = Color(0xFFF79009);
  static const Color _error = Color(0xFFE34B5B);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _neutral50 = Color(0xFFFFFEFF);
  static const Color _neutral100 = Color(0xFFF8FAFC);
  static const Color _neutral200 = Color(0xFFEEF2F5);
  static const Color _neutral300 = Color(0xFFE3E8EF);
  static const Color _neutral400 = Color(0xFFCDD5E0);
  static const Color _neutral500 = Color(0xFF98A2B3);
  static const Color _neutral600 = Color(0xFF667085);
  static const Color _neutral900 = Color(0xFF111827);

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
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'VitalTrack',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: const ColorScheme.light(
                primary: _primary,
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFDEE9FF),
                onPrimaryContainer: _primaryDark,
                secondary: _secondary,
                onSecondary: Colors.white,
                secondaryContainer: Color(0xFFB3F1E7),
                onSecondaryContainer: Color(0xFF004C45),
                tertiary: _accent,
                onTertiary: Colors.white,
                error: _error,
                onError: Colors.white,
                errorContainer: Color(0xFFFBDEE0),
                onErrorContainer: Color(0xFF8B1A1E),
                surface: Colors.white,
                onSurface: _neutral900,
                surfaceContainerLowest: _neutral50,
                surfaceContainerLow: _neutral100,
                surfaceContainer: _neutral200,
                surfaceContainerHigh: _neutral300,
                outline: _neutral300,
                outlineVariant: _neutral400,
                scrim: _neutral900,
              ),
              scaffoldBackgroundColor: _bg,
              // Typography
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                  color: _neutral900,
                ),
                displayMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.3,
                  color: _neutral900,
                ),
                displaySmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.33,
                  color: _neutral900,
                ),
                headlineLarge: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.36,
                  color: _neutral900,
                ),
                headlineMedium: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.44,
                  color: _neutral900,
                ),
                headlineSmall: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.5,
                  color: _neutral900,
                ),
                titleLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  height: 1.5,
                  color: _neutral900,
                ),
                titleMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  height: 1.57,
                  color: _neutral900,
                ),
                titleSmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  height: 1.67,
                  color: _neutral900,
                ),
                bodyLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  height: 1.5,
                  color: _neutral900,
                ),
                bodyMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  height: 1.57,
                  color: _neutral600,
                ),
                bodySmall: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  height: 1.67,
                  color: _neutral600,
                ),
                labelLarge: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  height: 1.57,
                  color: _neutral900,
                ),
                labelMedium: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  height: 1.67,
                  color: _neutral900,
                ),
                labelSmall: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  height: 1.45,
                  color: _neutral900,
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: Colors.white,
                foregroundColor: _neutral900,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                iconTheme: IconThemeData(color: _neutral900, size: 24),
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _neutral900,
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: _neutral200, width: 1),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  elevation: 0,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: _neutral50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _neutral300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                labelStyle: const TextStyle(
                  color: _neutral600,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                hintStyle: const TextStyle(color: _neutral500, fontSize: 14),
                helperStyle: const TextStyle(color: _neutral600, fontSize: 12),
                errorStyle: const TextStyle(color: _error, fontSize: 12),
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                elevation: 8,
                surfaceTintColor: Colors.transparent,
                indicatorColor: const Color(0xFFDEE9FF),
                iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: _primary, size: 24);
                  }
                  return const IconThemeData(color: _neutral500, size: 24);
                }),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                  Set<WidgetState> states,
                ) {
                  return TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: states.contains(WidgetState.selected)
                        ? _primary
                        : _neutral500,
                  );
                }),
              ),
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: Colors.white,
                indicatorColor: Color(0xFFDEE9FF),
                selectedIconTheme: IconThemeData(color: _primary, size: 24),
                unselectedIconTheme: IconThemeData(
                  color: _neutral500,
                  size: 24,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: _neutral600,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: _neutral200,
                thickness: 1,
                space: 12,
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _neutral300),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              final ThemeData baseTheme = Theme.of(context);
              final ThemeData adaptiveTheme = baseTheme.copyWith(
                iconTheme: baseTheme.iconTheme.copyWith(
                  size: adaptiveIconSize(context),
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
