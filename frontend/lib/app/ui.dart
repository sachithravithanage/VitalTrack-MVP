import 'package:flutter/material.dart';

class UiSpace {
  static const SizedBox xxs = SizedBox(height: 6);
  static const SizedBox xs = SizedBox(height: 10);
  static const SizedBox sm = SizedBox(height: 14);
  static const SizedBox md = SizedBox(height: 18);
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
    return SafeArea(
      child: ListView(
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: padding,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: compact ? 40 : 44,
              height: compact ? 40 : 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon,
                size: compact ? 20 : 22,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              size: compact ? 34 : 38,
              color: theme.colorScheme.primary,
            ),
            UiSpace.xs,
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            UiSpace.xxs,
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
