import 'dart:async';

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

/// Mission boot screen — Mobbin gallery-white design language.
/// 30% squircle Drishti icon tile, bold typography, edge system telemetry,
/// and stadium-pill entrance CTA.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _boot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  Timer? _advance;

  @override
  void initState() {
    super.initState();
    _advance = Timer(const Duration(milliseconds: 3200), _enter);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GestureDetector(
        onTap: _enter,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: CurvedAnimation(
                      parent: _boot, curve: const Interval(0, 0.45)),
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.1), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: _boot, curve: Mo.easeOutTech)),
                    child: Column(
                      children: [
                        // Mobbin 30% squircle icon tile
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(31),
                            border: Border.all(color: Dp.hairline, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/dristhi.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Dp.primary,
                                alignment: Alignment.center,
                                child: const Text(
                                  'D',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'DRISHTI',
                          style: AppText.displayHero.copyWith(
                            fontSize: 44,
                            letterSpacing: -1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Dp.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'EDGE-AI URBAN INTELLIGENCE',
                              style: AppText.dataTiny.copyWith(
                                color: Dp.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Transforming city transit into a live neural sensor network.',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            color: Dp.textMuted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                _BootReadout(boot: _boot, buses: cc.busesOnline),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: CurvedAnimation(
                      parent: _boot, curve: const Interval(0.7, 1)),
                  child: CommandButton(
                    label: 'ENTER COMMAND SYSTEM',
                    onTap: _enter,
                    icon: DGlyph.target,
                  ),
                ),
                const Spacer(),
                Text(
                  'DRISHTI TRANSIT · NATIONAL INITIATIVE',
                  style: AppText.dataTiny.copyWith(
                    color: Dp.textFaint,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
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
    final start = 0.35 + index * 0.12;
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: boot, curve: Interval(start, (start + 0.18).clamp(0, 1))),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: boot, curve: Mo.easeOutTech)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: AnimatedBuilder(
                  animation: boot,
                  builder: (context, child) => Opacity(
                    opacity: boot.value > start + 0.05 ? 1 : 0,
                    child: child,
                  ),
                  child: Drishti.icon(DGlyph.check, size: 13, color: Dp.accent),
                ),
              ),
              Text(
                text,
                style: AppText.data.copyWith(
                  color: Dp.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(0, 'GRID 42/42 · CORRIDORS SYNCHRONIZED'),
          _line(1, 'EDGE $buses/$buses · INFERENCE NODES ONLINE'),
          _line(2, 'GOOGLE MAPS & GEOPATIAL ENGINES · ACTIVE'),
          _line(3, 'EDGE MODEL DRISHTI-YOLOv8 · HIGH ACCURACY READY'),
        ],
      ),
    );
  }
}