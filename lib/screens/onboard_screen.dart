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

/// Edge-AI camera tab — the detection pipeline made visible. A live procedural
/// street feed with bounding boxes that draw themselves in while confidence
/// ticks up, a CAM → EDGE → CLOUD → CMD relay strip, and this node's event log.
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
      color: Dp.bg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
          children: [
            _NodeBar(cc: cc),
            const SizedBox(height: 10),
            _feed(cc),
            const SizedBox(height: 10),
            _RelayStrip(pulse: _pulse),
            const SizedBox(height: 10),
            _ConfidencePanel(visual: _visual, conf: _conf, box: _box),
            const SizedBox(height: 12),
            SectionHeader('THIS NODE · LAST DETECTIONS',
                trailing: const LivePill(dense: true, label: 'STREAMING')),
            const SizedBox(height: 6),
            _NodeLog(cc: cc),
          ],
        ),
      ),
    );
  }

  Widget _feed(CommandCenter cc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tok.cornerPanel),
      child: AspectRatio(
        aspectRatio: 16 / 9.6,
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
    );
  }
}

// ---------------------------------------------------------------------------

class _NodeBar extends StatelessWidget {
  const _NodeBar({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final hero = cc.buses.where((b) => b.hero).firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Dp.signal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Dp.signal.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Drishti.icon(DGlyph.bus, size: 15, color: Dp.signal),
              const SizedBox(width: 7),
              Text(cc.heroBusId,
                  style: monoTxt(12, color: Dp.signal, w: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EDGE NODE · REAR-CAM 04',
                style: AppText.dataTiny.copyWith(color: Dp.mist)),
            const SizedBox(height: 2),
            Text(
              '${hero?.route ?? 'PB · ROUTE'} · ${hero?.gpsLabel ?? ''}',
              style: monoTxt(9.5, color: Dp.mist),
            ),
          ],
        ),
        const Spacer(),
        Drishti.icon(DGlyph.signal, size: 18, color: Dp.signal),
        const SizedBox(width: 8),
        const LivePill(label: 'LIVE'),
      ],
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
        painter: _CornerBracketsPainter(Dp.signal),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RecDot(),
                  const SizedBox(width: 8),
                  Text('CAM 04 · ${_clock()}',
                      style: monoTxt(10, color: Dp.ink, w: FontWeight.w600)),
                  const Spacer(),
                  Text('GPS ${hero?.gpsLabel ?? '—'}',
                      style: monoTxt(9, color: Dp.mist)),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DRISHTI-YOLOv2 · EDGE',
                          style: monoTxt(9,
                              color: Dp.signal, w: FontWeight.w700, ls: 1)),
                      const SizedBox(height: 2),
                      Text('28 fps · LAT 22 ms · Q 0.94',
                          style: monoTxt(8.5, color: Dp.fog)),
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
        width: 9,
        height: 9,
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
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final l = 18.0;
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
          width: 3,
          height: 5.0 + i * 3.5,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color: Dp.signal.withValues(alpha: 0.75 + i * 0.08),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------

/// The CAM → EDGE → CLOUD → CMD relay strip; LEDs race across it when a
/// hero-bus detection fires.
class _RelayStrip extends StatelessWidget {
  const _RelayStrip({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    const nodes = [
      (DGlyph.camera, 'CAM', 0.28),
      (DGlyph.shield, 'EDGE·AI', 0.5),
      (DGlyph.signal, 'CLOUD', 0.74),
      (DGlyph.target, 'CMD', 1.0),
    ];
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = pulse.value;
          return Row(
            children: [
              for (var i = 0; i < nodes.length; i++) ...[
                if (i > 0) Expanded(child: _relayLine(t, nodes[i - 1].$3, nodes[i].$3)),
                _relayNode(
                    nodes[i].$1, nodes[i].$2, t >= nodes[i].$3),
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
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Dp.line,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fill,
          child: Container(
            decoration: BoxDecoration(
              color: Dp.signal,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                    color: Dp.signal.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _relayNode(DGlyph glyph, String label, bool lit) {
    final col = lit ? Dp.signal : Dp.fog;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: Mo.micro,
          style: TextStyle(fontSize: 15, height: 1, color: col),
          child: Drishti.icon(glyph, size: 15, color: col),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: monoTxt(8, color: lit ? Dp.signal : Dp.dim, w: FontWeight.w700, ls: 0.6)),
        const SizedBox(height: 3),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: lit ? Dp.signal : Dp.lineBright,
            shape: BoxShape.circle,
            boxShadow: lit
                ? [
                    BoxShadow(
                        color: Dp.signal.withValues(alpha: 0.6), blurRadius: 5),
                  ]
                : const [],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

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
        child: Row(
          children: [
            Drishti.icon(DGlyph.scan, size: 16, color: Dp.fog),
            const SizedBox(width: 10),
            Text('SCANNING STREET · AWAITING OBJECT',
                style: AppText.dataTiny.copyWith(color: Dp.fog, letterSpacing: 0.8)),
            const Spacer(),
            Text('IDLE', style: monoTxt(9, color: Dp.dim, w: FontWeight.w600, ls: 1)),
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
          glow: lock ? col : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Drishti.icon(_glyphFor(v.kind), size: 16, color: col),
                  const SizedBox(width: 8),
                  Text(v.kind.label.toUpperCase(),
                      style: AppText.dataStrong.copyWith(color: Dp.ink)),
                  const SizedBox(width: 8),
                  SeverityTag(v.kind.baseSeverity, size: 8.5),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: Mo.fast,
                    child: Text(
                      lock ? 'LOCKED' : 'TRACKING',
                      key: ValueKey(lock),
                      style: monoTxt(9,
                          color: lock ? Dp.signal : Dp.fog,
                          w: FontWeight.w700,
                          ls: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${(shown * 100).toStringAsFixed(0)}%',
                    style: monoTxt(26, color: lock ? Dp.signal : col, w: FontWeight.w700, ls: 0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 6,
                        color: Dp.raised2,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: shown.clamp(0, 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: lock ? Dp.signal : col,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (v.plate != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Drishti.icon(DGlyph.plate, size: 13, color: col),
                    const SizedBox(width: 8),
                    Text(v.plate!,
                        style: monoTxt(15, color: Dp.ink, w: FontWeight.w600, ls: 1.6)),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          for (final e in hero)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Dp.severityColor(e.severity).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: Dp.severityColor(e.severity).withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Drishti.icon(DGlyph.check,
                          size: 13,
                          color: Dp.severityColor(e.severity)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${e.kind.label.toUpperCase()} · ${e.confLabel}',
                      style: AppText.data.copyWith(color: Dp.ink),
                    ),
                  ),
                  Text(e.timeLabel, style: AppText.dataTiny.copyWith(color: Dp.fog)),
                  const SizedBox(width: 6),
                  Drishti.icon(DGlyph.chevronRight, size: 12, color: Dp.dim),
                ],
              ),
            ),
        ],
      ),
    );
  }
}