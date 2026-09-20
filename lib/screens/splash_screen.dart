import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _boot,
                        curve: const Interval(0, 0.45),
                      ),
                      child: Column(
                        children: [
                          // Mobbin 30% squircle icon tile
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Dp.canvasSoft,
                              borderRadius: BorderRadius.circular(29),
                              border: Border.all(color: Dp.hairline, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Dp.isDark
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
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
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'DRISHTI',
                            textAlign: TextAlign.center,
                            style: AppText.displayHero.copyWith(
                              fontSize: 40,
                              letterSpacing: -1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: Dp.accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(Dp.rFull),
                              border: Border.all(
                                  color: Dp.accent.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Transforming city transit into a live neural sensor network.',
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(
                                color: Dp.textMuted,
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _BootReadout(boot: _boot, buses: cc.busesOnline),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _boot,
                        curve: const Interval(0.7, 1),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: CommandButton(
                          label: 'ENTER COMMAND SYSTEM',
                          onTap: _enter,
                          icon: DGlyph.target,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'DRISHTI TRANSIT · NATIONAL INITIATIVE',
                      textAlign: TextAlign.center,
                      style: AppText.dataTiny.copyWith(
                        color: Dp.textFaint,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
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
    final start = 0.28 + index * 0.14;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: AnimatedBuilder(
                animation: boot,
                builder: (context, child) {
                  final active = boot.value >= start;
                  return Transform.scale(
                    scale: active ? 1.0 : 0.6,
                    child: Opacity(
                      opacity: active ? 1.0 : 0.2,
                      child: Drishti.icon(
                        DGlyph.check,
                        size: 13,
                        color: active ? Dp.accent : Dp.textFaint,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: boot,
              builder: (context, child) {
                final active = boot.value >= start;
                return Text(
                  text,
                  style: AppText.data.copyWith(
                    color: active ? Dp.ink : Dp.textMuted,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Drishti.icon(DGlyph.shield, size: 14, color: Dp.accent),
              const SizedBox(width: 8),
              Text(
                'SYSTEM INITIALIZATION',
                style: AppText.dataTiny.copyWith(
                  color: Dp.ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              const LivePill(dense: true, label: 'BOOTING'),
            ],
          ),
          const SizedBox(height: 10),
          HairDivider(color: Dp.hairlineSoft, thickness: double.infinity),
          const SizedBox(height: 8),
          _line(0, 'GRID 42/42 · CORRIDORS SYNCHRONIZED'),
          _line(1, 'EDGE $buses/$buses · INFERENCE NODES ONLINE'),
          _line(2, 'GOOGLE MAPS & GEOSPATIAL ENGINES · ACTIVE'),
          _line(3, 'EDGE MODEL DRISHTI-YOLOv8 · HIGH ACCURACY READY'),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: boot,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: boot.value,
                minHeight: 3,
                backgroundColor: Dp.field,
                valueColor: const AlwaysStoppedAnimation<Color>(Dp.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}