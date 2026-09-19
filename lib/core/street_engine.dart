import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/palette.dart';
import '../app/typography.dart';
import 'models.dart';

/// Everything the "edge camera" needs — a deterministic night-street scene
/// rendered entirely on the canvas (no video asset, works identically on
/// every device), with the same renderer used for the live feed AND for the
/// frozen "evidence frame" on the incident detail screen.
///
/// Vehicle / pedestrian / defect positions are pure functions of
/// (seed, time), so a detection's evidence frame is always reproducible.
class StreetScenePainter extends CustomPainter {
  StreetScenePainter({
    required this.seed,
    required this.time,
    this.detection,
    this.boxProgress = 0,
    this.confProgress = 0,
    this.locked = false,
    this.confidence = 0,
  });

  final int seed;
  final double time;

  /// What the edge-AI has locked onto this frame.
  final DetectionVisual? detection;

  /// 0..1 — the bounding box strokes itself in over this interval.
  final double boxProgress;

  /// 0..1 — confidence ticks up to its final value.
  final double confProgress;
  final bool locked;
  final double confidence;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---- sky -----------------------------------------------------------
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF070C18), Color(0xFF101C33)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // stars (deterministic)
    final starPaint = Paint()
      ..color = const Color(0xFFE9EEF8).withValues(alpha: 0.5);
    final starRnd = Rand(seed + 99);
    for (var i = 0; i < 26; i++) {
      final sx = starRnd.next() * w;
      final sy = starRnd.next() * h * 0.3;
      canvas.drawCircle(
          Offset(sx, sy), starRnd.next() * 0.9 + 0.3, starPaint);
    }

    const horizonY = 0.34;
    final horizon = horizonY * h;

    // city glow band behind skyline
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF34E2B4).withValues(alpha: 0.0),
          const Color(0xFF2E6F9E).withValues(alpha: 0.16),
          const Color(0xFF1B2A44).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, horizon - h * 0.12, w, h * 0.16));
    canvas.drawRect(
        Rect.fromLTWH(0, horizon - h * 0.12, w, h * 0.16), glow);

    // skyline silhouette
    final skyline = Paint()..color = const Color(0xFF0C1424);
    final skyRnd = Rand(seed + 7);
    var bx = 0.0;
    while (bx < w) {
      final bw = w * skyRnd.range(0.05, 0.11);
      final bh = h * skyRnd.range(0.05, 0.16);
      final byTop = horizon - bh;
      canvas.drawRect(Rect.fromLTWH(bx, byTop, bw, bh), skyline);
      // a few lit windows
      final win = Paint()..color = const Color(0xFFF2C33D).withValues(alpha: 0.28);
      final winRnd = Rand(seed + skyRnd.intRange(1, 900));
      final winCols = (bw / (w * 0.008)).floor().clamp(1, 4);
      final winRows = (bh / (h * 0.012)).floor().clamp(1, 4);
      for (var c1 = 0; c1 < winCols; c1++) {
        for (var r1 = 0; r1 < winRows; r1++) {
          if (winRnd.next() < 0.24) {
            canvas.drawRect(
                Rect.fromLTWH(
                    bx + (c1 + 0.3) * bw / winCols,
                    byTop + (r1 + 0.3) * bh / winRows,
                    w * 0.004,
                    h * 0.006),
                win);
          }
        }
      }
      bx += bw * (1 + skyRnd.range(0, 0.3));
    }

    // ---- road ----------------------------------------------------------
    final road = Path()
      ..moveTo(w * 0.455, horizon)
      ..lineTo(w * 0.545, horizon)
      ..lineTo(w * 0.98, h * 0.99)
      ..lineTo(w * 0.02, h * 0.99);
    canvas.drawPath(road, Paint()..color = const Color(0xFF101828));
    // asphalt sheen
    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF111A29),
            const Color(0xFF151F31),
            const Color(0xFF0D1522),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)),
    );

    // lane dividers — dashed lines scrolling toward the camera
    final dashPaint = Paint()
      ..color = const Color(0xFFE9C94B).withValues(alpha: 0.4)
      ..strokeWidth = 2.0;
    for (final lx in [0.37, 0.37 + 0.26]) {
      final sx = math
          .max(w * 0.455, w * 0.02 + (lx - 0.455) * (w * 0.96 / (w * 0.96)));
      final sbx = w * 0.02 + (lx - 0.455) * (w * 0.96 / (w * 0.90)) * 2.4;
      for (var i = 0; i < 7; i++) {
        final phase = ((time * 5 + i) % 7) / 7;
        final y = horizon + (h - horizon) * math.max(0.0, phase);
        final topY = y - (h - horizon) * 0.06;
        if (topY < horizon) continue;
        final x = lerp(sx, sbx, phase);
        canvas.drawLine(Offset(x, topY), Offset(x, y), dashPaint);
      }
    }

    // sidewalks + posts
    canvas.drawRect(
        Rect.fromLTWH(0, horizon, w * 0.02, h - horizon),
        Paint()..color = const Color(0xFF0B1322));
    canvas.drawRect(
        Rect.fromLTWH(w * 0.98, horizon, w * 0.02, h - horizon),
        Paint()..color = const Color(0xFF0B1322));

    _drawLamp(canvas, w, h, horizon, 0.06, time, seed);
    _drawLamp(canvas, w, h, horizon, 0.92, time, seed + 3);

    // sign (roadside) — target for signLoss
    _drawSign(canvas, w, h, horizon);

    // pothole — target for pothole
    _drawPothole(canvas, w, h, horizon, seed);

    // pedestrians — target for pedRisk
    _drawPedestrian(canvas, w, h, horizon, seed, time);

    // vehicles — targets for vehicle / plate
    final vehicleRects = _drawVehicles(canvas, w, h, horizon, seed, time);

    // ---- detection overlay --------------------------------------------
    final d = detection;
    if (d != null) {
      final sevCol = _severityFor(d.kind);
      final rect = _targetRect(d, vehicleRects, w, h, horizon);
      if (rect != null) {
        _drawDetBox(canvas, w, h, rect, sevCol, d, seed);
      }
    }

    // subtle vignette
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x00000000),
            const Color(0x88000000),
          ],
          stops: const [0.72, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  // ---------------------------------------------------------------------

  Color _severityFor(DetectionKind k) => Dp.severityColor(k.baseSeverity);

  void _drawLamp(Canvas canvas, double w, double h, double horizon,
      double xFrac, double time, int seed) {
    final x = w * xFrac;
    final baseY = h * 0.99;
    final armY = h * 0.55;
    final sway = math.sin(time * 0.8 + seed) * 2;
    canvas.drawLine(Offset(x, baseY), Offset(x, armY),
        Paint()..color = const Color(0xFF1D2A44)..strokeWidth = 2.5);
    canvas.drawLine(Offset(x, armY), Offset(x + 8 + sway, armY - 1),
        Paint()..color = const Color(0xFF1D2A44)..strokeWidth = 2.5);
    final glowR = h * 0.09;
    final gs = Offset(x + 8 + sway, armY - 1);
    canvas.drawCircle(
        gs,
        glowR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFF2C33D).withValues(alpha: 0.22),
              const Color(0xFFF2C33D).withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: gs, radius: glowR)));
    canvas.drawCircle(gs, 2.2, Paint()..color = const Color(0xFFF2C33D).withValues(alpha: 0.9));
  }

  void _drawSign(Canvas canvas, double w, double h, double horizon) {
    final x = w * 0.885;
    final baseY = h * 0.985;
    final headY = h * 0.46;
    canvas.drawLine(Offset(x, baseY), Offset(x, headY),
        Paint()..color = const Color(0xFF1D2A44)..strokeWidth = 2.5);
    canvas.drawCircle(
        Offset(x, headY),
        w * 0.028,
        Paint()..color = const Color(0xFF24304A));
    canvas.drawCircle(
        Offset(x, headY),
        w * 0.028,
        Paint()
          ..color = const Color(0xFFF2C33D).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
  }

  void _drawPothole(Canvas canvas, double w, double h, double horizon, int seed) {
    final rnd = Rand(seed + 21);
    final c = Offset(w * rnd.range(0.30, 0.36), h * rnd.range(0.78, 0.84));
    final rw = w * 0.045;
    final rh = h * 0.02;
    canvas.drawOval(
        Rect.fromCenter(center: c, width: rw * 2, height: rh * 2),
        Paint()..color = const Color(0xFF0A0F1A));
    canvas.drawOval(
        Rect.fromCenter(center: c, width: rw * 1.6, height: rh * 1.5),
        Paint()
          ..color = const Color(0xFF0A0F1A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // rim highlight
    canvas.drawArc(
        Rect.fromCenter(center: c.translate(-rw * 0.2, -rh * 0.4),
            width: rw * 2.2, height: rh * 2.2),
        3.4, 2.2, false,
        Paint()
          ..color = const Color(0xFF35506E).withValues(alpha: 0.7)
          ..strokeWidth = 1.6);
  }

  void _drawPedestrian(Canvas canvas, double w, double h, double horizon,
      int seed, double time) {
    final wander = math.sin(time * 0.7 + seed) * w * 0.012;
    final x = w * 0.075 + wander;
    final y = h * 0.62 + math.sin(time * 1.3 + seed) * h * 0.012;
    final pw = w * 0.018;
    final ph = h * 0.085;
    final legSwing = math.sin(time * 6 + seed) * w * 0.006;
    // head
    canvas.drawCircle(Offset(x, y - ph),
        pw * 0.9, Paint()..color = const Color(0xFF223150));
    // body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - pw, y - ph + pw, pw * 2, ph - pw * 0.4),
            Radius.circular(pw * 0.7)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF2A3B5C), Color(0xFF1B2740)],
          ).createShader(Rect.fromLTWH(x - pw, y - ph + pw, pw * 2, ph - pw)));
    // legs
    final leg = Paint()
      ..color = const Color(0xFF16213A)
      ..strokeWidth = w * 0.006;
    canvas.drawLine(Offset(x - pw * 0.5, y - pw * 0.6 + legSwing * 0.4),
        Offset(x - pw * 0.6, y + pw * 0.4), leg);
    canvas.drawLine(Offset(x + pw * 0.5, y - pw * 0.6 - legSwing * 0.6),
        Offset(x + pw * 0.6, y + pw * 0.6), leg);
  }

  /// Draws the oncoming traffic and returns their normalized rects.
  List<Rect> _drawVehicles(Canvas canvas, double w, double h, double horizon,
      int seed, double time) {
    final rects = <Rect>[];
    final lanes = [0.30, 0.56];
    for (var v = 0; v < 2; v++) {
      final phase = frac(seed * 0.173 + v * 0.47 + time / 9.5);
      // ease in so vehicles pop into view smoothly
      final p = ease(phase);
      final y = horizon + (h - horizon) * p;
      if (y <= horizon + 1) continue;
      final bottomX = w * lanes[v];
      final farX = w * (0.47 + v * 0.06);
      final x = farX + (bottomX - farX) * p;
      final vw = lerp(w * 0.035, w * 0.13, p);
      final vh = vw * 2.3;

      final top = y - vh;
      final rect = Rect.fromLTWH(x - vw / 2 + vw * (v == 0 ? 0.28 : 0.2), top, vw, vh);
      rects.add(rect);

      // body
      final body = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            mute(seed + v, 0x2A, 0x38, 0x5A),
            mute(seed + v, 0x1B, 0x26, 0x42),
          ],
        ).createShader(rect);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(w * 0.012)), body);
      // windshield band (front third nearest camera)
      final windRect = Rect.fromLTWH(
          rect.left + vw * 0.08, rect.top + vh * 0.62, vw * 0.84, vh * 0.16);
      canvas.drawRRect(
          RRect.fromRectAndRadius(windRect, Radius.circular(w * 0.006)),
          Paint()..color = const Color(0xFF0E1730).withValues(alpha: 0.9));
      // headlights
      final hl = Paint()..color = const Color(0xFFF7E7B0).withValues(alpha: 0.9);
      canvas.drawCircle(
          Offset(rect.left + vw * 0.24, rect.bottom - vh * 0.04), w * 0.010, hl);
      canvas.drawCircle(
          Offset(rect.right - vw * 0.24, rect.bottom - vh * 0.04), w * 0.010, hl);
      // grille
      canvas.drawLine(
        Offset(rect.left + vw * 0.22, rect.bottom - vh * 0.02),
        Offset(rect.right - vw * 0.22, rect.bottom - vh * 0.02),
        Paint()
          ..color = const Color(0xFF0C1424)
          ..strokeWidth = w * 0.006,
      );
      // registration plate panel (front bumper)
      final platePanel = Rect.fromLTWH(
          rect.center.dx - vw * 0.16, rect.bottom - vh * 0.075, vw * 0.32, vh * 0.05);
      canvas.drawRect(platePanel,
          Paint()..color = const Color(0xFFF2F4F8).withValues(alpha: 0.92));
      canvas.drawRect(
          platePanel,
          Paint()
            ..color = const Color(0xFF24304A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
      // headlight beam faint cones
      for (final side in [-1, 1]) {
        final hx = rect.center.dx + side * vw * 0.24;
        final b = Paint()
          ..color = const Color(0xFFF7E7B0).withValues(alpha: 0.05)
          ..style = PaintingStyle.fill;
        final beam = Path()
          ..moveTo(hx, rect.bottom - vh * 0.05)
          ..lineTo(hx + side * w * 0.16, rect.bottom + h * 0.06)
          ..lineTo(hx + side * w * 0.04, rect.bottom + h * 0.06);
        canvas.drawPath(beam, b);
      }
    }
    return rects;
  }

  Rect? _targetRect(DetectionVisual d, List<Rect> vehicles, double w,
      double h, double horizon) {
    switch (d.kind) {
      case DetectionKind.pothole:
        return Rect.fromLTWH(w * 0.28, h * 0.75, w * 0.16, h * 0.12);
      case DetectionKind.signLoss:
        return Rect.fromLTWH(w * 0.83, h * 0.40, w * 0.13, h * 0.20);
      case DetectionKind.pedRisk:
        return Rect.fromLTWH(w * 0.03, h * 0.54, w * 0.09, h * 0.20);
      case DetectionKind.congestion:
        return Rect.fromLTWH(w * 0.08, h * 0.50, w * 0.84, h * 0.42);
      case DetectionKind.plateCapture:
      case DetectionKind.roadFracture:
        if (vehicles.isNotEmpty) {
          return vehicles.first;
        }
        return null;
    }
  }

  void _drawDetBox(Canvas canvas, double w, double h, Rect rect, Color color,
      DetectionVisual d, int seed) {
    final strokeW = math.max(1.6, w * 0.0035);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.012)));

    // draw-in: stroke reveals over boxProgress, then holds.
    if (boxProgress < 1) {
      final metrics = path.computeMetrics().toList();
      final total = metrics.fold<double>(0, (s, m) => s + m.length);
      final visible = total * boxProgress;
      var remaining = visible;
      final reveal = Path();
      for (final m in metrics) {
        if (remaining <= 0) break;
        final take = math.min(remaining, m.length);
        reveal.addPath(m.extractPath(0, take), Offset.zero);
        remaining -= take;
      }
      canvas.drawPath(
          reveal,
          Paint()
            ..color = color.withValues(alpha: 0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    } else {
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    }

    // confidence-revealed corner brackets
    if (boxProgress >= 1) {
      final cw = w * 0.018;
      final bracket = Paint()
        ..color = color
        ..strokeWidth = strokeW * 1.1
        ..strokeCap = StrokeCap.round;
      final p = math.min(confProgress * 1.6, 1.0);
      void corner(Offset base, Offset dx, Offset dy) {
        canvas.drawLine(base, base + dx * p, bracket);
        canvas.drawLine(base, base + dy * p, bracket);
      }

      corner(rect.topLeft, Offset(cw, 0), Offset(0, cw));
      corner(rect.topRight, Offset(-cw, 0), Offset(0, cw));
      corner(rect.bottomLeft, Offset(cw, 0), Offset(0, -cw));
      corner(rect.bottomRight, Offset(-cw, 0), Offset(0, -cw));
    }

    // label chip with confidence ticking up
    final conf = d.confidence * confProgress;
    final confText = locked
        ? '${(d.confidence * 100).toStringAsFixed(0)}% · LOCK'
        : '${(conf * 100).toStringAsFixed(0)}%';
    final label = '${d.kind.code} · $confText';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: monoTxt(
          w * 0.026,
          color: color,
          w: FontWeight.w600,
          ls: w * 0.0012,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final chipTop = rect.top - tp.height - h * 0.018;
    final chipRect = chipTop < 0
        ? Rect.fromLTWH(rect.left, rect.bottom + h * 0.012, tp.width + w * 0.03, tp.height + h * 0.014)
        : Rect.fromLTWH(rect.left - w * 0.006, chipTop, tp.width + w * 0.03, tp.height + h * 0.014);
    canvas.drawRRect(
        RRect.fromRectAndRadius(chipRect, Radius.circular(chipRect.height * 0.35)),
        Paint()..color = const Color(0xE6041122));
    canvas.drawRRect(
        RRect.fromRectAndRadius(chipRect, Radius.circular(chipRect.height * 0.35)),
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    tp.paint(canvas, chipRect.topLeft + Offset(w * 0.015, h * 0.007));

    // center crosshair
    final cxp = Paint()
      ..color = color.withValues(alpha: 0.35 + 0.5 * confProgress)
      ..strokeWidth = 1.4;
    final c = rect.center;
    canvas.drawLine(c.translate(-w * 0.012, 0), c.translate(-w * 0.004, 0), cxp);
    canvas.drawLine(c.translate(w * 0.004, 0), c.translate(w * 0.012, 0), cxp);
    canvas.drawLine(c.translate(0, -h * 0.008), c.translate(0, -h * 0.003), cxp);
    canvas.drawLine(c.translate(0, h * 0.003), c.translate(0, h * 0.008), cxp);
  }

  @override
  bool shouldRepaint(StreetScenePainter old) =>
      old.time != time ||
      old.seed != seed ||
      old.boxProgress != boxProgress ||
      old.confProgress != confProgress ||
      old.locked != locked ||
      old.confidence != confidence ||
      old.detection != detection;
}

/// What the edge-AI has locked onto in a frame.
class DetectionVisual {
  const DetectionVisual({
    required this.kind,
    required this.confidence,
    this.plate,
    this.objectIndex = 0,
  });

  final DetectionKind kind;
  final double confidence;
  final String? plate;
  final int objectIndex;

  @override
  bool operator ==(Object other) =>
      other is DetectionVisual &&
      other.kind == kind &&
      other.plate == plate &&
      other.objectIndex == objectIndex &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(kind, plate, objectIndex);
}

// --- small math helpers -------------------------------------------------

double frac(double v) => v - v.floorToDouble();

double ease(double t) => t * t * (3 - 2 * t);

double lerp(double a, double b, double t) => a + (b - a) * t;

Color mute(int seed, int r, int g, int b) {
  final rnd = Rand(seed);
  return Color.fromARGB(
      255,
      (r * rnd.range(0.92, 1.08)).round().clamp(0, 255),
      (g * rnd.range(0.92, 1.08)).round().clamp(0, 255),
      (b * rnd.range(0.92, 1.08)).round().clamp(0, 255));
}