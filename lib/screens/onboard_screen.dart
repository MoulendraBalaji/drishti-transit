import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../core/models.dart';
import '../core/street_engine.dart';
import '../ui/chrome.dart';
import '../ui/glyphs.dart';

/// Edge-AI camera tab — Mobbin Gallery-White design language.
/// Live procedural street feed with high-accuracy bounding boxes,
/// electric blue HUD reticles, CAM → EDGE → CLOUD → CMD relay strip,
/// and real-time detection telemetry log.
class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen>
    with TickerProviderStateMixin {
  static const int _feedSeed = 481;

  late final AnimationController _scene = AnimationController(
      vsync: this, duration: const Duration(hours: 24))
    ..forward();
  late final AnimationController _box = AnimationController(
    vsync: this,
    duration: Mo.scene,
  );
  late final AnimationController _conf = AnimationController(
    vsync: this,
    duration: Mo.slow,
  );
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));

  CommandCenter? _cc;
  String? _lastHeroId;
  DetectionVisual? _visual;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cc = context.watch<CommandCenter>();
    _cc = cc;
    final latest = cc.latest;
    if (latest != null && latest.busId == cc.heroBusId && latest.id != _lastHeroId) {
      _lastHeroId = latest.id;
      _activate(latest);
    }
  }

  void _activate(DetectionEvent e) {
    _visual = DetectionVisual(
      kind: e.kind,
      confidence: e.confidence,
      plate: e.plate,
    );
    _box.forward(from: 0);
    _conf.forward(from: 0);
    _pulse.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _scene.dispose();
    _box.dispose();
    _conf.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = _cc ?? context.watch<CommandCenter>();
    return ColoredBox(
      color: Dp.canvas,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _NodeBar(cc: cc),
            const SizedBox(height: 12),
            _feed(cc),
            const SizedBox(height: 12),
            _RelayStrip(pulse: _pulse),
            const SizedBox(height: 12),
            _ConfidencePanel(visual: _visual, conf: _conf, box: _box),
            const SizedBox(height: 16),
            const SectionHeader(
              'LIVE INFERENCE STREAM · HERO NODE',
              trailing: LivePill(dense: true, label: 'STREAMING'),
            ),
            const SizedBox(height: 8),
            _NodeLog(cc: cc),
          ],
        ),
      ),
    );
  }

  Widget _feed(CommandCenter cc) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dp.rMd - 1),
        child: AspectRatio(
          aspectRatio: 16 / 9.8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: StreetScenePainter(
                  seed: _feedSeed,
                  time: _scene.value * 86400,
                  detection: _visual,
                  boxProgress: _box.value,
                  confProgress: _conf.value,
                  locked: _conf.isCompleted,
                  confidence: _visual?.confidence ?? 0,
                ),
              ),
              _FeedHud(cc: cc),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeBar extends StatelessWidget {
  const _NodeBar({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final hero = cc.buses.where((b) => b.hero).firstOrNull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(color: Dp.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Dp.primary,
              borderRadius: BorderRadius.circular(Dp.rFull),
            ),
            child: Row(
              children: [
                Drishti.icon(DGlyph.bus, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  cc.heroBusId,
                  style: monoTxt(11, color: Colors.white, w: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EDGE NODE 04 · ULTRA-HD SENSOR',
                style: AppText.dataTiny.copyWith(
                  color: Dp.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${hero?.route ?? 'PB · ROUTE'} · ${hero?.gpsLabel ?? ''}',
                style: monoTxt(9.5, color: Dp.textMuted),
              ),
            ],
          ),
          const Spacer(),
          const LivePill(dense: true, label: 'LIVE FEED'),
        ],
      ),
    );
  }
}

