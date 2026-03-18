import 'package:flutter/material.dart';

import '../app/ui.dart';

class FormScreenScaffold extends StatelessWidget {
  const FormScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 620,
    this.scrollable = true,
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ResponsiveContent(
        maxWidth: maxWidth,
        scrollable: scrollable,
        child: child,
      ),
    );
  }
}
