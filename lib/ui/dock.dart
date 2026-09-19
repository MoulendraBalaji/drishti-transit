import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import 'glyphs.dart';

/// A directional slide/fade that plays when the active tab changes — the
/// shell's deliberate substitute for default bottom-nav transitions. The tab
/// body itself is kept mounted (IndexedStack) so map state survives.
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
          offset: Offset(dir * (1 - t) * 26, 0),
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

  /// Small signal dot shown over the first tab when live.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final itemW = w / tabs.length;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: Tok.dockHeight + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: const BoxDecoration(
        color: Dp.surface,
        border: Border(top: BorderSide(color: Dp.line)),
      ),
      child: Stack(
        children: [
          // Sliding active thumb
          AnimatedAlign(
            alignment: Alignment((index * 2 / (tabs.length - 1)) - 1, 0),
            duration: Mo.standard,
            curve: Mo.easeInOutTech,
            child: FractionallySizedBox(
              widthFactor: 1 / tabs.length,
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Dp.signal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Dp.signal.withValues(alpha: 0.22)),
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
    final color = active ? Dp.signal : Dp.fog;
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
                  child: Drishti.icon(tab.glyph,
                      size: active ? 21 : 19, color: color),
                ),
                if (badge)
                  Positioned(
                    top: -1,
                    right: -7,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Dp.signal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tab.label,
              style: monoTxt(
                active ? 9 : 8,
                color: active ? Dp.signal : Dp.fog,
                w: active ? FontWeight.w700 : FontWeight.w500,
                ls: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}