import 'package:flutter/material.dart';

class NarrowDialogFrame extends StatelessWidget {
  const NarrowDialogFrame({
    super.key,
    required this.maxWidth,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final double maxWidth;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
