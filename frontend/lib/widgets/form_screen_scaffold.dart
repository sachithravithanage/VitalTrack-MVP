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
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE7ECF6)),
        ),
      ),
      body: ResponsiveContent(
        maxWidth: maxWidth,
        scrollable: scrollable,
        child: child,
      ),
    );
  }
}
