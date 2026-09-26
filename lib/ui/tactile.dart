import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import 'glyphs.dart';

/// Tactile wrapper providing the signature micro-interaction for Drishti-Transit:
/// - Quick scale-down (0.97) + subtle opacity/color shift on tap-down
/// - Smooth spring-back on release
/// - Soft haptic via [HapticFeedback.lightImpact] on mobile
/// - Consistent tactile confirmation across both Web and Android.
class Tactile extends StatefulWidget {
  const Tactile({
    super.key,
    required this.child,
    this.onTap,
    this.scale = Mo.pressScale,
    this.primary = false,
    this.cursor = SystemMouseCursors.click,
    this.enableFeedback = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool primary;
  final MouseCursor cursor;
  final bool enableFeedback;

  @override
  State<Tactile> createState() => _TactileState();
}

class _TactileState extends State<Tactile> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _pressed = true);
    if (widget.enableFeedback) {
      if (widget.primary) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? widget.cursor : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1.0,
          duration: Mo.micro,
          curve: Mo.easeTech,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.88 : 1.0,
            duration: Mo.micro,
            curve: Mo.easeTech,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A tactile command-center button with custom styling, no Material defaults.
class TactileButton extends StatelessWidget {
  const TactileButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.accent,
    this.outline = false,
    this.dense = false,
    this.expanded = false,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onTap;
  final DGlyph? icon;
  final Color? accent;
  final bool outline;
  final bool dense;
  final bool expanded;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final activeColor = accent ?? Dp.accent;
    final bg = outline
        ? Colors.transparent
        : (accent != null ? activeColor : Dp.card);
    final fg = outline
        ? activeColor
        : (accent != null ? Dp.onSignal : Dp.ink);
    final border = outline
        ? activeColor.withValues(alpha: 0.6)
        : Dp.hairline;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 14 : 20,
        vertical: dense ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(color: border, width: 1.2),
        boxShadow: outline
            ? null
            : [
                BoxShadow(
                  color: (accent != null ? activeColor : Colors.black)
                      .withValues(alpha: accent != null ? 0.25 : 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Drishti.icon(icon!, size: dense ? 14 : 16, color: fg, stroke: 1.8),
            SizedBox(width: dense ? 6 : 8),
          ],
          Text(
            label,
            style: AppText.label.copyWith(
              color: fg,
              fontSize: dense ? 11.5 : 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    return Tactile(
      onTap: onTap,
      primary: primary,
      child: expanded ? SizedBox(width: double.infinity, child: content) : content,
    );
  }
}

/// A tactile interactive card with border illumination and scale response.
class TactileCard extends StatelessWidget {
  const TactileCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = Dp.rMd,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Tactile(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Dp.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? Dp.hairline,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
