import 'package:flutter/material.dart';

import '../app/ui.dart';

class InputSection extends StatelessWidget {
  const InputSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        UiSpace.xs,
        child,
      ],
    );
  }
}
