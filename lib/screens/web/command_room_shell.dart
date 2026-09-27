import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../app/typography.dart';
import '../../core/command_center.dart';
import '../../ui/dock.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/tactile.dart';
import '../detection_feed_screen.dart';
import 'command_room_settings_view.dart';
import 'web_command_views.dart';

/// CommandRoomShell — Top-level Operations Shell for the Command Room (Web) experience.
///
/// Scope: City Authority & Fleet Operations Control Room.
/// Workspaces:
/// 1. City-Wide Live Map
/// 2. Fleet-Wide Live Camera Feed
/// 3. Assign & Dispatch Console
/// 4. Fleet-Wide Analytics & Corridor Scorecards
/// 5. Historical Explorer & Municipal Audit Export
/// 6. Alert Configuration & Inference Thresholds
/// 7. Command Room Settings
///
/// Contains zero field-specific views and zero role-switching toggles.
class CommandRoomShell extends StatefulWidget {
  const CommandRoomShell({super.key});

  @override
  State<CommandRoomShell> createState() => _CommandRoomShellState();
}

class _CommandRoomShellState extends State<CommandRoomShell> with SingleTickerProviderStateMixin {
  static const _webTabs = [
    DockTab(DGlyph.markRadar, 'FLEET MAP'),
    DockTab(DGlyph.camera, 'LIVE FEED'),
    DockTab(DGlyph.target, 'ASSIGN & DISPATCH'),
    DockTab(DGlyph.stats, 'FLEET ANALYTICS'),
    DockTab(DGlyph.download, 'AUDIT & EXPORT'),
    DockTab(DGlyph.sliders, 'ALERT CONFIG'),
    DockTab(DGlyph.shield, 'COMMAND SETTINGS'),
  ];

  int _webIndex = 0;
  bool _sidebarCollapsed = false;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Mo.scene,
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Dp.isDark;

