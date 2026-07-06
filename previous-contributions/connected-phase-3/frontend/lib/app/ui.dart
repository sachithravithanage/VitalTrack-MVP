import 'package:flutter/material.dart';

// Enterprise Design System
class UiSpace {
  static const SizedBox xxs = SizedBox(height: 4);
  static const SizedBox xs = SizedBox(height: 8);
  static const SizedBox sm = SizedBox(height: 12);
  static const SizedBox md = SizedBox(height: 16);
  static const SizedBox lg = SizedBox(height: 24);
  static const SizedBox xl = SizedBox(height: 32);
  static const SizedBox xxl = SizedBox(height: 40);

  // Horizontal spacing
  static const SizedBox hxs = SizedBox(width: 8);
  static const SizedBox hsm = SizedBox(width: 12);
  static const SizedBox hmd = SizedBox(width: 16);
  static const SizedBox hlg = SizedBox(width: 24);
}

class UiElevation {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow small = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow large = BoxShadow(
    color: Color(0x2B000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
}

class UiBorder {
  static const BorderRadius xs = BorderRadius.all(Radius.circular(6));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

TextScaler adaptiveTextScaler(BuildContext context) {
  final double width = MediaQuery.sizeOf(context).width;
  final double userScale = MediaQuery.textScalerOf(context).scale(1);
  final double widthFactor = width < 360
      ? 0.95
      : width < 600
      ? 1.0
      : width < 900
      ? 1.03
      : 1.08;
  return TextScaler.linear((userScale * widthFactor).clamp(0.95, 1.8));
}

double adaptiveControlHeight(BuildContext context) {
  final double width = MediaQuery.sizeOf(context).width;
  if (width < 360) return 44;
  if (width < 900) return 48;
  return 54;
}

double adaptiveIconSize(BuildContext context) {
  final double width = MediaQuery.sizeOf(context).width;
  if (width < 360) return 20;
  if (width < 900) return 24;
  return 26;
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.all(18),
    this.scrollable = false,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (scrollable) {
      return SafeArea(child: SingleChildScrollView(child: content));
    }
    return SafeArea(child: content);
  }
}

class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    super.key,
    required this.children,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.all(18),
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final EdgeInsets adaptiveDefaultPadding = EdgeInsets.all(
      width < 380
          ? 14
          : width >= 1200
          ? 22
          : 18,
    );
    final EdgeInsetsGeometry resolvedPadding =
        padding == const EdgeInsets.all(18) ? adaptiveDefaultPadding : padding;

    return SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: resolvedPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: compact ? 44 : 48,
              height: compact ? 44 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                size: compact ? 22 : 24,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: compact ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 380;
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 28,
          vertical: compact ? 28 : 36,
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: compact ? 60 : 72,
              height: compact ? 60 : 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                icon,
                size: compact ? 32 : 40,
                color: theme.colorScheme.primary,
              ),
            ),
            UiSpace.md,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF98A2B3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
