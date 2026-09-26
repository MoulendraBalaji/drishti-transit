import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import 'glyphs.dart';

/// A directional subtle slide/fade that plays when the active tab changes.
class TabMotion extends StatefulWidget {
  const TabMotion({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<TabMotion> createState() => _TabMotionState();
}

class _TabMotionState extends State<TabMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Mo.standard,
    value: 1,
  );
  int _prev = 0;

  @override
  void didUpdateWidget(TabMotion old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      _prev = old.index;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = widget.index < _prev ? -1.0 : 1.0;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Mo.easeTech.transform(_c.value);
        return Transform.translate(
          offset: Offset(dir * (1 - t) * 16, 0),
          child: Opacity(opacity: t.clamp(0.2, 1.0), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// A single tab specification for the dock.
class DockTab {
  const DockTab(this.glyph, this.label);
  final DGlyph glyph;
  final String label;
}

/// DrishtiDock — The 4-screen bottom dock with animated sliding pill indicator.
/// Deliberately engineered with tactical ops-room styling, cyan live accents,
/// and smooth sliding physics between tabs.
class DrishtiDock extends StatelessWidget {
  const DrishtiDock({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelect,
    this.badge = false,
  });

  final List<DockTab> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final double dockWidth = math.min(w - 28, 480);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final isDark = Dp.isDark;
    final dockBg = isDark
        ? const Color(0xFF0D1526).withValues(alpha: 0.92)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.96);
    final dockBorder = isDark
        ? const Color(0xFF1E2F4C)
        : const Color(0xFFCBD5E1);
    final pillBg = isDark
        ? const Color(0xFF16233B)
        : const Color(0xFFE9EDF2);
    final pillBorder = isDark
        ? Dp.accent.withValues(alpha: 0.45)
        : const Color(0xFF0284C7).withValues(alpha: 0.5);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: math.max(bottomPad, 12),
        ),
        child: Center(
          child: SizedBox(
            width: dockWidth,
            height: 62,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dp.rFull),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: dockBg,
                    borderRadius: BorderRadius.circular(Dp.rFull),
                    border: Border.all(
                      color: dockBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : const Color(0xFF64748B))
                            .withValues(alpha: isDark ? 0.5 : 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: (isDark ? Dp.accent : const Color(0xFF0284C7))
                            .withValues(alpha: isDark ? 0.06 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Animated sliding pill indicator between tabs
                      AnimatedAlign(
                        alignment: Alignment(
                          tabs.length > 1
                              ? (index * 2 / (tabs.length - 1)) - 1
                              : 0.0,
                          0,
                        ),
                        duration: Mo.standard,
                        curve: Mo.easeTech,
                        child: FractionallySizedBox(
                          widthFactor: 1 / tabs.length,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(Dp.rFull),
                              border: Border.all(
                                color: pillBorder,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? Dp.accent : const Color(0xFF0284C7))
                                      .withValues(alpha: isDark ? 0.12 : 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Sovereign National Tricolor Hairline across top of dock
                      Positioned(
                        top: 0,
                        left: 28,
                        right: 28,
                        child: Container(
                          height: 2.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.0),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF9933), // Saffron
                                Color(0xFFFFFFFF), // White
                                Color(0xFF138808), // Green
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < tabs.length; i++)
                            Expanded(
                              child: _DockItem(
                                tab: tabs[i],
                                active: i == index,
                                badge: badge && i == 1,
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

class _DockItem extends StatefulWidget {
  const _DockItem({
    required this.tab,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final DockTab tab;
  final bool active;
  final bool badge;
  final VoidCallback onTap;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;
    final activeColor = isDark ? Dp.accent : const Color(0xFF0284C7);
    final inactiveColor = isDark ? const Color(0xFF8899AC) : const Color(0xFF64748B);
    final color = widget.active ? activeColor : inactiveColor;

    return GestureDetector(
      key: ValueKey('dock_tab_${widget.tab.label}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: Mo.micro,
        curve: Mo.easeTech,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Drishti.icon(
                    widget.tab.glyph,
                    size: widget.active ? 19 : 17,
                    color: color,
                    stroke: widget.active ? 2.1 : 1.6,
                  ),
                  if (widget.badge)
                    Positioned(
                      top: -2,
                      right: -7,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Dp.critical,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: Mo.fast,
                style: monoTxt(
                  widget.active ? 9.0 : 8.5,
                  color: color,
                  w: widget.active ? FontWeight.w700 : FontWeight.w500,
                  ls: 0.8,
                ),
                child: Text(widget.tab.label),
              ),
              if (widget.active) ...[
                const SizedBox(height: 2),
                Container(
                  width: 14,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}