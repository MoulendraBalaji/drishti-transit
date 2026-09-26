import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../ui/chrome.dart';
import '../ui/dock.dart';
import '../ui/glyphs.dart';
import '../ui/gov_masthead.dart';
import '../ui/tactile.dart';

/// AppShell — Hosts the 4 core screens:
/// A) Home / Mission (index 0)
/// B) Detection Feed (index 1)
/// C) Command Map (index 2)
/// D) Analytics (index 3)
///
/// Responsive:
/// - Mobile: DrishtiDock floating bottom bar with animated sliding pill indicator
/// - Desktop (>= 900px): Left command console rail with animated tab indicator
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    DockTab(DGlyph.shield, 'MISSION'),
    DockTab(DGlyph.camera, 'DETECTION'),
    DockTab(DGlyph.markRadar, 'COMMAND MAP'),
    DockTab(DGlyph.stats, 'ANALYTICS'),
  ];

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Mo.scene,
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _select(int index) {
    widget.shell.goBranch(
      index,
      initialLocation: index == widget.shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.shell.currentIndex;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entrance, curve: Mo.easeTech),
          child: isDesktop
              ? _buildDesktopLayout(context, idx)
              : _buildMobileLayout(idx),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(int idx) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const GovMasthead(dense: true),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: TabMotion(index: idx, child: widget.shell),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DrishtiDock(
                    tabs: _tabs,
                    index: idx,
                    onSelect: _select,
                    badge: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, int idx) {
    final cc = context.watch<CommandCenter>();
    final isDark = Dp.isDark;

    return Column(
      children: [
        const GovMasthead(),
        Expanded(
          child: Row(
            children: [
              // Left Ops Rail
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A101E).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
                  border: Border(
                    right: BorderSide(
                      color: isDark ? const Color(0xFF1B283F) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF142036) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFF9933),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9933).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/dristhi.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: AshokaChakra(size: 22, color: Dp.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DRISHTI-TRANSIT',
                                style: AppText.displaySmall(size: 14).copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Dp.ink,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'सत्यमेव जयते',
                                    style: TextStyle(
                                      fontFamily: AppText.sans,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF9933),
                                    ),
                                  ),
                                  Text(
                                    ' • AIS-140',
                                    style: monoTxt(8.5, color: Dp.accent, w: FontWeight.w700, ls: 0.8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const GovTricolorBar(height: 2.5),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Text(
                            'OPERATIONS CONSOLE',
                            style: monoTxt(9, color: Dp.textFaint, w: FontWeight.w700, ls: 1.2),
                          ),
                          const Spacer(),
                          AshokaChakra(size: 11, color: Dp.textFaint),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _tabs.length; i++)
                      _SidebarNavButton(
                        icon: _tabs[i].glyph,
                        label: _tabs[i].label,
                        active: idx == i,
                        onTap: () => _select(i),
                      ),
                    const Spacer(),
                    // Telemetry status module in sidebar with tricolor accent
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0E1628) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(Dp.rSm),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9933).withValues(alpha: isDark ? 0.08 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AshokaChakra(size: 13, color: const Color(0xFF000080)),
                              const SizedBox(width: 8),
                              Text(
                                'FLEET TELEMETRY',
                                style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w700, ls: 0.8),
                              ),
                              const Spacer(),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF138808),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${cc.busesOnline} Active Bus Scanners',
                            style: AppText.bodySmall.copyWith(
                              color: Dp.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cc.total} Live Defect Vectors',
                            style: monoTxt(9, color: Dp.textMuted),
                          ),
                          const SizedBox(height: 10),
                          const LivePill(dense: true, label: 'NIC GOV-NET ACTIVE'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top Ops Bar
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF090E17) : const Color(0xFFFFFFFF),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF1B283F) : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          AshokaChakra(size: 16, color: const Color(0xFF000080)),
                          const SizedBox(width: 8),
                          Text(
                            _tabs[idx].label,
                            style: monoTxt(12, color: Dp.accent, w: FontWeight.w800, ls: 1.2),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF485A75) : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'पुणे महानगर परिवहन • PUNE METROPOLITAN GRID',
                            style: monoTxt(10, color: Dp.textMuted),
                          ),
                          const Spacer(),
                          const GovBadge(label: 'NIC GOV-NET', sublabel: 'LIVE STREAM', dense: true),
                          const SizedBox(width: 14),
                          const _DesktopClock(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabMotion(index: idx, child: widget.shell),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  const _SidebarNavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final DGlyph icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return Tactile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeTech,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF16233B) : const Color(0xFFE2E8F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Dp.rSm),
          border: Border.all(
            color: active
                ? (isDark ? Dp.accent.withValues(alpha: 0.5) : const Color(0xFF0F172A))
                : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: active && isDark
              ? [
                  BoxShadow(
                    color: Dp.accent.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Drishti.icon(
              icon,
              size: 16,
              color: active
                  ? (isDark ? Dp.accent : const Color(0xFF0F172A))
                  : (isDark ? const Color(0xFF8899AC) : const Color(0xFF64748B)),
              stroke: active ? 2.0 : 1.6,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: monoTxt(
                11,
                color: active
                    ? Dp.ink
                    : (isDark ? const Color(0xFF8899AC) : const Color(0xFF64748B)),
                w: active ? FontWeight.w700 : FontWeight.w500,
                ls: 0.6,
              ),
            ),
            const Spacer(),
            if (active)
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 0.6),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF9933), Color(0xFF138808)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopClock extends StatefulWidget {
  const _DesktopClock();

  @override
  State<_DesktopClock> createState() => _DesktopClockState();
}

class _DesktopClockState extends State<_DesktopClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    return Text(
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)} IST',
      style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w700),
    );
  }
}