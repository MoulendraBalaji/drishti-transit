import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import 'glyphs.dart';
import 'tactile.dart';

/// The official Government of India Tricolor Header Bar.
/// Saffron (#FF9933), White (#FFFFFF / #CBD5E1 in dark), Green (#138808).
class GovTricolorBar extends StatelessWidget {
  const GovTricolorBar({super.key, this.height = 3.5});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(child: Container(color: const Color(0xFFFF9933))), // Saffron
          Expanded(child: Container(color: Dp.isDark ? const Color(0xFFE2E8F0) : Colors.white)), // White
          Expanded(child: Container(color: const Color(0xFF138808))), // India Green
        ],
      ),
    );
  }
}

/// Official Government of India & Ministry of Road Transport and Highways masthead.
/// Appears at the very top of Drishti-Transit, providing official government branding,
/// bilingual titles, quick theme toggle (System / Dark / Light), and settings trigger.
class GovMasthead extends StatelessWidget {
  const GovMasthead({super.key, this.dense = false});
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Dp.isDark;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GovTricolorBar(height: 3.5),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 12,
            vertical: dense ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF070B13) : const Color(0xFFFFFFFF),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1B283F) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              // National Emblem Badge & Bilingual Ministry Masthead
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Official Government Logo / App Icon Tile
                  Container(
                    width: 32,
                    height: 32,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF142036) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2C4166) : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/dristhi.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Drishti.icon(DGlyph.shield, size: 16, color: Dp.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'भारत सरकार',
                            style: TextStyle(
                              fontFamily: AppText.sans,
                              fontSize: isDesktop ? 10.5 : 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                              letterSpacing: 0.2,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              '|',
                              style: monoTxt(9, color: Dp.textFaint),
                            ),
                          ),
                          Text(
                            'GOVERNMENT OF INDIA',
                            style: monoTxt(
                              isDesktop ? 9.5 : 8.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              w: FontWeight.w700,
                              ls: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isDesktop
                            ? 'सड़क परिवहन एवं राजमार्ग मंत्रालय • Ministry of Road Transport & Highways'
                            : 'MoRTH • SMART CITIES MISSION',
                        style: TextStyle(
                          fontFamily: AppText.sans,
                          fontSize: isDesktop ? 10 : 8.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF8899AC) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // AIS-140 Status Badge
              if (isDesktop) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111E33) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(Dp.rSm),
                    border: Border.all(
                      color: isDark ? const Color(0xFF223554) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF138808),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'NIC GOV-NET • AIS-140 CERTIFIED',
                        style: monoTxt(8.5, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155), w: FontWeight.w700, ls: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // Quick Theme Toggle Button (Sun / Moon / Auto)
              _buildQuickThemeToggle(context, cc),
              const SizedBox(width: 6),
              // Dedicated Settings Gear Button
              _buildSettingsButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickThemeToggle(BuildContext context, CommandCenter cc) {
    final mode = cc.themeMode;
    final isDark = Dp.isDark;

    final (DGlyph icon, String tip) = switch (mode) {
      ThemeMode.system => (DGlyph.stacks, 'Theme: System Native (Auto)'),
      ThemeMode.dark => (DGlyph.moon, 'Theme: Dark (Ops Room)'),
      ThemeMode.light => (DGlyph.sun, 'Theme: Light (Gov Portal)'),
    };

    return Tooltip(
      message: '$tip — Click to switch',
      child: Tactile(
        onTap: () {
          HapticFeedback.selectionClick();
          cc.toggleTheme();
        },
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF142036) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(Dp.rFull),
            border: Border.all(
              color: isDark ? const Color(0xFF2C4166) : const Color(0xFFCBD5E1),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Drishti.icon(icon, size: 13, color: isDark ? Dp.accent : const Color(0xFF0F172A)),
              const SizedBox(width: 4),
              Text(
                switch (mode) {
                  ThemeMode.system => 'AUTO',
                  ThemeMode.dark => 'DARK',
                  ThemeMode.light => 'LIGHT',
                },
                style: monoTxt(
                  8.5,
                  color: isDark ? Dp.accent : const Color(0xFF0F172A),
                  w: FontWeight.w700,
                  ls: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    final isDark = Dp.isDark;

    return Tooltip(
      message: 'Government Command & Node Settings',
      child: Tactile(
        key: const ValueKey('command_settings_button'),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/settings');
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF142036) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(Dp.rFull),
            border: Border.all(
              color: isDark ? const Color(0xFF2C4166) : const Color(0xFFCBD5E1),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Drishti.icon(
              DGlyph.settings,
              size: 14,
              color: isDark ? Dp.ink : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bespoke 24-Spoke Ashoka Chakra (Dharma Chakra) — Sovereign Indian National Emblem.
class AshokaChakra extends StatelessWidget {
  const AshokaChakra({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 1.4,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final defaultColor = Dp.isDark ? const Color(0xFF38BDF8) : const Color(0xFF000080);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AshokaChakraPainter(
          color: color ?? defaultColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _AshokaChakraPainter extends CustomPainter {
  const _AshokaChakraPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final hubPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer wheel rim
    canvas.drawCircle(center, radius - (strokeWidth / 2), rimPaint);

    // Inner center hub
    final hubRadius = radius * 0.22;
    canvas.drawCircle(center, hubRadius, hubPaint);

    // 24 Spokes (15 degrees each)
    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 15) * math.pi / 180;
      final start = Offset(
        center.dx + hubRadius * math.cos(angle),
        center.dy + hubRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - strokeWidth) * math.cos(angle),
        center.dy + (radius - strokeWidth) * math.sin(angle),
      );
      canvas.drawLine(start, end, spokePaint);
    }
  }

  @override
  bool shouldRepaint(_AshokaChakraPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Ambient Government Canvas with subtle National Tricolor Gradient
/// and authentic watermark Ashoka Chakra motif in the background.
class GovCanvas extends StatelessWidget {
  const GovCanvas({
    super.key,
    required this.child,
    this.showWatermark = true,
  });

  final Widget child;
  final bool showWatermark;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Dp.canvas,
        gradient: Dp.tricolorGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showWatermark)
            Positioned(
              right: -120,
              bottom: -120,
              child: IgnorePointer(
                child: Opacity(
                  opacity: isDark ? 0.032 : 0.024,
                  child: AshokaChakra(
                    size: 480,
                    color: isDark ? Colors.white : const Color(0xFF000080),
                    strokeWidth: 4.0,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Official Government of India micro-badge with national tricolor pip.
class GovBadge extends StatelessWidget {
  const GovBadge({
    super.key,
    required this.label,
    this.sublabel,
    this.dense = false,
  });

  final String label;
  final String? sublabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1726) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(Dp.rSm),
        border: Border.all(
          color: isDark ? const Color(0xFF223554) : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9933).withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // National tricolor micro pip
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 0.8),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF9933), Color(0xFF138808)],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: monoTxt(
              dense ? 8.5 : 9.5,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
              w: FontWeight.w700,
              ls: 0.5,
            ),
          ),
          if (sublabel != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('·', style: TextStyle(color: Dp.textFaint, fontSize: 8)),
            ),
            Text(
              sublabel!,
              style: monoTxt(
                dense ? 8 : 9,
                color: Dp.accent,
                w: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

