import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../ui/chrome.dart';
import '../ui/dock.dart';
import '../ui/glyphs.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    DockTab(DGlyph.target, 'COMMAND'),
    DockTab(DGlyph.camera, 'EDGE'),
    DockTab(DGlyph.stats, 'INSIGHT'),
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
    widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.shell.currentIndex;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _entrance, curve: Mo.easeInOutTech),
        child: isDesktop ? _buildAdminDashboard(context, idx) : _buildMobileLayout(idx),
      ),
    );
  }

  Widget _buildMobileLayout(int idx) {
    return Stack(
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
    );
  }

  Widget _buildAdminDashboard(BuildContext context, int idx) {
    final cc = context.watch<CommandCenter>();
    final isDark = Dp.isDark;

    return Row(
      children: [
        // Left Sidebar (Mobbin Admin Dashboard Navigation with high contrast in dark mode)
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF),
            border: Border(
              right: BorderSide(
                color: isDark ? const Color(0xFF30363D) : Dp.hairline,
                width: 1.2,
              ),
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(2, 0),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/settings');
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF38444D) : Dp.hairline,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/dristhi.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Drishti.icon(DGlyph.bus, size: 20, color: Dp.accent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DRISHTI',
                          style: AppText.displaySmall(size: 16).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFFF0F6FC) : Dp.ink,
                          ),
                        ),
                        Text(
                          'ADMIN CONSOLE',
                          style: AppText.dataTiny.copyWith(
                            color: Dp.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HairDivider(
                color: isDark ? const Color(0xFF30363D) : Dp.hairline,
                thickness: double.infinity,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'NAVIGATION',
                  style: AppText.dataTiny.copyWith(
                    color: isDark ? const Color(0xFF8B949E) : Dp.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SidebarNavButton(
                icon: DGlyph.target,
                label: 'Central Command',
                active: idx == 0,
                onTap: () => _select(0),
              ),
              _SidebarNavButton(
                icon: DGlyph.camera,
                label: 'Edge Camera Node',
                active: idx == 1,
                onTap: () => _select(1),
              ),
              _SidebarNavButton(
                icon: DGlyph.stats,
                label: 'Network Insights',
                active: idx == 2,
                onTap: () => _select(2),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'PREFERENCES',
                  style: AppText.dataTiny.copyWith(
                    color: isDark ? const Color(0xFF8B949E) : Dp.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SidebarNavButton(
                icon: DGlyph.settings,
                label: 'System Settings',
                active: false,
                onTap: () => context.push('/settings'),
              ),
              const Spacer(),
              // Telemetry status panel in sidebar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2128) : Dp.canvasSoft,
                  borderRadius: BorderRadius.circular(Dp.rSm),
                  border: Border.all(
                    color: isDark ? const Color(0xFF38444D) : Dp.hairline,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Dp.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FLEET TELEMETRY',
                          style: AppText.dataTiny.copyWith(
                            color: isDark ? const Color(0xFFF0F6FC) : Dp.ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${cc.busesOnline} Bus Nodes Online',
                      style: AppText.bodySmall.copyWith(
                        color: isDark ? Colors.white : Dp.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cc.total} Detections Logged',
                      style: AppText.dataTiny.copyWith(
                        color: isDark ? const Color(0xFF8B949E) : Dp.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const LivePill(dense: true, label: 'SYSTEM ACTIVE'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main Admin Area
        Expanded(
          child: Column(
            children: [
              // Top Admin Bar
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Dp.canvas,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF30363D) : Dp.hairline,
                      width: 1.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _pageTitle(idx),
                      style: AppText.displaySmall(size: 16).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isDark ? const Color(0xFFF0F6FC) : Dp.ink,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Search bar styled like Google Places
                    Container(
                      width: 280,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D1117) : Dp.field,
                        borderRadius: BorderRadius.circular(Dp.rFull),
                        border: Border.all(
                          color: isDark ? const Color(0xFF30363D) : Dp.hairlineSoft,
                        ),
                      ),
                      child: Row(
                        children: [
                          Drishti.icon(
                            DGlyph.target,
                            size: 14,
                            color: isDark ? const Color(0xFF8B949E) : Dp.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Search Pune corridors, stops…',
                            style: AppText.bodySmall.copyWith(
                              color: isDark ? const Color(0xFF8B949E) : Dp.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF21262D) : Dp.canvasSoft,
                        borderRadius: BorderRadius.circular(Dp.rFull),
                        border: Border.all(
                          color: isDark ? const Color(0xFF38444D) : Dp.hairline,
                        ),
                      ),
                      child: Row(
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
                          const SizedBox(width: 6),
                          Text(
                            'MAPS API LINKED',
                            style: monoTxt(
                              9,
                              color: isDark ? const Color(0xFFF0F6FC) : Dp.ink,
                              w: FontWeight.w700,
                              ls: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const LivePill(label: 'ADMIN LIVE'),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/settings');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF21262D) : Dp.canvasSoft,
                          borderRadius: BorderRadius.circular(Dp.rFull),
                          border: Border.all(
                            color: isDark ? const Color(0xFF38444D) : Dp.hairline,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Drishti.icon(
                              DGlyph.settings,
                              size: 13,
                              color: isDark ? const Color(0xFFF0F6FC) : Dp.ink,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SETTINGS',
                              style: monoTxt(
                                9,
                                color: isDark ? const Color(0xFFF0F6FC) : Dp.ink,
                                w: FontWeight.w700,
                                ls: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
    );
  }

  String _pageTitle(int idx) {
    switch (idx) {
      case 0:
        return 'Central Fleet Command & Geospatial Stream';
      case 1:
        return 'Edge-AI High Accuracy Camera Inference';
      case 2:
        return 'Network Insights & Defect Analytics';
      default:
        return 'Drishti Transit';
    }
  }
}

class _SidebarNavButton extends StatefulWidget {
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
  State<_SidebarNavButton> createState() => _SidebarNavButtonState();
}

class _SidebarNavButtonState extends State<_SidebarNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;
    final bool active = widget.active;

    final Color bg;
    final Color fg;
    final Color border;
    final List<BoxShadow>? shadows;

    if (active) {
      bg = Dp.accent; // Electric blue #0066FF
      fg = Colors.white;
      border = isDark ? const Color(0xFF3385FF) : const Color(0xFF0052CC);
      shadows = [
        BoxShadow(
          color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.40 : 0.25),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    } else {
      if (_hovered) {
        bg = isDark ? const Color(0xFF262C36) : const Color(0xFFF2F4F7);
        fg = isDark ? Colors.white : Dp.ink;
        border = isDark ? const Color(0xFF38444D) : Dp.hairline;
        shadows = null;
      } else {
        bg = isDark ? const Color(0xFF1C2128) : Colors.transparent;
        fg = isDark ? const Color(0xFFE6EDF3) : Dp.ink;
        border = isDark ? const Color(0xFF2D333B) : Colors.transparent;
        shadows = null;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(Dp.rFull),
            child: AnimatedContainer(
              duration: Mo.fast,
              curve: Mo.easeOutTech,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(color: border, width: 1.2),
                boxShadow: shadows,
              ),
              child: Row(
                children: [
                  Drishti.icon(
                    widget.icon,
                    size: 16,
                    color: fg,
                    stroke: active ? 2.2 : 1.8,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: AppText.label.copyWith(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (active) ...[
                    const Spacer(),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}