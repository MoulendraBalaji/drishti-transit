import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import 'glyphs.dart';

/// A directional slide/fade that plays when the active tab changes.
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
        final t = Mo.easeOutTech.transform(_c.value);
        return Transform.translate(
          offset: Offset(dir * (1 - t) * 20, 0),
          child: Opacity(opacity: t.clamp(0.2, 1.0), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// A single tab spec for the dock.
class DockTab {
  const DockTab(this.glyph, this.label);
  final DGlyph glyph;
  final String label;
}

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
    final itemW = w / tabs.length;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: Tok.dockHeight + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: Dp.canvas,
        border: Border(top: BorderSide(color: Dp.hairline, width: 1.0)),
      ),
      child: Stack(
        children: [
          // Sliding active thumb with Mobbin stadium pill geometry
          AnimatedAlign(
            alignment: Alignment((index * 2 / (tabs.length - 1)) - 1, 0),
            duration: Mo.standard,
            curve: Mo.easeInOutTech,
            child: FractionallySizedBox(
              widthFactor: 1 / tabs.length,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Dp.canvasSoft,
                  borderRadius: BorderRadius.circular(Dp.rFull),
                  border: Border.all(color: Dp.hairline, width: 1.0),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                _DockItem(
                  width: itemW,
                  tab: tabs[i],
                  active: i == index,
                  badge: badge && i == 0,
                  onTap: () {
                    if (i == index) return;
                    HapticFeedback.selectionClick();
                    onSelect(i);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.width,
    required this.tab,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final double width;
  final DockTab tab;
  final bool active;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Dp.ink : Dp.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedDefaultTextStyle(
                  duration: Mo.fast,
                  curve: Mo.easeOutTech,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    height: 1,
                    letterSpacing: 0.4,
                  ),
                  child: Drishti.icon(
                    tab.glyph,
                    size: active ? 20 : 18,
                    color: color,
                    stroke: active ? 2.0 : 1.6,
                  ),
                ),
                if (badge)
                  Positioned(
                    top: -2,
                    right: -7,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Dp.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              tab.label,
              style: monoTxt(
                active ? 9.5 : 8.5,
                color: color,
                w: active ? FontWeight.w700 : FontWeight.w500,
                ls: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}