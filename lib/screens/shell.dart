import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/motion.dart';
import '../app/palette.dart';
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
    return Scaffold(
      backgroundColor: Dp.bg,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _entrance, curve: Mo.easeInOutTech),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
              .animate(CurvedAnimation(parent: _entrance, curve: Mo.easeOutTech)),
          child: Column(
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
          ),
        ),
      ),
    );
  }
}