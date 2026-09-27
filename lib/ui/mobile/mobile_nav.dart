import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../core/command_center.dart';
import '../../ui/glyphs.dart';
import 'mobile_controls.dart';
import 'mobile_tokens.dart';

/// A single destination in the field dock.
class MDockTab {
  const MDockTab(this.glyph, this.label);
  final DGlyph glyph;
  final String label;
}

/// MDockBar — the field bottom navigation.
///
/// Replaces the desktop dock with a thumb-reachable bar built for a handset:
/// full-width pill, 66dp tall, 12sp sans labels (readable at arm's length), a
/// sliding accent indicator, an urgent-work badge, and a tricolor hairline that
/// ties it back to the national masthead language.
class MDockBar extends StatelessWidget {
  const MDockBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.badgeIndex,
  });

  final List<MDockTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final int? badgeIndex;

  /// Outer height of the bar excluding the safe-area inset.
  static const double height = 66;

  /// Horizontal breathing room kept on each side.
  static const double sidePad = 14;

  /// Bottom padding the bar reserves (safe area or a comfortable minimum).
  static double bottomInset(BuildContext context) =>
      math.max(MediaQuery.paddingOf(context).bottom, 12);

  /// Space a scroll view must keep clear so the dock never covers content.
  static double contentClearance(BuildContext context, {double extra = 18}) =>
      height + bottomInset(context) + extra;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;
    final maxW = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.fromLTRB(sidePad, 0, sidePad, bottomInset(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(maxW - sidePad * 2, 460)),
          child: SizedBox(
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dp.rLg),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0C1524).withValues(alpha: 0.94)
                        : Colors.white.withValues(alpha: 0.97),
                    border: Border.all(
                      color: isDark ? const Color(0xFF20304B) : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : const Color(0xFF64748B))
                            .withValues(alpha: isDark ? 0.55 : 0.20),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Sliding accent indicator behind the active destination.
                      AnimatedPositioned(
                        duration: Mo.standard,
                        curve: Mo.easeTech,
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1 / tabs.length,
                          child: FractionallySizedBox(
                            alignment: tabs.length > 1
                                ? Alignment(
                                    (index * 2 / (tabs.length - 1)) - 1, 0)
                                : Alignment.center,
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: MSig.accentFill(Dp.isDark ? 0.13 : 0.10),
                                borderRadius: BorderRadius.circular(Dp.rMd),
                                border: Border.all(
                                  color: MSig.accentRing,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Sovereign tricolor hairline across the top of the dock.
                      Positioned(
                        top: 0,
                        left: 24,
                        right: 24,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF9933),
                                Color(0xFFFFFFFF),
                                Color(0xFF138808),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            Expanded(
                              child: _MDockItem(
                                key: ValueKey('dock_tab_${tabs[i].label}'),
                                tab: tabs[i],
                                active: i == index,
                                badge: badgeIndex == i,
                                onTap: () {
                                  if (i == index) return;
                                  HapticFeedback.selectionClick();
                                  onSelect(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MDockItem extends StatefulWidget {
  const _MDockItem({
    super.key,
    required this.tab,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final MDockTab tab;
  final bool active;
  final bool badge;
  final VoidCallback onTap;

  @override
  State<_MDockItem> createState() => _MDockItemState();
}

class _MDockItemState extends State<_MDockItem> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? MSig.accent : Dp.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: Mo.micro,
        curve: Mo.easeTech,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    duration: Mo.fast,
                    curve: Mo.easeTech,
                    scale: widget.active ? 1.0 : 0.94,
                    child: Drishti.icon(
                      widget.tab.glyph,
                      size: 21,
                      color: color,
                      stroke: widget.active ? 2.1 : 1.7,
                    ),
                  ),
                  if (widget.badge)
                    Positioned(
                      top: -1,
                      right: -7,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: MSig.offline,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Dp.isDark ? const Color(0xFF0C1524) : Colors.white,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 14,
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: Mo.fast,
                    curve: Mo.easeTech,
                    style: MT.tab(
                      size: 10,
                      color: color,
                      w: widget.active ? FontWeight.w800 : FontWeight.w600,
                    ),
                    child: Text(
                      widget.tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// MTopBar — the field terminal app bar.
///
/// One 60dp band that answers "who am I, where am I, and is the link up" without
/// the crowded three-chip row the old bar used: emblem, identity block, live
/// connectivity ring, and one settings target. Everything else moved into the
/// page, where it has room to breathe.
class MTopBar extends StatelessWidget {
  const MTopBar({
    super.key,
    required this.cc,
    required this.onOpenSettings,
    this.title = 'Drishti Field Ops',
    this.subtitle,
  });

  final CommandCenter cc;
  final VoidCallback onOpenSettings;
  final String title;
  final String? subtitle;

  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    final online = !cc.isFieldOffline;
    final statusColor = online ? MSig.online : MSig.offline;

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(MSp.gutter, 0, 12, 0),
      decoration: BoxDecoration(
        color: Dp.isDark ? const Color(0xFF0A1120) : Colors.white,
        border: Border(bottom: BorderSide(color: Dp.hairline, width: 1.0)),
      ),
      child: Row(
        children: [
          // National emblem tile
          Container(
            width: 36,
            height: 36,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Dp.isDark ? const Color(0xFF13203A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: MSig.saffron, width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: MSig.saffron.withValues(alpha: Dp.isDark ? 0.26 : 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/dristhi.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Drishti.icon(DGlyph.shield, size: 18, color: MSig.accent),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: MT.title(size: 14, color: Dp.ink, w: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 7),
                    _PulseDot(color: statusColor, active: online),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? cc.mobileAssignedRoute,
                  style: MT.data(size: 10, color: Dp.textMuted, w: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Connectivity target: tap to simulate a low-signal zone.
          MIconButton(
            glyph: online ? DGlyph.signal : DGlyph.offlineCloud,
            onTap: () {
              HapticFeedback.selectionClick();
              cc.toggleFieldOffline();
            },
            size: 40,
            iconSize: 17,
            radius: 13,
            color: statusColor,
            background: statusColor.withValues(alpha: Dp.isDark ? 0.14 : 0.10),
            borderColor: statusColor.withValues(alpha: 0.45),
            badge: !online,
          ),
          const SizedBox(width: 8),
          MIconButton(
            key: const ValueKey('topbar_settings'),
            glyph: DGlyph.sliders,
            onTap: onOpenSettings,
            size: 40,
            iconSize: 17,
            radius: 13,
            color: Dp.inkSoft,
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.active});
  final Color color;
  final bool active;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Mo.livePulse,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = widget.active ? 1.0 : 0.4;
        final halo = widget.active ? (1.0 - _c.value) * 0.5 : 0.0;
        return SizedBox(
          width: 12,
          height: 12,
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: t),
                shape: BoxShape.circle,
                boxShadow: halo > 0
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: halo * 0.7),
                          blurRadius: 6,
                          spreadRadius: 1.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// MFab — the one always-available field action, docked above the bar.
class MFab extends StatelessWidget {
  const MFab({super.key, required this.label, required this.icon, this.onTap, this.accent});

  final String label;
  final DGlyph icon;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? MSig.saffron;
    return MButton(
      label: label,
      icon: icon,
      onTap: onTap,
      accent: c,
      kind: MButtonKind.primary,
      pill: true,
      expand: false,
      tall: false,
    );
  }
}
