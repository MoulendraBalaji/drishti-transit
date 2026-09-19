import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../ui/chrome.dart';
import '../ui/glyphs.dart';

/// Mission boot screen — sets the tone in under two and a half seconds, then
/// hands over to the command shell with a scale-out / settle transition.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _boot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: Mo.radarSweep,
  )..repeat();
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    _advance = Timer(const Duration(milliseconds: 2650), _enter);
  }

  void _enter() {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    context.go('/command');
  }

  @override
  void dispose() {
    _advance?.cancel();
    _boot.dispose();
    _radar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    return Scaffold(
      backgroundColor: Dp.bg,
      body: GestureDetector(
        onTap: _enter,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // faint survey grid
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: CurvedAnimation(
                          parent: _boot, curve: Intervals(0, 0.4)),
                      child: AnimatedBuilder(
                        animation: _radar,
                        builder: (context, _) => CustomPaint(
                          size: const Size(96, 96),
                          painter: _RadarPainter(_radar.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: CurvedAnimation(
                          parent: _boot, curve: Intervals(0.12, 0.5)),
                      child: SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 0.08), end: Offset.zero)
                            .animate(CurvedAnimation(
                                parent: _boot, curve: Mo.easeOutTech)),
                        child: Column(
                          children: [
                            Text(
                              'DRISHTI',
                              style: AppText.displayHero.copyWith(
                                  fontSize: 52, letterSpacing: -2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TRANSIT · EDGE-AI · NETWORK',
                              style: AppText.dataTiny.copyWith(
                                  color: Dp.saffron, letterSpacing: 2.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: CurvedAnimation(
                          parent: _boot, curve: Intervals(0.3, 0.6)),
                      child: Text(
                        'Every bus is a sensor for the city.',
                        style: AppText.body.copyWith(
                            color: Dp.mist, fontStyle: FontStyle.normal),
                      ),
                    ),
                    const Spacer(),
                    _BootReadout(boot: _boot, buses: cc.busesOnline),
                    const SizedBox(height: 26),
                    _BootHint(boot: _boot),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootReadout extends StatelessWidget {
  const _BootReadout({required this.boot, required this.buses});
  final AnimationController boot;
  final int buses;

  Widget _line(int index, String text) {
    final start = 0.42 + index * 0.12;
    return FadeTransition(
      opacity: CurvedAnimation(parent: boot, curve: Intervals(start, start + 0.15)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: boot, curve: Mo.easeOutTech)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: AnimatedBuilder(
                  animation: boot,
                  builder: (context, child) => Opacity(
                    opacity: boot.value > start + 0.08 ? 1 : 0,
                    child: child,
                  ),
                  child:
                      Drishti.icon(DGlyph.check, size: 14, color: Dp.signal),
                ),
              ),
              Text(text, style: AppText.data.copyWith(color: Dp.mist)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: Dp.surface,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(0, 'GRID 42/42 · CORRIDORS LOCKED'),
          _line(1, 'EDGE $buses/$buses · NODES ONLINE'),
          _line(2, 'UPLINK TO COMMAND · SECURE'),
          _line(3, 'MODEL DRISHTI-YOLOv2 · READY'),
        ],
      ),
    );
  }
}

class _BootHint extends StatelessWidget {
  const _BootHint({required this.boot});
  final AnimationController boot;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: boot, curve: const Intervals(0.82, 1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('TAP TO TAKE COMMAND',
              style: AppText.dataTiny.copyWith(color: Dp.fog, letterSpacing: 1.6)),
          const SizedBox(width: 6),
          Drishti.icon(DGlyph.chevronRight, size: 12, color: Dp.fog),
        ],
      ),
    );
  }
}

/// Interval curve shim (Flutter exposes Interval already).
typedef Intervals = Interval;

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final line = Paint()
      ..color = Dp.signal.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, r * 0.92, line);
    canvas.drawCircle(c, r * 0.6, Paint()
      ..color = Dp.signal.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    canvas.drawCircle(c, r * 0.3, Paint()
      ..color = Dp.signal.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // sweep
    canvas.drawArc(Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        -math.pi / 2 + t * 2 * math.pi, 1.15, false, line);

    canvas.drawCircle(c, r * 0.3, Paint()..color = Dp.signal.withValues(alpha: 0.06));
    canvas.drawCircle(c, 2.5, Paint()..color = Dp.signal);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Dp.line.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    const step = 32.0;
    var x = 0.0;
    while (x <= size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      x += step;
    }
    var y = 0.0;
    while (y <= size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      y += step;
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}