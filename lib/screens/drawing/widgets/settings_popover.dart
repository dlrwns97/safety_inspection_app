import 'package:flutter/material.dart';

class SettingsPopoverController {
  OverlayEntry? _entry;

  bool get isShown => _entry != null;

  void show({
    required BuildContext context,
    required LayerLink link,
    required Widget child,
  }) {
    hide();
    final overlay = Overlay.of(context, rootOverlay: true);
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final isTablet = width >= 900;
    final maxWidth = isTablet ? 420.0 : 360.0;
    final maxHeight = isTablet ? 420.0 : 360.0;

    _entry = OverlayEntry(
      builder: (entryContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: hide,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(entryContext).colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 280,
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}
