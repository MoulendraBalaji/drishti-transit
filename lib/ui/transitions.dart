import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/motion.dart';

/// Route choreography kinds for Drishti-Transit.
enum RouteKind {
  /// Tab switch or root screen entry: subtle upward slide + scale + fade.
  enter,

  /// Detail or modal focus: calibrated lift + settle.
  zoomIn,

  /// Instant fade for splash or state reset.
  iris,
}

/// The single custom [Page] type used by go_router across the entire app.
/// Eliminates default Android slide-up and default Material fade completely.
/// Implements the hand-tuned motion signature:
/// subtle scale (0.985 -> 1.0) + fade (0.0 -> 1.0) + slight vertical slide (0.025 -> 0.0)
/// powered by [Mo.easeTech] (Cubic(0.2, 0.0, 0.0, 1.0)).
class DrishtiRoute<T> extends CustomTransitionPage<T> {
  DrishtiRoute({
    required WidgetBuilder builder,
    this.kind = RouteKind.enter,
  }) : super(
          child: Builder(builder: builder),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _buildTransition(kind, animation, child),
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
      RouteKind.zoomIn => Mo.scene,
      RouteKind.iris => Mo.standard,
    };
  }

  static Widget _buildTransition(
    RouteKind kind,
    Animation<double> animation,
    Widget? child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Mo.easeTech,
      reverseCurve: Mo.easeInTech,
    );

    switch (kind) {
      case RouteKind.enter:
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.022),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.988, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );

      case RouteKind.zoomIn:
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.035),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.975, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );

      case RouteKind.iris:
        return FadeTransition(
          opacity: curved,
          child: child,
        );
    }
  }
}