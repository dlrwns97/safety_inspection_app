import 'package:flutter/material.dart';

class NarrowDialogFrame extends StatelessWidget {
  const NarrowDialogFrame({
    super.key,
    required this.maxWidth,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.maxHeightFactor = 0.9,
  });

  final double maxWidth;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom - 24;
    final safeAvailableHeight = availableHeight > 0
        ? availableHeight
        : media.size.height * 0.6;
    final maxHeight = (safeAvailableHeight * maxHeightFactor)
        .clamp(160.0, safeAvailableHeight)
        .toDouble();

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
