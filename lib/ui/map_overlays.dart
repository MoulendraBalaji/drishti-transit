import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/models.dart';
import 'glyphs.dart';

/// ---------------------------------------------------------------------------
/// Bus markers — small moving chips; hero bus gently glows.
/// ---------------------------------------------------------------------------
class BusMarker extends StatelessWidget {
  const BusMarker({super.key, required this.bus});
  final Bus bus;

  @override
  Widget build(BuildContext context) {
    final hero = bus.hero;
    final accent = Dp.signal;
    return SizedBox(
      width: hero ? 40 : 32,
      height: hero ? 40 : 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hero)
            const _HeroHalo(),
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: hero ? Dp.signal : Dp.raised2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hero ? accent : Dp.lineBright,
              ),
            ),
            child: Drishti.icon(
              DGlyph.bus,
              size: hero ? 15 : 13,
              color: hero ? Dp.onSignal : Dp.vehicleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHalo extends StatefulWidget {
  const _HeroHalo();

  @override
  State<_HeroHalo> createState() => _HeroHaloState();
}

class _HeroHaloState extends State<_HeroHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Mo.livePulse)
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return CustomPaint(
            size: const Size(40, 40),
            painter: _HaloPainter(t));
      },
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final o = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
        o,
        size.width * 0.5,
        Paint()
          ..color = Dp.signal.withValues(alpha: (1 - t) * 0.16)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        o, size.width * (0.5 - t * 0.1), Paint()..color = Dp.signal.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.t != t;
}

/// ---------------------------------------------------------------------------
/// Incident pins — severity colored with a small confidence readout.
/// ---------------------------------------------------------------------------
class IncidentPin extends StatelessWidget {
  const IncidentPin({super.key, required this.event, required this.newest});
  final DetectionEvent event;
  final bool newest;

  @override
  Widget build(BuildContext context) {
    final col = Dp.severityColor(event.severity);
    return SizedBox(
      width: 52,
      height: 60,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (newest)
            const _PinPulse(),
          Positioned(
            top: 6,
            child: CustomPaint(
              size: const Size(34, 40),
              painter: _PinPainter(col),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(width: 52, height: 22, child: _ConfChip(event, col)),
          ),
        ],
      ),
    );
  }
}

class _ConfChip extends StatelessWidget {
  const _ConfChip(this.event, this.color);
  final DetectionEvent event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xE6041122),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          event.confLabel,
          style: monoTxt(7.5, color: color, w: FontWeight.w700, ls: 0.2),
        ),
      ),
    );
  }
}

class _PinPulse extends StatefulWidget {
  const _PinPulse();

  @override
  State<_PinPulse> createState() => _PinPulseState();
}

class _PinPulseState extends State<_PinPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Mo.scene)
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = CurvedAnimation(parent: _c, curve: Mo.easeOutTech).value;
        return CustomPaint(
          size: const Size(40, 48),
          painter: _ArrivalRipplePainter(t, Dp.signal),
        );
      },
      child: const SizedBox(),
    );
  }
}

class _ArrivalRipplePainter extends CustomPainter {
  _ArrivalRipplePainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final o = Offset(size.width / 2, size.height / 2);
    final e = Curves.easeOutCubic.transform(t);
    final fill = Paint()..color = color.withValues(alpha: (1 - t) * 0.5);
    canvas.drawCircle(o, size.width * (0.3 + e * 0.28), fill);
    canvas.drawCircle(
      o,
      size.width * 0.32,
      Paint()
        ..color = color.withValues(alpha: (1 - t) * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ArrivalRipplePainter old) => old.t != t;
}

class _PinPainter extends CustomPainter {
  _PinPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final o = Offset(w / 2, h * 0.52);
    final body = ui.Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.5, h * 0.96, w * 0.16, h * 0.68, w * 0.16, h * 0.44)
      ..cubicTo(w * 0.16, h * 0.2, w * 0.32, h * 0.06, w * 0.5, h * 0.06)
      ..cubicTo(w * 0.68, h * 0.06, w * 0.84, h * 0.2, w * 0.84, h * 0.44)
      ..cubicTo(w * 0.84, h * 0.68, w * 0.5, h * 0.96, w / 2, h);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.28),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(o, w * 0.11,
        Paint()..color = const Color(0xFF041122));
    canvas.drawCircle(o, w * 0.07, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

/// ---------------------------------------------------------------------------
/// Heat layer — a genuine composited overlay of weighted radial gradients,
/// not an image. Repaints with the camera so it tracks pan/zoom.
/// ---------------------------------------------------------------------------
class HeatOverlay extends StatelessWidget {
  const HeatOverlay({super.key, required this.points});
  final List<HeatPoint> points;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _HeatPainter(points, camera),
        ),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.points, this.camera);
  final List<HeatPoint> points;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final zoomScale = math.pow(2, (camera.zoom - 13)).toDouble();
    for (final p in points) {
      final offset = camera.latLngToScreenOffset(LatLng(p.lat, p.lng));
      if (!(offset.dx > -200 &&
          offset.dx < size.width + 200 &&
          offset.dy > -200 &&
          offset.dy < size.height + 200)) {
        continue;
      }
      final ageSec = now.difference(p.at).inSeconds;
      final fade = (1 - ageSec / 900).clamp(0.0, 1.0);
      if (fade <= 0) continue;
      final radius = 34 * zoomScale * p.weight * 1.6;
      final col = Color.lerp(Dp.signal, Dp.critical, p.weight)!;
      final grad = Paint()
        ..shader = RadialGradient(
          colors: [
            col.withValues(alpha: 0.55 * fade),
            col.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
            center: offset, radius: radius));
      canvas.drawCircle(offset, radius, grad);
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.points != points || old.camera != camera;
}

/// ---------------------------------------------------------------------------
/// Arrival ripples — a designed pulse at the GPS point when an alert lands.
/// Driven by its own ticker so it keeps running between data events.
/// ---------------------------------------------------------------------------
class RippleLayer extends StatefulWidget {
  const RippleLayer({super.key, required this.ripples});
  final List<Ripple> ripples;

  @override
  State<RippleLayer> createState() => _RippleLayerState();
}

class _RippleLayerState extends State<RippleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (widget.ripples.isEmpty) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _RipplesPainter(widget.ripples, camera, DateTime.now()),
        ),
      ),
    );
  }
}

class _RipplesPainter extends CustomPainter {
  _RipplesPainter(this.ripples, this.camera, this.now);
  final List<Ripple> ripples;
  final MapCamera camera;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in ripples) {
      final age = now.difference(r.born).inMilliseconds / 2000.0;
      if (age > 1) continue;
      final offset = camera.latLngToScreenOffset(
        LatLng(r.event.lat, r.event.lng),
      );
      final col = Dp.severityColor(r.event.severity);
      final t = Curves.easeOutCubic.transform(age);
      final radius = 10 + t * 52;
      canvas.drawCircle(
        offset,
        radius,
        Paint()
          ..color = col.withValues(alpha: (1 - t) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 - t,
      );
      canvas.drawCircle(
        offset,
        radius * 0.55,
        Paint()
          ..color = col.withValues(alpha: (1 - t) * 0.18)
          ..style = PaintingStyle.fill,
      );
      // the alert just landed
      canvas.drawCircle(offset, 4, Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(_RipplesPainter old) => true;
}