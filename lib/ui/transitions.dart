import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/motion.dart';

/// Route choreography kinds — one hand, used across all navigation.
enum RouteKind {
  /// Tab-root entry: settle up and in.
  enter,

  /// Pushed detail: lift + settle, the product's signature push.
  zoomIn,

  /// Boot / exit states.
  iris,
}

/// The single custom [Page] type used by every go_router pageBuilder,
/// replacing default Material transitions app-wide. Backed by go_router's own
/// [CustomTransitionPage], which builds a real declarative [Page] with a
/// bespoke transition vocabulary threaded through [transitionsBuilder].
class DrishtiRoute<T> extends CustomTransitionPage<T> {
  DrishtiRoute({
    required WidgetBuilder builder,
    this.kind = RouteKind.zoomIn,
  }) : super(
          child: Builder(builder: builder),
          transitionsBuilder: (context, animation, secondary, child) =>
              _transitionFor(kind, animation, child),
          transitionDuration: _durationFor(kind, reverse: false),
          reverseTransitionDuration: _durationFor(kind, reverse: true),
          maintainState: true,
          opaque: true,
          fullscreenDialog: false,
          barrierDismissible: false,
        );

  final RouteKind kind;

  static Duration _durationFor(RouteKind k, {required bool reverse}) {
    if (reverse) return Mo.fast;
    return switch (k) {
      RouteKind.enter => Mo.standard,
      RouteKind.zoomIn => Mo.scene + const Duration(milliseconds: 60),
      RouteKind.iris => Mo.scene,
    };
  }

  static Widget _transitionFor(
      RouteKind kind, Animation<double> animation, Widget? child) {
    switch (kind) {
      case RouteKind.enter:
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Mo.easeInOutTech),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Mo.easeOutTech)),
            child: child,
          ),
        );
      case RouteKind.iris:
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Mo.easeInOutTech),
          child: child,
        );
      case RouteKind.zoomIn:
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Mo.easeOutTech),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Mo.easeOutTech)),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.984, end: 1).animate(CurvedAnimation(
                  parent: animation, curve: Mo.easeOutTech)),
              child: child,
            ),
          ),
        );
    }
  }
}