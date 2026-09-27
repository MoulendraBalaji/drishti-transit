import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../core/command_center.dart';
import '../../core/models.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/mobile/mobile_nav.dart';
import '../../ui/mobile/mobile_surfaces.dart';
import '../../ui/mobile/mobile_tokens.dart';
import 'field_crew_boot_screen.dart';
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
/// Opening choreography: the boot sequence plays over an opaque curtain, then
/// the curtain lifts while the app bar, page body, and dock settle in on a
/// single staggered timeline ([Mo.easeOutTech]) — so the terminal never simply
/// "appears".
class FieldCrewShell extends StatefulWidget {
  const FieldCrewShell({super.key});

  /// Route path served by [FieldCrewRouter] for field settings.
  static const String settingsPath = '/settings';

  @override
  State<FieldCrewShell> createState() => _FieldCrewShellState();
}

class _FieldCrewShellState extends State<FieldCrewShell>
    with TickerProviderStateMixin {
  static const _tabs = [
    MDockTab(DGlyph.route, 'MY ROUTE'),
    MDockTab(DGlyph.wrench, 'VERIFY & FIX'),
    MDockTab(DGlyph.clipboard, 'MY WORK'),
  ];

  int _currentIndex = 0;
  DetectionEvent? _selectedVerifyEvent;

  // Opening timeline: one controller, three staggered regions.
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  late final Animation<double> _barIn = CurvedAnimation(
    parent: _open,
    curve: const Interval(0.00, 0.52, curve: Mo.easeOutTech),
  );
  late final Animation<double> _bodyIn = CurvedAnimation(
    parent: _open,
    curve: const Interval(0.14, 0.86, curve: Mo.easeOutTech),
  );
  late final Animation<double> _dockIn = CurvedAnimation(
    parent: _open,
    curve: const Interval(0.34, 1.00, curve: Mo.easeOutTech),
  );

  // Boot curtain.
  bool _booting = true;

  late final AnimationController _curtain = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void dispose() {
    _open.dispose();
    _curtain.dispose();
    super.dispose();
  }

  void _onBootComplete() {
    if (!mounted) return;
    setState(() => _booting = false);
    _curtain.forward();
    _open.forward();
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
    final urgent = cc.mobileRouteIncidents.any(
      (e) => e.status == IncidentStatus.assigned || e.status == IncidentStatus.newAlert,
    );

    final Widget activePage = switch (_currentIndex) {
      0 => MobileRouteScreen(onSwitchToVerify: _onSwitchToVerify),
      1 => MobileVerifyScreen(initialEvent: _selectedVerifyEvent),
      _ => const MobileLogScreen(),
    };

    final dockClearance = MDockBar.height + MDockBar.bottomInset(context);

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  MReveal(
                    animation: _barIn,
                    offset: const Offset(0, -0.55),
                    child: MTopBar(
                      cc: cc,
                      onOpenSettings: () {
                        HapticFeedback.selectionClick();
                        context.push(FieldCrewShell.settingsPath);
                      },
                    ),
                  ),
                  const GovTricolorBar(height: 2.5),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: MReveal(
                            animation: _bodyIn,
                            offset: const Offset(0, 0.05),
                            scaleFrom: 0.995,
                            child: AnimatedSwitcher(
                              duration: Mo.standard,
                              switchInCurve: Mo.easeOutTech,
                              switchOutCurve: Mo.easeInTech,
                              transitionBuilder: (child, anim) {
                                final dx = _currentIndex > 0 ? 1.0 : -1.0;
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset(0.04 * dx, 0),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey<int>(_currentIndex),
                                child: activePage,
                              ),
                            ),
                          ),
                        ),

                        // The single always-available field action, docked above the bar.
                        Positioned(
                          right: MSp.gutter,
                          bottom: dockClearance + 14,
                          child: IgnorePointer(
                            ignoring: _currentIndex != 0,
                            child: AnimatedSlide(
                              duration: Mo.standard,
                              curve: Mo.easeTech,
                              offset: _currentIndex == 0
                                  ? Offset.zero
                                  : const Offset(0, 0.6),
                              child: AnimatedOpacity(
                                duration: Mo.standard,
                                curve: Mo.easeTech,
                                opacity: _currentIndex == 0 ? 1.0 : 0.0,
                                child: MFab(
                                  label: 'FLAG DEFECT',
                                  icon: DGlyph.shield,
                                  accent: MSig.saffron,
                                  onTap: () => _openManualFlag(context, cc),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: MReveal(
                            animation: _dockIn,
                            offset: const Offset(0, 0.55),
                            child: MDockBar(
                              tabs: _tabs,
                              index: _currentIndex,
                              badgeIndex: urgent ? 1 : null,
                              onSelect: (i) => setState(() => _currentIndex = i),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_booting)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: AnimatedBuilder(
                    animation: _curtain,
                    builder: (context, child) => Opacity(
                      opacity: 1.0 - _curtain.value,
                      child: Transform.scale(
                        scale: 1.0 + 0.06 * _curtain.value,
                        child: child,
                      ),
                    ),
                    child: FieldCrewBoot(onComplete: _onBootComplete),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openManualFlag(BuildContext context, CommandCenter cc) {
    HapticFeedback.mediumImpact();
    showFieldSheet<void>(
      context: context,
      builder: (_) => ManualFlagSheet(cc: cc),
    );
  }
}
