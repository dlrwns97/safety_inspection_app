import 'dart:ui';

Path buildStrokeOutlinePath(List<Offset> outline) {
  final path = Path();
  if (outline.isEmpty) {
    return path;
  }

  path.moveTo(outline.first.dx, outline.first.dy);
  for (var i = 0; i < outline.length - 1; i += 1) {
    final p0 = outline[i];
    final p1 = outline[i + 1];
    path.quadraticBezierTo(
      p0.dx,
      p0.dy,
      (p0.dx + p1.dx) / 2,
      (p0.dy + p1.dy) / 2,
    );
  }
  path.close();
  return path;
}