/// Camera burn-in: REC, frame time, gps, model, corner brackets.
class _FeedHud extends StatelessWidget {
  const _FeedHud({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final hero = cc.buses.where((b) => b.hero).firstOrNull;
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornerBracketsPainter(Dp.accent),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RecDot(),
                  const SizedBox(width: 8),
                  Text(
                    'CAM 04 · ${_clock()}',
                    style: monoTxt(10.5, color: Colors.white, w: FontWeight.w700),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'GPS ${hero?.gpsLabel ?? '—'}',
                      style: monoTxt(9, color: Colors.white, w: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Dp.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DRISHTI-YOLOv8 · EDGE HIGH ACCURACY',
                          style: monoTxt(8.5,
                              color: Colors.white, w: FontWeight.w700, ls: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '30 fps · LAT 14 ms · ACC 98.6%',
                        style: monoTxt(9, color: Colors.white, w: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _SignalBars(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _clock() {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }
}

class _RecDot extends StatefulWidget {
  @override
  State<_RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<_RecDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Mo.livePulse)
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Dp.critical.withValues(alpha: 0.35 + 0.65 * _c.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  _CornerBracketsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    const l = 20.0;
    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, 0)
        ..lineTo(l, 0),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - l, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, l),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - l)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - l, size.height),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(l, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - l),
      p,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => old.color != color;
}

class _SignalBars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return Container(
          width: 3.5,
          height: 6.0 + i * 3.5,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8 + i * 0.05),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

/// The CAM → EDGE → CLOUD → CMD relay strip.
class _RelayStrip extends StatelessWidget {
  const _RelayStrip({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    const nodes = [
      (DGlyph.camera, 'CAM', 0.25),
      (DGlyph.shield, 'EDGE·AI', 0.50),
      (DGlyph.signal, 'CLOUD', 0.75),
      (DGlyph.target, 'COMMAND', 1.0),
    ];
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = pulse.value;
          return Row(
            children: [
              for (var i = 0; i < nodes.length; i++) ...[
                if (i > 0) Expanded(child: _relayLine(t, nodes[i - 1].$3, nodes[i].$3)),
                _relayNode(nodes[i].$1, nodes[i].$2, t >= nodes[i].$3),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _relayLine(double t, double from, double to) {
    final fill = ((t - from) / (to - from)).clamp(0.0, 1.0);
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Dp.field,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fill,
          child: Container(
            decoration: BoxDecoration(
              color: Dp.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _relayNode(DGlyph glyph, String label, bool lit) {
    final col = lit ? Dp.accent : Dp.textFaint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Drishti.icon(glyph, size: 16, color: col),
        const SizedBox(height: 4),
        Text(
          label,
          style: monoTxt(
            8.5,
            color: lit ? Dp.ink : Dp.textMuted,
            w: FontWeight.w700,
            ls: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: lit ? Dp.accent : Dp.hairline,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _ConfidencePanel extends StatelessWidget {
  const _ConfidencePanel({required this.visual, required this.conf, required this.box});
  final DetectionVisual? visual;
  final AnimationController conf;
  final AnimationController box;

  @override
  Widget build(BuildContext context) {
    final v = visual;
    if (v == null) {
      return Panel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Drishti.icon(DGlyph.scan, size: 18, color: Dp.textMuted),
            const SizedBox(width: 12),
            Text(
              'SCANNING STREET · AWAITING OBJECT DETECTION',
              style: AppText.dataTiny.copyWith(
                color: Dp.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Dp.canvasSoft,
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(color: Dp.hairline),
              ),
              child: Text(
                'IDLE',
                style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w700, ls: 0.8),
              ),
            ),
          ],
        ),
      );
    }
    final col = Dp.severityColor(v.kind.baseSeverity);
    final lock = box.value >= 1 && conf.isCompleted;
    final shown = lock ? v.confidence : v.confidence * conf.value;

    return AnimatedBuilder(
      animation: Listenable.merge([conf, box]),
      builder: (context, _) {
        return Panel(
          border: lock ? Dp.accent : Dp.hairline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Dp.canvasSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Dp.hairline),
                    ),
                    alignment: Alignment.center,
                    child: Drishti.icon(_glyphFor(v.kind), size: 16, color: col),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    v.kind.label.toUpperCase(),
                    style: AppText.dataStrong.copyWith(
                      color: Dp.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SeverityTag(v.kind.baseSeverity, size: 9),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: lock ? Dp.accent.withValues(alpha: 0.1) : Dp.canvasSoft,
                      borderRadius: BorderRadius.circular(Dp.rFull),
                      border: Border.all(
                        color: lock ? Dp.accent : Dp.hairline,
                      ),
                    ),
                    child: Text(
                      lock ? 'LOCKED · VERIFIED' : 'CLASSIFYING',
                      style: monoTxt(
                        9,
                        color: lock ? Dp.accent : Dp.textMuted,
                        w: FontWeight.w700,
                        ls: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${(shown * 100).toStringAsFixed(1)}%',
                    style: monoTxt(28, color: Dp.ink, w: FontWeight.w800, ls: -0.5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 8,
                        color: Dp.field,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: shown.clamp(0, 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: lock ? Dp.accent : col,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (v.plate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Dp.canvasSoft,
                    borderRadius: BorderRadius.circular(Dp.rSm),
                    border: Border.all(color: Dp.hairline),
                  ),
                  child: Row(
                    children: [
                      Drishti.icon(DGlyph.plate, size: 14, color: Dp.accent),
                      const SizedBox(width: 10),
                      Text(
                        'OCR LICENSE PLATE: ${v.plate!}',
                        style: monoTxt(13, color: Dp.ink, w: FontWeight.w700, ls: 1.2),
                      ),
                      const Spacer(),
                      const SeverityTag(SeverityClass.critical, size: 8),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  DGlyph _glyphFor(DetectionKind k) => switch (k) {
        DetectionKind.pothole => DGlyph.target,
        DetectionKind.roadFracture => DGlyph.route,
        DetectionKind.signLoss => DGlyph.info,
        DetectionKind.congestion => DGlyph.stacks,
        DetectionKind.pedRisk => DGlyph.pin,
        DetectionKind.plateCapture => DGlyph.plate,
      };
}

class _NodeLog extends StatelessWidget {
  const _NodeLog({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final hero = cc.incidents.where((e) => e.busId == cc.heroBusId).take(4).toList();
    if (hero.isEmpty) {
      return const Panel(
        child: Text('NO DETECTIONS THIS SESSION.', style: AppText.bodySmall),
      );
    }
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          for (final e in hero)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Dp.canvasSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Dp.hairline),
                    ),
                    child: Center(
                      child: Drishti.icon(
                        DGlyph.check,
                        size: 14,
                        color: Dp.severityColor(e.severity),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.kind.label.toUpperCase()} · ${e.confLabel}',
                          style: AppText.dataStrong.copyWith(color: Dp.ink, fontSize: 12),
                        ),
                        if (e.trackId != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${e.trackId} · SPEED ${e.speedKmh?.toStringAsFixed(0)} KM/H · DIST ${e.distanceM?.toStringAsFixed(1)} M',
                            style: AppText.dataTiny.copyWith(color: Dp.textMuted, fontSize: 8.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(e.timeLabel, style: AppText.dataTiny.copyWith(color: Dp.textMuted)),
                  const SizedBox(width: 8),
                  Drishti.icon(DGlyph.chevronRight, size: 12, color: Dp.textFaint),
                ],
              ),
            ),
        ],
      ),
    );
  }
}