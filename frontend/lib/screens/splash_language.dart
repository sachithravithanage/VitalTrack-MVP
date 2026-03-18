import 'dart:async';

import 'package:flutter/material.dart';

import '../app/models.dart';
import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';
import 'auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LanguageSelectionScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: SizedBox(
              width: 286,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'VITALTRACK',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/images/vitaltrack_logo_full.png',
                    height: 162,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Column(
                      children: const <Widget>[
                        Icon(
                          Icons.monitor_heart,
                          size: 80,
                          color: Color(0xFF1E5AA8),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'VitalTrack',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.t('splash_tagline'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(minHeight: 4),
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

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  AppLanguage _selected = AppLanguage.english;

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(app.t('select_language'))),
      body: ResponsiveContent(
        maxWidth: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SectionHeader(
              title: app.t('select_language'),
              subtitle: app.t('select_language_subtitle'),
              icon: Icons.language,
            ),
            UiSpace.xs,
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      selected: _selected == AppLanguage.english,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      title: Text(app.t('language_english_title')),
                      subtitle: Text(app.t('language_english_subtitle')),
                      trailing: Icon(
                        _selected == AppLanguage.english
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _selected == AppLanguage.english
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF98A2B3),
                      ),
                      onTap: () =>
                          setState(() => _selected = AppLanguage.english),
                    ),
                    const Divider(height: 8),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.translate,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      selected: _selected == AppLanguage.sinhala,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      title: Text(app.t('language_sinhala_title')),
                      subtitle: Text(app.t('language_sinhala_subtitle')),
                      trailing: Icon(
                        _selected == AppLanguage.sinhala
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _selected == AppLanguage.sinhala
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF98A2B3),
                      ),
                      onTap: () =>
                          setState(() => _selected = AppLanguage.sinhala),
                    ),
                  ],
                ),
              ),
            ),
            UiSpace.sm,
            FilledButton(
              onPressed: () {
                app.setLanguage(_selected);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                );
              },
              child: Text(app.t('continue')),
            ),
          ],
        ),
      ),
    );
  }
}
