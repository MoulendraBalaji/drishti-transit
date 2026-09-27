import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../app/typography.dart';
import '../../core/command_center.dart';
import '../../core/models.dart';
import '../../ui/dock.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/tactile.dart';
import 'field_crew_settings_screen.dart';
import 'mobile_field_screens.dart';

/// FieldCrewShell — Top-level navigation shell for the Field Crew Mobile App.
///
/// Scope: Single on-ground field worker assigned to a specific transit route/zone.
/// Contains ONLY:
/// 1. My Route (home)
/// 2. Verify & Fix
/// 3. My Work
/// 4. Field Settings (route/zone reassignment, notification prefs, offline queue, account/logout)
///
/// Completely separate from any central command interfaces.
class FieldCrewShell extends StatefulWidget {
  const FieldCrewShell({super.key});

  @override
  State<FieldCrewShell> createState() => _FieldCrewShellState();
}

class _FieldCrewShellState extends State<FieldCrewShell> with SingleTickerProviderStateMixin {
  static const _tabs = [
    DockTab(DGlyph.route, 'MY ROUTE'),
    DockTab(DGlyph.wrench, 'VERIFY & FIX'),
    DockTab(DGlyph.clipboard, 'MY WORK'),
  ];

  int _currentIndex = 0;
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
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final hasUrgent = cc.mobileRouteIncidents.any(
      (e) => e.status == IncidentStatus.assigned || e.status == IncidentStatus.newAlert,
    );

    final Widget activePage = switch (_currentIndex) {
      0 => MobileRouteScreen(onSwitchToVerify: _onSwitchToVerify),
      1 => MobileVerifyScreen(initialEvent: _selectedVerifyEvent),
      _ => const MobileLogScreen(),
    };

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _entrance, curve: Mo.easeTech),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Clean Municipal Field Top App Bar (reclaims space previously occupied by demo toggle)
                _buildFieldCrewAppBar(context, cc),
                const GovTricolorBar(height: 2.0),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: TabMotion(index: _currentIndex, child: activePage),
                      ),
                      // Floating Tactical Mobile Dock
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DrishtiDock(
                          tabs: _tabs,
                          index: _currentIndex,
                          onSelect: (i) => setState(() => _currentIndex = i),
                          badge: hasUrgent,
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
    );
  }

  /// Simple, purpose-built mobile app bar showing route name, connection status, and settings button.
  Widget _buildFieldCrewAppBar(BuildContext context, CommandCenter cc) {
    final isDark = Dp.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090E17) : Colors.white,
        border: Border(bottom: BorderSide(color: Dp.hairline, width: 1.0)),
      ),
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
                child: AshokaChakra(size: 16, color: Dp.accent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DRISHTI FIELD OPERATIONS',
                  style: monoTxt(8.5, color: const Color(0xFFFF9933), w: FontWeight.w800, ls: 0.8),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cc.mobileAssignedRoute.toUpperCase(),
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          letterSpacing: 0.4,
                          color: Dp.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Dp.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'UNIT 04',
                        style: monoTxt(8, color: Dp.accent, w: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Connection status badge (tactile tap toggles offline simulation)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              cc.toggleFieldOffline();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cc.isFieldOffline
                    ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                    : const Color(0xFF138808).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(
                  color: cc.isFieldOffline ? const Color(0xFFDC2626) : const Color(0xFF138808),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cc.isFieldOffline ? const Color(0xFFDC2626) : const Color(0xFF138808),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cc.isFieldOffline ? 'OFFLINE' : 'ONLINE',
                    style: monoTxt(
                      8.5,
                      color: cc.isFieldOffline ? const Color(0xFFDC2626) : const Color(0xFF138808),
                      w: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Settings Gear Button leading to real Field Settings
          Tactile(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FieldCrewSettingsScreen(),
                ),
              );
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Dp.canvasSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Dp.hairline),
              ),
              child: Center(
                child: Drishti.icon(DGlyph.sliders, size: 15, color: Dp.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
