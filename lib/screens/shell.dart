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
    return Column(
      children: [
        Expanded(
          child: TabMotion(index: idx, child: widget.shell),
        ),
        DrishtiDock(
          tabs: _tabs,
          index: idx,
          onSelect: _select,
          badge: true,
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(BuildContext context, int idx) {
    final cc = context.watch<CommandCenter>();
    return Row(
      children: [
        // Left Sidebar (Mobbin Admin Dashboard Navigation)
        Container(
          width: 260,
          decoration: const BoxDecoration(
            color: Dp.canvas,
            border: Border(
              right: BorderSide(color: Dp.hairline, width: 1.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Dp.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
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
              const HairDivider(color: Dp.hairline, thickness: double.infinity),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'NAVIGATION',
                  style: AppText.dataTiny.copyWith(
                    color: Dp.textFaint,
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
              const Spacer(),
              // Telemetry status panel in sidebar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Dp.canvasSoft,
                  borderRadius: BorderRadius.circular(Dp.rSm),
                  border: Border.all(color: Dp.hairline),
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
                            color: Dp.ink,
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
                        color: Dp.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cc.total} Detections Logged',
                      style: AppText.dataTiny.copyWith(color: Dp.textMuted),
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
                decoration: const BoxDecoration(
                  color: Dp.canvas,
                  border: Border(
                    bottom: BorderSide(color: Dp.hairline, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _pageTitle(idx),
                      style: AppText.displaySmall(size: 16).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Search bar styled like Google Places
                    Container(
                      width: 280,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Dp.field,
                        borderRadius: BorderRadius.circular(Dp.rFull),
                        border: Border.all(color: Dp.hairlineSoft),
                      ),
                      child: Row(
                        children: [
                          Drishti.icon(DGlyph.target, size: 14, color: Dp.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            'Search Pune corridors, stops…',
                            style: AppText.bodySmall.copyWith(
                              color: Dp.textMuted,
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
                        color: Dp.canvasSoft,
                        borderRadius: BorderRadius.circular(Dp.rFull),
                        border: Border.all(color: Dp.hairline),
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
                            style: monoTxt(9, color: Dp.ink, w: FontWeight.w700, ls: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const LivePill(label: 'ADMIN LIVE'),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(Dp.rFull),
          child: AnimatedContainer(
            duration: Mo.fast,
            curve: Mo.easeOutTech,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? Dp.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(Dp.rFull),
            ),
            child: Row(
              children: [
                Drishti.icon(
                  icon,
                  size: 16,
                  color: active ? Colors.white : Dp.ink,
                  stroke: active ? 2.0 : 1.6,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppText.label.copyWith(
                    color: active ? Colors.white : Dp.ink,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (active) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Dp.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}