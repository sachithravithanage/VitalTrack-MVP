import 'package:flutter/material.dart';

class UiSpace {
  static const SizedBox xxs = SizedBox(height: 6);
  static const SizedBox xs = SizedBox(height: 8);
  static const SizedBox sm = SizedBox(height: 12);
  static const SizedBox md = SizedBox(height: 16);
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
    this.padding = const EdgeInsets.all(16),
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
    this.padding = const EdgeInsets.all(16),
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
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: compact ? 20 : 22,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
              child: Icon(
                icon,
                size: compact ? 20 : 22,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: <Widget>[
            Icon(icon, size: compact ? 34 : 38, color: Theme.of(context).colorScheme.primary),
            UiSpace.xs,
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
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