    final Widget activePage = switch (_webIndex) {
      0 => const WebCityMapView(),
      1 => const DetectionFeedScreen(),
      2 => const WebDispatchView(),
      3 => const WebAnalyticsView(),
      4 => const WebAuditView(),
      5 => const WebConfigView(),
      _ => const CommandRoomSettingsView(),
    };

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entrance, curve: Mo.easeTech),
          child: Column(
            children: [
              const GovMasthead(),
              Expanded(
                child: Row(
                  children: [
                    // Collapsible Left Operations Rail
                    AnimatedContainer(
                      duration: Mo.standard,
                      curve: Mo.easeTech,
                      width: _sidebarCollapsed ? 68 : 256,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0A101E).withValues(alpha: 0.96)
                            : const Color(0xFFF8FAFC).withValues(alpha: 0.96),
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
                          // Sidebar Header with Tactical Menu Bar Button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                            child: Row(
                              mainAxisAlignment: _sidebarCollapsed
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.spaceBetween,
                              children: [
                                if (!_sidebarCollapsed) ...[
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF142036) : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFF9933), width: 1.2),
                                          ),
                                          child: Image.asset(
                                            'assets/images/dristhi.jpeg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Center(
                                              child: AshokaChakra(size: 18, color: Dp.accent),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'DRISHTI-TRANSIT',
                                                style: AppText.displaySmall(size: 12.5).copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: Dp.ink,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'OPERATIONS CONTROL',
                                                style: monoTxt(8, color: const Color(0xFFFF9933), w: FontWeight.w800),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                // Tactical Menu Bar Button (Open/Close Sidebar)
                                _buildMenuBarButton(isDark: isDark),
                              ],
                            ),
                          ),
                          const GovTricolorBar(height: 2.0),
                          const SizedBox(height: 12),

                          if (!_sidebarCollapsed)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                'MUNICIPAL WORKSPACES',
                                style: monoTxt(8.5, color: Dp.textFaint, w: FontWeight.w800, ls: 1.0),
                              ),
                            ),

                          // Web Navigation Workspace Items
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: _webTabs.length,
                              itemBuilder: (context, i) {
                                return _SidebarNavButton(
                                  icon: _webTabs[i].glyph,
                                  label: _webTabs[i].label,
                                  active: _webIndex == i,
                                  collapsed: _sidebarCollapsed,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _webIndex = i);
                                  },
                                );
                              },
                            ),
                          ),

                          // Telemetry Status Module (Collapses smoothly)
                          if (!_sidebarCollapsed)
                            Container(
                              margin: const EdgeInsets.all(14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0E1628) : Colors.white,
                                borderRadius: BorderRadius.circular(Dp.rSm),
                                border: Border.all(color: Dp.hairline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const AshokaChakra(size: 12, color: Color(0xFF000080)),
                                      const SizedBox(width: 6),
                                      Text('FLEET TELEMETRY', style: monoTxt(9, color: Dp.ink, w: FontWeight.w800)),
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
                                  const SizedBox(height: 6),
                                  Text(
                                    '${cc.busesOnline} Buses · ${cc.total} Defect Vectors',
                                    style: monoTxt(8.5, color: Dp.textMuted),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF142036) : const Color(0xFFE2E8F0),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF138808), width: 1.2),
                                  ),
                                  child: const Center(
                                    child: AshokaChakra(size: 14, color: Color(0xFF000080)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Main Operations Canvas
                    Expanded(
                      child: Column(
                        children: [
                          // Top Operations Bar (Clean, spacious, zero demo role pill)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF090E17) : Colors.white,
                              border: Border(bottom: BorderSide(color: Dp.hairline)),
                            ),
                            child: Row(
                              children: [
                                const AshokaChakra(size: 15, color: Color(0xFF000080)),
                                const SizedBox(width: 8),
                                Text(
                                  _webTabs[_webIndex].label,
                                  style: monoTxt(12, color: Dp.accent, w: FontWeight.w800, ls: 1.0),
                                ),
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: Dp.textFaint)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'PUNE METROPOLITAN TRANSIT GRID · CENTRAL OPERATIONS',
                                    style: monoTxt(10, color: Dp.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const _DesktopClock(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabMotion(index: _webIndex, child: activePage),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tactical Menu Bar Button with bespoke styling
  Widget _buildMenuBarButton({required bool isDark}) {
    return Tooltip(
      message: _sidebarCollapsed ? 'Expand Operations Sidebar' : 'Collapse Operations Sidebar',
      child: Tactile(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _sidebarCollapsed = !_sidebarCollapsed);
        },
        child: AnimatedContainer(
          duration: Mo.fast,
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarCollapsed ? 8 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16233B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? Dp.accent.withValues(alpha: 0.45) : const Color(0xFF94A3B8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Dp.accent : const Color(0xFF0284C7)).withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Drishti.icon(
                DGlyph.menu,
                size: 14,
                color: isDark ? Dp.accent : const Color(0xFF0F172A),
                stroke: 2.1,
              ),
              if (!_sidebarCollapsed) ...[
                const SizedBox(width: 6),
                Text(
                  'MENU',
                  style: monoTxt(
                    9.5,
                    color: isDark ? Dp.accent : const Color(0xFF0F172A),
                    w: FontWeight.w800,
                    ls: 0.8,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_left,
                  size: 13,
                  color: Dp.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  const _SidebarNavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final DGlyph icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    final content = Tactile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeTech,
        margin: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12, vertical: 3),
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 10 : 14,
          vertical: 10,
        ),
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
          mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Drishti.icon(
              icon,
              size: 16,
              color: active
                  ? (isDark ? Dp.accent : const Color(0xFF0F172A))
                  : (isDark ? const Color(0xFF8899AC) : const Color(0xFF64748B)),
              stroke: active ? 2.0 : 1.6,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: monoTxt(
                    10.5,
                    color: active
                        ? Dp.ink
                        : (isDark ? const Color(0xFF8899AC) : const Color(0xFF64748B)),
                    w: active ? FontWeight.w700 : FontWeight.w500,
                    ls: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (active)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF9933), Color(0xFF138808)],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (collapsed) {
      return Tooltip(message: label, child: content);
    }
    return content;
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
