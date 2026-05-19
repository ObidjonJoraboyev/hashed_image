import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'decay_pattern.dart';

/// Paints the BlurHash cover image on top of the real image and progressively
/// erodes it with organic blob-shaped holes, then fades it out completely.
class BlurDecayPainter extends CustomPainter {
  final ui.Image blur;
  final Animation<double> progress;
  final DecayPattern pattern;

  /// Fraction of the radial gradient devoted to soft falloff (vs a hard core).
  static const double _edgeSoftness = 0.995;

  /// Extra multiplier on gradient radius so path outlines sit deep inside the
  /// falloff, creating a cloud-like perceived border.
  static const double _gradientOuterPadding = 1.22;

  /// When `1.0` the opacity fades across the entire animation. Lower values
  /// finish the fade early for a snappier hand-off.
  static const double _fadeCompletionFraction = 1.0;

  BlurDecayPainter({
    required this.blur,
    required this.progress,
    required this.pattern,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final p = progress.value;

    final fadeLinear = (p / _fadeCompletionFraction).clamp(0.0, 1.0);
    final fadeEased = Curves.easeInOutCubic.transform(fadeLinear);
    final coverAlpha = ((1.0 - fadeEased) * 255).clamp(0.0, 255.0).round();
    if (coverAlpha <= 0) return;

    // Isolated layer so dstOut erases only the blur cover, not the image below.
    canvas.saveLayer(rect, Paint());
    _drawCover(canvas, size, coverAlpha);
    if (p > 0) _erode(canvas, size, p);
    canvas.restore();
  }

  void _drawCover(Canvas canvas, Size size, int alpha) {
    final src = _coverSrc(
      Size(blur.width.toDouble(), blur.height.toDouble()),
      size,
    );
    canvas.drawImageRect(
      blur,
      src,
      Offset.zero & size,
      Paint()
        ..color = ui.Color.fromARGB(alpha, 255, 255, 255)
        ..filterQuality = FilterQuality.low,
    );
  }

  void _erode(Canvas canvas, Size size, double p) {
    final diagonal =
        math.sqrt(size.width * size.width + size.height * size.height);
    // Erosion lags behind opacity: stays small early, accelerates late so the
    // viewer perceives a soft dissolve rather than growing shapes.
    final eased = math.pow(p, 2.35).toDouble();
    if (eased <= 0) return;

    for (final blob in pattern.blobs) {
      final radius = diagonal * blob.maxRadiusFactor * eased;
      if (radius <= 0.5) continue;
      final cx = blob.center.dx * size.width;
      final cy = blob.center.dy * size.height;
      _drawBlob(canvas, Offset(cx, cy), radius, blob);
    }
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, DecayBlob blob) {
    final outer = radius * (1.0 + kBlobRadiusJitter + _gradientOuterPadding);
    final coreEnd = (1.0 - _edgeSoftness).clamp(0.001, 0.08);

    final colors = <ui.Color>[
      const ui.Color(0xFF000000),
      const ui.Color(0xF5000000),
      const ui.Color(0xC8000000),
      const ui.Color(0x88000000),
      const ui.Color(0x48000000),
      const ui.Color(0x18000000),
      const ui.Color(0x00000000),
    ];
    final stops = <double>[
      0.0,
      coreEnd,
      coreEnd + (1.0 - coreEnd) * 0.18,
      coreEnd + (1.0 - coreEnd) * 0.38,
      coreEnd + (1.0 - coreEnd) * 0.58,
      coreEnd + (1.0 - coreEnd) * 0.82,
      1.0,
    ];

    final paint = Paint()
      ..blendMode = BlendMode.dstOut
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(center, outer, colors, stops);

    canvas.drawPath(_buildBlobPath(center, radius, blob), paint);
  }

  Path _buildBlobPath(Offset center, double radius, DecayBlob blob) {
    final n = blob.radialOffsets.length;
    final points = List<Offset>.generate(n, (i) {
      final angle = (i / n) * 2 * math.pi + blob.rotation;
      final r = radius * blob.radialOffsets[i];
      return Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
    });

    // Catmull-Rom → cubic Bézier (1/6 coefficient from uniform CR→Bézier).
    const t = 1.0 / 6.0;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < n; i++) {
      final p0 = points[(i - 1 + n) % n];
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final p3 = points[(i + 2) % n];
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) * t,
        p1.dy + (p2.dy - p0.dy) * t,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) * t,
        p2.dy - (p3.dy - p1.dy) * t,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  Rect _coverSrc(Size src, Size dst) {
    final sr = src.width / src.height;
    final dr = dst.width / dst.height;
    if (sr > dr) {
      final nw = src.height * dr;
      final dx = (src.width - nw) / 2;
      return Rect.fromLTWH(dx, 0, nw, src.height);
    }
    final nh = src.width / dr;
    final dy = (src.height - nh) / 2;
    return Rect.fromLTWH(0, dy, src.width, nh);
  }

  @override
  bool shouldRepaint(covariant BlurDecayPainter old) =>
      old.blur != blur || !identical(old.pattern, pattern);
}
