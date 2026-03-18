import 'package:flutter/material.dart';

class BusyFilledButton extends StatelessWidget {
  const BusyFilledButton({
    super.key,
    required this.isBusy,
    required this.label,
    required this.onPressed,
  });

  final bool isBusy;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isBusy ? null : onPressed,
      child: isBusy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
