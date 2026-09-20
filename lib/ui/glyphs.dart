import 'package:flutter/material.dart';

/// The full bespoke Drishti glyph set — hand-drawn line icons, one stroke
/// weight, consistent with the mono/data aesthetic. No Material icon font.
enum DGlyph {
  markRadar,
  bus,
  camera,
  pin,
  plate,
  alert,
  heat,
  stacks,
  signal,
  stats,
  crosshair,
  clock,
  arrowUpRight,
  check,
  scan,
  feed,
  route,
  chevronUp,
  chevronDown,
  chevronRight,
  chevronLeft,
  refresh,
  shield,
  target,
  info,
  sun,
  moon,
}

/// Renders a [DGlyph] as a crisp stroked glyph.
class Drishti {
  Drishti._();

  static Widget icon(
    DGlyph glyph, {
    double size = 20,
    Color color = const Color(0xFF141414),
    double stroke = 1.7,
  }) =>
      CustomPaint(
        size: Size.square(size),
        painter: _DrishtiGlyphPainter(glyph, color, stroke),
      );
}

class _DrishtiGlyphPainter extends CustomPainter {
  _DrishtiGlyphPainter(this.glyph, this.color, this.stroke);

  final DGlyph glyph;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Normalized 0..1 helper-space drawing.
    void line(Offset a, Offset b) =>
        canvas.drawLine(a * s, b * s, paint);
    void poly(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx * s, pts.first.dy * s);
      for (final pt in pts.skip(1)) {
        p.lineTo(pt.dx * s, pt.dy * s);
      }
      canvas.drawPath(p, paint);
    }

    void circle(Offset c, double r, {bool fill = false}) {
      if (fill) {
        canvas.drawCircle(c * s, r * s, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        canvas.drawCircle(c * s, r * s, paint);
      }
    }

    void dot(Offset c, double r) {
      canvas.drawCircle(c * s, r * s, Paint()
        ..color = color
        ..style = PaintingStyle.fill);
    }

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    switch (glyph) {
      case DGlyph.markRadar:
        line(const Offset(1.5, 0.2), const Offset(1.5, 0.12));
        line(const Offset(0.0, 0.0), const Offset(1.0, 0.0));
        canvas.drawArc(
            Rect.fromCenter(center: const Offset(0.8, 0.8) * s, width: s, height: s),
            -0.6, 1.9, false, arcPaint);
        canvas.drawArc(
            Rect.fromCenter(center: const Offset(0.5, 0.5) * s, width: s * 1.5, height: s * 1.5),
            -0.4, 0.6, false, arcPaint);
        dot(const Offset(0.5, 0.5), 0.09);
        break;
      case DGlyph.bus:
        poly(const [
          Offset(0.16, 0.18), Offset(0.2, 0.34), Offset(0.22, 0.74),
          Offset(0.3, 0.9), Offset(0.7, 0.9), Offset(0.78, 0.74),
          Offset(0.8, 0.34), Offset(0.84, 0.18),
        ]);
        line(const Offset(0.2, 0.34), const Offset(0.2, 0.18));
        line(const Offset(0.8, 0.34), const Offset(0.8, 0.18));
        // windows
        line(const Offset(0.3, 0.78), const Offset(0.7, 0.78));
        line(const Offset(0.32, 0.62), const Offset(0.68, 0.62));
        line(const Offset(0.3, 0.4), const Offset(0.7, 0.4));
        // wheels
        circle(const Offset(0.28, 0.88), 0.08);
        circle(const Offset(0.72, 0.88), 0.08);
        break;
      case DGlyph.camera:
        poly(const [
          Offset(0.18, 0.3), Offset(0.3, 0.3), Offset(0.38, 0.2),
          Offset(0.62, 0.2), Offset(0.7, 0.3), Offset(0.82, 0.3),
          Offset(0.82, 0.72), Offset(0.18, 0.72),
        ]);
        line(const Offset(0.18, 0.72), const Offset(0.18, 0.3));
        circle(const Offset(0.5, 0.5), 0.15);
        dot(const Offset(0.72, 0.24), 0.05);
        break;
      case DGlyph.pin:
        final p = Path()
          ..moveTo(s * 0.5, s * 0.92)
          ..cubicTo(s * 0.5, s * 0.92, s * 0.13, s * 0.56, s * 0.13, s * 0.36)
          ..cubicTo(s * 0.13, s * 0.17, s * 0.3, s * 0.07, s * 0.5, s * 0.07)
          ..cubicTo(s * 0.7, s * 0.07, s * 0.87, s * 0.17, s * 0.87, s * 0.36)
          ..cubicTo(s * 0.87, s * 0.56, s * 0.5, s * 0.92, s * 0.5, s * 0.92);
        canvas.drawPath(p, paint);
        circle(const Offset(0.5, 0.36), 0.09);
        break;
      case DGlyph.plate:
        poly(const [
          Offset(0.1, 0.32), Offset(0.22, 0.2), Offset(0.42, 0.2),
          Offset(0.9, 0.42), Offset(0.9, 0.64), Offset(0.8, 0.78),
          Offset(0.34, 0.78), Offset(0.1, 0.6),
        ]);
        line(const Offset(0.1, 0.6), const Offset(0.1, 0.32));
        line(const Offset(0.24, 0.28), const Offset(0.82, 0.46));
        line(const Offset(0.18, 0.56), const Offset(0.34, 0.66));
        break;
      case DGlyph.alert:
        poly(const [
          Offset(0.5, 0.07), Offset(0.93, 0.86), Offset(0.89, 0.93),
          Offset(0.11, 0.93), Offset(0.07, 0.86),
        ]);
        line(const Offset(0.5, 0.34), const Offset(0.5, 0.62));
        dot(const Offset(0.5, 0.78), 0.05);
        break;
      case DGlyph.heat:
        // radiating pulse arcs
        canvas.drawArc(Rect.fromCircle(center: const Offset(0.32, 0.5) * s, radius: s * 0.14), -0.4, 1.5, false, arcPaint);
        canvas.drawArc(Rect.fromCircle(center: const Offset(0.32, 0.5) * s, radius: s * 0.26), -0.4, 2.2, false, arcPaint);
        canvas.drawArc(Rect.fromCircle(center: const Offset(0.32, 0.5) * s, radius: s * 0.38), -0.4, 2.7, false, arcPaint);
        break;
      case DGlyph.stacks:
        poly(const [Offset(0.12, 0.5), Offset(0.48, 0.12), Offset(0.88, 0.5), Offset(0.5, 0.9), Offset(0.12, 0.5)]);
        poly(const [Offset(0.12, 0.78), Offset(0.5, 0.9), Offset(0.88, 0.5)]);
        break;
      case DGlyph.signal:
        line(const Offset(0.18, 0.68), const Offset(0.18, 0.8));
        line(const Offset(0.34, 0.6), const Offset(0.34, 0.8));
        line(const Offset(0.5, 0.5), const Offset(0.5, 0.8));
        line(const Offset(0.66, 0.36), const Offset(0.66, 0.8));
        line(const Offset(0.82, 0.16), const Offset(0.82, 0.8));
        line(const Offset(0.08, 0.8), const Offset(0.92, 0.8));
        break;
      case DGlyph.stats:
        line(const Offset(0.12, 0.88), const Offset(0.88, 0.88));
        line(const Offset(0.2, 0.88), const Offset(0.2, 0.6));
        line(const Offset(0.44, 0.88), const Offset(0.44, 0.32));
        line(const Offset(0.68, 0.88), const Offset(0.68, 0.46));
        line(const Offset(0.2, 0.52), const Offset(0.44, 0.26));
        line(const Offset(0.44, 0.26), const Offset(0.68, 0.4));
        break;
      case DGlyph.crosshair:
        circle(const Offset(0.5, 0.5), 0.3);
        line(const Offset(0.5, 0.06), const Offset(0.5, 0.18));
        line(const Offset(0.5, 0.82), const Offset(0.5, 0.94));
        line(const Offset(0.06, 0.5), const Offset(0.18, 0.5));
        line(const Offset(0.82, 0.5), const Offset(0.94, 0.5));
        dot(const Offset(0.5, 0.5), 0.07);
        break;
      case DGlyph.clock:
        circle(const Offset(0.5, 0.5), 0.42);
        line(const Offset(0.5, 0.5), const Offset(0.5, 0.3));
        line(const Offset(0.5, 0.5), const Offset(0.64, 0.55));
        break;
      case DGlyph.arrowUpRight:
        line(const Offset(0.24, 0.76), const Offset(0.76, 0.24));
        line(const Offset(0.76, 0.24), const Offset(0.4, 0.24));
        line(const Offset(0.76, 0.24), const Offset(0.76, 0.6));
        break;
      case DGlyph.check:
        poly(const [Offset(0.84, 0.2), Offset(0.34, 0.72), Offset(0.16, 0.52)]);
        break;
      case DGlyph.scan:
        poly(const [Offset(0.12, 0.3), Offset(0.12, 0.12), Offset(0.3, 0.12)]);
        poly(const [Offset(0.7, 0.12), Offset(0.88, 0.12), Offset(0.88, 0.3)]);
        poly(const [Offset(0.88, 0.7), Offset(0.88, 0.88), Offset(0.7, 0.88)]);
        poly(const [Offset(0.3, 0.88), Offset(0.12, 0.88), Offset(0.12, 0.7)]);
        break;
      case DGlyph.feed:
        line(const Offset(0.16, 0.42), const Offset(0.84, 0.42));
        line(const Offset(0.16, 0.66), const Offset(0.84, 0.66));
        line(const Offset(0.16, 0.9), const Offset(0.84, 0.9));
        dot(const Offset(0.3, 0.18), 0.07);
        line(const Offset(0.42, 0.18), const Offset(0.62, 0.18));
        break;
      case DGlyph.route:
        poly(const [Offset(0.14, 0.34), Offset(0.34, 0.24), Offset(0.52, 0.4), Offset(0.78, 0.3), Offset(0.88, 0.44)]);
        circle(const Offset(0.14, 0.34), 0.07);
        circle(const Offset(0.88, 0.44), 0.07);
        dot(const Offset(0.52, 0.4), 0.1);
        break;
      case DGlyph.chevronUp:
        poly(const [Offset(0.5, 0.28), Offset(0.22, 0.56), Offset(0.78, 0.56)]);
        break;
      case DGlyph.chevronDown:
        poly(const [Offset(0.5, 0.72), Offset(0.22, 0.44), Offset(0.78, 0.44)]);
        break;
      case DGlyph.chevronRight:
        poly(const [Offset(0.3, 0.2), Offset(0.7, 0.5), Offset(0.3, 0.8)]);
        break;
      case DGlyph.chevronLeft:
        poly(const [Offset(0.7, 0.2), Offset(0.3, 0.5), Offset(0.7, 0.8)]);
        break;
      case DGlyph.refresh:
        canvas.drawArc(Rect.fromCircle(center: const Offset(0.5, 0.5) * s, radius: s * 0.36), -3.7, 3.8, false, arcPaint);
        poly(const [Offset(0.9, 0.18), Offset(0.82, 0.28), Offset(0.92, 0.3)]);
        break;
      case DGlyph.shield:
        poly(const [
          Offset(0.5, 0.06), Offset(0.86, 0.12), Offset(0.84, 0.4),
          Offset(0.78, 0.7), Offset(0.5, 0.94), Offset(0.22, 0.7),
          Offset(0.16, 0.4), Offset(0.14, 0.12),
        ]);
        line(const Offset(0.5, 0.06), const Offset(0.5, 0.94));
        line(const Offset(0.14, 0.12), const Offset(0.5, 0.06));
        break;
      case DGlyph.target:
        circle(const Offset(0.5, 0.5), 0.36);
        circle(const Offset(0.5, 0.5), 0.16);
        dot(const Offset(0.5, 0.5), 0.06);
        line(const Offset(0.5, 0.04), const Offset(0.5, 0.14));
        line(const Offset(0.5, 0.86), const Offset(0.5, 0.96));
        line(const Offset(0.04, 0.5), const Offset(0.14, 0.5));
        line(const Offset(0.86, 0.5), const Offset(0.96, 0.5));
        break;
      case DGlyph.info:
        circle(const Offset(0.5, 0.5), 0.42);
        dot(const Offset(0.5, 0.32), 0.06);
        line(const Offset(0.5, 0.46), const Offset(0.5, 0.66));
        break;
      case DGlyph.sun:
        circle(const Offset(0.5, 0.5), 0.22);
        line(const Offset(0.5, 0.08), const Offset(0.5, 0.20));
        line(const Offset(0.5, 0.80), const Offset(0.5, 0.92));
        line(const Offset(0.08, 0.5), const Offset(0.20, 0.5));
        line(const Offset(0.80, 0.5), const Offset(0.92, 0.5));
        line(const Offset(0.20, 0.20), const Offset(0.28, 0.28));
        line(const Offset(0.72, 0.72), const Offset(0.80, 0.80));
        line(const Offset(0.20, 0.80), const Offset(0.28, 0.72));
        line(const Offset(0.72, 0.28), const Offset(0.80, 0.20));
        break;
      case DGlyph.moon:
        final p = Path()
          ..moveTo(s * 0.72, s * 0.16)
          ..cubicTo(s * 0.38, s * 0.20, s * 0.20, s * 0.48, s * 0.28, s * 0.76)
          ..cubicTo(s * 0.34, s * 0.88, s * 0.48, s * 0.96, s * 0.62, s * 0.94)
          ..cubicTo(s * 0.28, s * 0.88, s * 0.16, s * 0.44, s * 0.50, s * 0.14)
          ..close();
        canvas.drawPath(p, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_DrishtiGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.stroke != stroke;
}