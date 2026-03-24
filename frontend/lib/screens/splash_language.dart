import 'dart:async';

import 'package:flutter/material.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import 'auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations for professional appearance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LanguageSelectionScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    // Responsive sizing based on screen dimensions
    final double baseFontSize = screenWidth < 400
        ? 20
        : (screenWidth < 600 ? 24 : 28);
    final double logoHeight = isPortrait
        ? (screenHeight * 0.25).clamp(140.0, 280.0)
        : (screenHeight * 0.35).clamp(120.0, 240.0);
    final double verticalSpacing = isPortrait
        ? (screenHeight * 0.06).clamp(24.0, 60.0)
        : (screenHeight * 0.08).clamp(16.0, 40.0);
    final double horizontalPadding = screenWidth < 400 ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {}, // Prevent accidental interactions
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            // Logo blended with splash background to avoid edge outline artifacts
                            ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Color(0x66E8EAED),
                                BlendMode.softLight,
                              ),
                              child: Image.asset(
                                'assets/images/vitaltrack_logo_full.png',
                                height: logoHeight,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                semanticLabel: 'VitalTrack Logo',
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.monitor_heart,
                                  size: logoHeight * 0.9,
                                  color: const Color(0xFF1E5AA8),
                                ),
                              ),
                            ),
                            SizedBox(height: verticalSpacing),

                            // Tagline with responsive font size
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding * 0.5,
                              ),
                              child: Text(
                                app.t('splash_tagline'),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: baseFontSize,
                                      color: const Color(0xFF616161),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.35,
                                      height: 1.4,
                                    ),
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  AppLanguage _selected = AppLanguage.english;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isSmallScreen = screenWidth < 400;
    final bool isTablet = screenWidth > 800;

    // Responsive sizing
    final double horizontalPadding = isSmallScreen ? 16 : 24;
    final double titleFontSize = isSmallScreen ? 24 : (isTablet ? 36 : 32);
    final double subtitleFontSize = isSmallScreen ? 13 : (isTablet ? 18 : 16);
    final double logoSize = isSmallScreen ? 92 : (isTablet ? 132 : 108);
    final double cardHeight = isSmallScreen ? 80 : (isTablet ? 100 : 90);
    final double iconSize = isSmallScreen ? 28 : (isTablet ? 40 : 32);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(height: isSmallScreen ? 20 : 28),

                        // Logo
                        Image.asset(
                          'assets/images/vitaltrack_logo_symbol.png',
                          height: logoSize,
                          fit: BoxFit.contain,
                          semanticLabel: 'VitalTrack Logo',
                          errorBuilder: (_, _, _) => Icon(
                            Icons.monitor_heart,
                            size: logoSize * 0.8,
                            color: const Color(0xFF1E5AA8),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 32 : 40),

                        // Title
                        Text(
                          app.t('select_preferred_language'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A3A52),
                                height: 1.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),

                        // Subtitle in Sinhala
                        Text(
                          app.t('select_language_subtitle'),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: subtitleFontSize,
                                color: const Color(0xFF616161),
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),
                      ],
                    ),

                    // Language options
                    Column(
                      children: <Widget>[
                        // English option
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selected = AppLanguage.english),
                          child: Container(
                            height: cardHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selected == AppLanguage.english
                                    ? const Color(0xFF1E5AA8)
                                    : const Color(0xFFE5EBF5),
                                width: _selected == AppLanguage.english
                                    ? 2.5
                                    : 1.5,
                              ),
                              color: _selected == AppLanguage.english
                                  ? const Color(0xFFF0F5FF)
                                  : Colors.white,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding * 0.8,
                                vertical: 12,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(
                                        0xFF1E5AA8,
                                      ).withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.language,
                                      color: const Color(0xFF1E5AA8),
                                      size: iconSize * 0.6,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding * 0.6),
                                  Expanded(
                                    child: Text(
                                      app.t('language_english_title'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: isSmallScreen
                                                ? 18
                                                : (isTablet ? 20 : 18),
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1A3A52),
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    _selected == AppLanguage.english
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color: _selected == AppLanguage.english
                                        ? const Color(0xFF1E5AA8)
                                        : const Color(0xFFCCCCCC),
                                    size: iconSize,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Sinhala option
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selected = AppLanguage.sinhala),
                          child: Container(
                            height: cardHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selected == AppLanguage.sinhala
                                    ? const Color(0xFF1E5AA8)
                                    : const Color(0xFFE5EBF5),
                                width: _selected == AppLanguage.sinhala
                                    ? 2.5
                                    : 1.5,
                              ),
                              color: _selected == AppLanguage.sinhala
                                  ? const Color(0xFFF0F5FF)
                                  : Colors.white,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding * 0.8,
                                vertical: 12,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(
                                        0xFF1E5AA8,
                                      ).withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.language,
                                      color: const Color(0xFF1E5AA8),
                                      size: iconSize * 0.6,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding * 0.6),
                                  Expanded(
                                    child: Text(
                                      app.t('language_sinhala_title'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: isSmallScreen
                                                ? 18
                                                : (isTablet ? 20 : 18),
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1A3A52),
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    _selected == AppLanguage.sinhala
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color: _selected == AppLanguage.sinhala
                                        ? const Color(0xFF1E5AA8)
                                        : const Color(0xFFCCCCCC),
                                    size: iconSize,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Continue button and footer
                    Column(
                      children: <Widget>[
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 48 : 56,
                          child: FilledButton(
                            onPressed: () {
                              app.setLanguage(_selected);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1E5AA8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  app.t('continue_bilingual'),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
