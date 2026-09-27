import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../core/command_center.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/mobile/mobile_tokens.dart';

/// FieldCrewBoot — the opening sequence for the Field Crew terminal.
///
/// A deliberate, complete cold-start: the tricolor sweeps in, the national emblem
/// resolves, the wordmark wipes up, and the hardware checklist reports in one
/// line at a time before a progress rail completes and the curtain lifts to
/// reveal the shell. It is fully frame-driven (no timers), so it is deterministic
/// and a tap skips straight to the end.
class FieldCrewBoot extends StatefulWidget {
  const FieldCrewBoot({super.key, required this.onComplete});

  /// Fired once the boot choreography has fully resolved.
  final VoidCallback onComplete;

  @override
  State<FieldCrewBoot> createState() => _FieldCrewBootState();
}

class _FieldCrewBootState extends State<FieldCrewBoot>
    with SingleTickerProviderStateMixin {
  static const List<String> _checklist = [
    'TERMINAL LINK · MUNICIPAL SECURE GRID',
    'EDGE NODES · 42/42 INFERENCE ONLINE',
    'GNSS LOCK · NAVIC L5 + GPS L1',
    'SHIFT PROFILE · UNIT FC-04 WEST',
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1560),
  )..forward();

  bool _signalled = false;

  late final Animation<double> _sweep = _seg(0.00, 0.30);
  late final Animation<double> _emblemIn = _seg(0.00, 0.34);
  late final Animation<double> _wordIn = _seg(0.16, 0.48);
  late final Animation<double> _subIn = _seg(0.30, 0.56);
  late final Animation<double> _cardIn = _seg(0.34, 0.68);
  late final Animation<double> _railIn = _seg(0.52, 0.94);
  late final Animation<double> _footIn = _seg(0.62, 0.95);
  late final List<Animation<double>> _lines = [
    for (var i = 0; i < 4; i++) _seg(0.34 + i * 0.11, 0.54 + i * 0.11),
  ];

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_signalled) {
        _signalled = true;
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _seg(double start, double end) => CurvedAnimation(
        parent: _c,
        curve: Interval(start, end, curve: Mo.easeOutTech),
      );

  void _skip() {
    HapticFeedback.mediumImpact();
    if (_c.isCompleted) return;
    _c.value = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final accent = MSig.accent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Container(
        color: Dp.isDark ? const Color(0xFF070C16) : const Color(0xFFF7F9FC),
        child: Stack(
          children: [
            // Ambient tricolor wash + emblem watermark
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: Dp.tricolorGradient),
              ),
            ),
            Positioned(
              right: -130,
              bottom: -150,
              child: IgnorePointer(
                child: Opacity(
                  opacity: Dp.isDark ? 0.04 : 0.03,
                  child: AshokaChakra(
                    size: 460,
                    color: Dp.isDark ? Colors.white : const Color(0xFF000080),
                    strokeWidth: 4.5,
                  ),
                ),
              ),
            ),

            // Tricolor sweep
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, child) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: Curves.easeOutCubic.transform(_sweep.value),
                    child: child,
                  ),
                ),
                child: const GovTricolorBar(height: 3),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Emblem
                        Center(
                          child: AnimatedBuilder(
                            animation: _emblemIn,
                            builder: (context, child) {
                              final t = _emblemIn.value;
                              return Opacity(
                                opacity: t,
                                child: Transform.scale(
                                  scale: 0.82 + 0.18 * t,
                                  child: child,
                                ),
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Radar sweep ring behind the mark
                                AnimatedBuilder(
                                  animation: _c,
                                  builder: (context, child) {
                                    final t = _c.value.clamp(0.0, 1.0);
                                    return Opacity(
                                      opacity: (1 - t) * 0.5,
                                      child: CustomPaint(
                                        size: const Size.square(150),
                                        painter: _BootRingPainter(
                                          progress: t,
                                          color: accent,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  width: 104,
                                  height: 104,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: Dp.isDark
                                        ? const Color(0xFF0F1A2C)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(31),
                                    border: Border.all(color: MSig.saffron, width: 1.6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: MSig.saffron
                                            .withValues(alpha: Dp.isDark ? 0.3 : 0.18),
                                        blurRadius: 26,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/dristhi.jpeg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Drishti.icon(
                                        DGlyph.shield,
                                        size: 44,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Wordmark wipe
                        AnimatedBuilder(
                          animation: _wordIn,
                          builder: (context, child) => Opacity(
                            opacity: _wordIn.value,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _wordIn.value,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            'DRISHTI',
                            textAlign: TextAlign.center,
                            style: MT.display(size: 38, color: Dp.ink).copyWith(
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        AnimatedBuilder(
                          animation: _subIn,
                          builder: (context, child) => Opacity(
                            opacity: _subIn.value,
                            child: Transform.translate(
                              offset: Offset(0, 6 * (1 - _subIn.value)),
                              child: child,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 54,
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF9933),
                                      Color(0xFFFFFFFF),
                                      Color(0xFF138808),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'FIELD OPERATIONS TERMINAL',
                                textAlign: TextAlign.center,
                                style: MT.eyebrow(size: 10.5, color: accent, ls: 2.6),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Municipal road-defect inspection & on-site repair unit',
                                textAlign: TextAlign.center,
                                style: MT.body(size: 12, color: Dp.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Hardware checklist
                        AnimatedBuilder(
                          animation: _cardIn,
                          builder: (context, child) => Opacity(
                            opacity: _cardIn.value,
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - _cardIn.value)),
                              child: child,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                            decoration: BoxDecoration(
                              color: Dp.card,
                              borderRadius: BorderRadius.circular(Dp.rMd),
                              border: Border.all(color: Dp.hairline),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: Dp.isDark ? 0.3 : 0.07),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Drishti.icon(DGlyph.shield, size: 14, color: accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SYSTEM INITIALISING',
                                      style: MT.eyebrow(size: 9.5, color: Dp.ink, ls: 1.6),
                                    ),
                                    const Spacer(),
                                    Text(
                                      cc.mobileAssignedRoute,
                                      style: MT.data(size: 9.5, color: Dp.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 11),
                                for (var i = 0; i < _checklist.length; i++)
                                  _BootLine(
                                    text: _checklist[i],
                                    animation: _lines[i],
                                    color: accent,
                                  ),
                                const SizedBox(height: 12),
                                AnimatedBuilder(
                                  animation: _railIn,
                                  builder: (context, _) => ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: _railIn.value,
                                      minHeight: 3,
                                      backgroundColor: Dp.field,
                                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        AnimatedBuilder(
                          animation: _footIn,
                          builder: (context, child) => Opacity(
                            opacity: _footIn.value,
                            child: child,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'TAP TO CONTINUE',
                                style: MT.eyebrow(size: 9, color: Dp.textFaint, ls: 2.0),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'MoRTH AIS-140 · PMPML WEST CORRIDOR',
                                textAlign: TextAlign.center,
                                style: MT.data(
                                  size: 9.5,
                                  color: Dp.textFaint,
                                  w: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootLine extends StatelessWidget {
  const _BootLine({required this.text, required this.animation, required this.color});

  final String text;
  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Padding(
            padding: EdgeInsets.only(top: 6 * (1 - t)),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * t,
                      child: Drishti.icon(DGlyph.check, size: 12, color: color, stroke: 2.2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: MT.data(
                      size: 10.5,
                      color: t > 0.9 ? Dp.ink : Dp.textMuted,
                      w: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BootRingPainter extends CustomPainter {
  _BootRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final t = (progress * 1.4 - i * 0.18).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final r = maxR * (0.42 + 0.58 * (1 - t));
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.30 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // Four tick marks to read as an ops reticle.
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = (math.pi / 2) * i + math.pi / 4;
      final inner = maxR * 0.86;
      final outer = maxR * 0.96;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * outer, math.sin(a) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BootRingPainter old) =>
      old.progress != progress || old.color != color;
}
