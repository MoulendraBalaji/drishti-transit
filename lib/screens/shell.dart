import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../core/models.dart';
import '../ui/dock.dart';
import '../ui/glyphs.dart';
import '../ui/gov_masthead.dart';
import '../ui/tactile.dart';
import 'mobile/mobile_field_screens.dart';
import 'web/web_command_views.dart';

/// AppShell — Orchestrates the Divergent Architecture across Web & Mobile:
///
/// 1. MOBILE (Android) = FIELD CREW / ON-GROUND OPERATOR
///    Scope: ONE user, ONE assigned route at a time.
///    - My Route Today: assigned route alerts, urgent push-style alert, manual flag FAB, offline queue.
///    - Verify & Fix Workflow: 3-step on-site verification (AI bounding box, confirm/false-positive, mark repaired + photo proof).
///    - My Activity Log: personal work completed today with SLA indicator.
///
/// 2. WEB = CITY AUTHORITY / COMMAND-ROOM OPERATOR
///    Scope: The WHOLE fleet, ALL routes, aggregated.
///    - City-Wide Live Map: all active buses, alert pins, heatmap overlay, corridors.
///    - Assign & Dispatch: status pipeline (New -> Assigned -> Verified -> Resolved); Web ASSIGNS, Mobile RESOLVES.
///    - Fleet-Wide Analytics: multi-panel trend charts, 24h congestion, 8 corridor scorecards.
///    - Historical Explorer & Municipal Report Export: audit trail + official PDF/CSV certificate.
///    - Alert Configuration: severity confidence sliders & monitored corridor switches.
///
/// 3. Collapsible Operations Sidebar with styled Tactical Menu Bar Button.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  // Mobile Field Tabs
  static const _mobileTabs = [
    DockTab(DGlyph.route, 'MY ROUTE'),
    DockTab(DGlyph.wrench, 'VERIFY & FIX'),
    DockTab(DGlyph.clipboard, 'MY WORK'),
  ];

  // Web Command Tabs
  static const _webTabs = [
    DockTab(DGlyph.markRadar, 'FLEET MAP'),
    DockTab(DGlyph.target, 'ASSIGN & DISPATCH'),
    DockTab(DGlyph.stats, 'FLEET ANALYTICS'),
    DockTab(DGlyph.download, 'AUDIT & EXPORT'),
    DockTab(DGlyph.sliders, 'ALERT CONFIG'),
  ];

  int _mobileIndex = 0;
  int _webIndex = 0;
  bool _sidebarCollapsed = false;
  bool? _manualRoleIsWeb; // null = auto responsive by width >= 900
  DetectionEvent? _selectedVerifyEvent;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: Mo.scene,
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _onSwitchToVerify(DetectionEvent event) {
    setState(() {
      _selectedVerifyEvent = event;
      _mobileIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktopDefault = width >= 900;
    final isWebRole = _manualRoleIsWeb ?? isDesktopDefault;

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entrance, curve: Mo.easeTech),
          child: isWebRole ? _buildWebDesktopLayout(context) : _buildMobileFieldLayout(context),
        ),
      ),
    );
  }

  /// ============================================================
  /// MOBILE FIELD OPERATIONS APP LAYOUT
  /// Scope: Field Crew / On-Ground Operator (Single Route, On-site verify & resolve)
  /// ============================================================
  Widget _buildMobileFieldLayout(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final hasUrgent = cc.mobileRouteIncidents.any((e) => e.status == IncidentStatus.assigned || e.status == IncidentStatus.newAlert);

    final Widget activePage = switch (_mobileIndex) {
      0 => MobileRouteScreen(onSwitchToVerify: _onSwitchToVerify),
      1 => MobileVerifyScreen(initialEvent: _selectedVerifyEvent),
      _ => const MobileLogScreen(),
    };

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Masthead with Demo Role Toggle Pill
          _buildRoleSwitcherHeader(isWebCurrent: false),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: TabMotion(index: _mobileIndex, child: activePage),
                ),
                // Floating Tactical Mobile Dock
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DrishtiDock(
                    tabs: _mobileTabs,
                    index: _mobileIndex,
                    onSelect: (i) => setState(() => _mobileIndex = i),
                    badge: hasUrgent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================
  /// WEB COMMAND & CONTROL DASHBOARD LAYOUT
  /// Scope: City Authority / Command-Room Operator (Whole fleet, Dispatch, Analytics, Config)
  /// ============================================================
  Widget _buildWebDesktopLayout(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Dp.isDark;

    final Widget activePage = switch (_webIndex) {
      0 => const WebCityMapView(),
      1 => const WebDispatchView(),
      2 => const WebAnalyticsView(),
      3 => const WebAuditView(),
      _ => const WebConfigView(),
    };

    return Column(
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
                  color: isDark ? const Color(0xFF0A101E).withValues(alpha: 0.96) : const Color(0xFFF8FAFC).withValues(alpha: 0.96),
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
                        mainAxisAlignment: _sidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
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
                                          'COMMAND CENTER',
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

                    // 5 Web-Only Navigation Items
                    for (var i = 0; i < _webTabs.length; i++)
                      _SidebarNavButton(
                        icon: _webTabs[i].glyph,
                        label: _webTabs[i].label,
                        active: _webIndex == i,
                        collapsed: _sidebarCollapsed,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _webIndex = i);
                        },
                      ),

                    const Spacer(),

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
                    // Top Ops Bar
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
                              'PUNE METROPOLITAN TRANSIT GRID',
                              style: monoTxt(10, color: Dp.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Role Switcher Pill in Top Bar
                          _buildRoleSwitcherHeader(isWebCurrent: true, embedded: true),
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

  /// Header Role Switcher Pill: Lets judges toggle between Command Room (Web) & Field Crew (Mobile)
  Widget _buildRoleSwitcherHeader({required bool isWebCurrent, bool embedded = false}) {
    final isDark = Dp.isDark;

    final pillWidget = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142036) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(color: Dp.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleOption(
            label: 'COMMAND ROOM (WEB)',
            icon: DGlyph.markRadar,
            active: isWebCurrent,
            onTap: () => setState(() => _manualRoleIsWeb = true),
          ),
          _roleOption(
            label: 'FIELD CREW (MOBILE)',
            icon: DGlyph.wrench,
            active: !isWebCurrent,
            onTap: () => setState(() => _manualRoleIsWeb = false),
          ),
        ],
      ),
    );

    if (embedded) return pillWidget;

    return Container(
      color: isDark ? const Color(0xFF090E17) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const AshokaChakra(size: 14, color: Color(0xFF000080)),
          const SizedBox(width: 6),
          Text(
            'DEMO ROLE:',
            style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Expanded(child: Center(child: pillWidget)),
        ],
      ),
    );
  }

  Widget _roleOption({
    required String label,
    required DGlyph icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final isDark = Dp.isDark;

    return Tactile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? (isDark ? const Color(0xFF1E2F4C) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dp.rFull),
          border: Border.all(
            color: active ? (isDark ? Dp.accent : const Color(0xFF0284C7)) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Drishti.icon(
              icon,
              size: 12,
              color: active ? Dp.accent : Dp.textMuted,
              stroke: active ? 2.0 : 1.5,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: monoTxt(
                8.5,
                color: active ? Dp.ink : Dp.textMuted,
                w: active ? FontWeight.w800 : FontWeight.w600,
                ls: 0.5,
              ),
            ),
          ],
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