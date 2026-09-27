import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import 'mobile_controls.dart';
import 'mobile_tokens.dart';

/// MCard — the field-ops surface.
///
/// A crisp hairline panel on the deep-navy card token with an optional accent
/// edge for the one thing on screen that must be seen first.
class MCard extends StatelessWidget {
  const MCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderColor,
    this.radius = Dp.rMd,
    this.accentEdge,
    this.glowColor,
    this.onTap,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// Draws a 3px status edge down the leading side of the card.
  final Color? accentEdge;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Dp.hairline;
    final body = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? Dp.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          if (Dp.isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: Dp.isDark ? 0.22 : 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: accentEdge == null
            ? child
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: accentEdge,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: child),
                ],
              ),
      ),
    );

    if (onTap == null) return body;
    return MTap(onTap: onTap, child: body);
  }
}

/// MSectionLabel — accent notch + uppercase mono label, sized for a phone.
class MSectionLabel extends StatelessWidget {
  const MSectionLabel(this.title, {super.key, this.trailing, this.accent, this.size = 10});

  final String title;
  final Widget? trailing;
  final Color? accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: accent ?? MSig.accent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: MT.eyebrow(size: size, color: Dp.inkSoft, ls: 1.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// MPill — compact status / severity chip with an optional live dot.
class MPill extends StatelessWidget {
  const MPill({
    super.key,
    required this.label,
    required this.color,
    this.dot = false,
    this.icon,
    this.dense = false,
    this.solid = false,
  });

  final String label;
  final Color color;
  final bool dot;
  final DGlyph? icon;
  final bool dense;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final fg = solid ? Dp.isDark ? const Color(0xFF04121A) : Colors.white : color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 4.5,
      ),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: Dp.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(
          color: solid ? color : color.withValues(alpha: Dp.isDark ? 0.5 : 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            SizedBox(width: dense ? 4 : 5),
          ],
          if (icon != null) ...[
            Drishti.icon(icon!, size: dense ? 10 : 11, color: fg, stroke: 2.0),
            SizedBox(width: dense ? 4 : 5),
          ],
          Text(
            label,
            style: MT.eyebrow(
              size: dense ? 9 : 9.5,
              color: fg,
              ls: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// MStat — Fraunces figure + uppercase mono caption, optionally divided.
class MStat extends StatelessWidget {
  const MStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.caption,
  });

  final String value;
  final String label;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: MT.figure(size: 25, color: color)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: MT.eyebrow(size: 9, color: Dp.textMuted, ls: 1.1),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: MT.data(size: 9.5, color: Dp.textFaint, w: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// MEmptyState — sovereign emblem + title + guidance, never a bare string.
class MEmptyState extends StatelessWidget {
  const MEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.color,
    this.icon,
    this.compact = false,
  });

  final String title;
  final String message;
  final Color? color;
  final DGlyph? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = color ?? MSig.online;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: compact ? 20 : 28),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 40 : 52,
            height: compact ? 40 : 52,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: c.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Center(
              child: icon != null
                  ? Drishti.icon(icon!, size: compact ? 18 : 22, color: c, stroke: 1.8)
                  : AshokaChakra(size: compact ? 18 : 24, color: c),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: MT.eyebrow(size: 10.5, color: c, ls: 1.4),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: MT.body(size: 11.5, color: Dp.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// MKeyValue — label above value, the honest mobile alternative to a 2-column
/// data row that would crush on a 360dp canvas.
class MKeyValue extends StatelessWidget {
  const MKeyValue({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.dense = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final DGlyph? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Drishti.icon(icon!, size: 11, color: Dp.textFaint, stroke: 1.6),
              const SizedBox(width: 5),
            ],
            Text(label, style: MT.eyebrow(size: 9, color: Dp.textFaint, ls: 1.2)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: MT.data(size: dense ? 10.5 : 11, color: valueColor ?? Dp.ink, w: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// MDivider — hairline rule used inside mobile cards.
class MDivider extends StatelessWidget {
  const MDivider({super.key, this.vertical = 0, this.color});

  final double vertical;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        height: vertical > 0 ? null : 1,
        width: vertical > 0 ? 1 : null,
        color: color ?? Dp.hairlineSoft,
      );
}

/// MReveal — the opening-choreography primitive.
///
/// One controller, many staggered reveals: a short fade + translate (+ optional
/// scale) driven by a per-region [Interval] of the shell's entrance timeline.
class MReveal extends StatelessWidget {
  const MReveal({
    super.key,
    required this.animation,
    required this.child,
    this.offset = const Offset(0, 0.10),
    this.scaleFrom = 1.0,
  });

  final Animation<double> animation;
  final Widget child;
  final Offset offset;
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, kid) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - t), offset.dy * (1 - t)),
            child: scaleFrom == 1.0
                ? kid
                : Transform.scale(scale: scaleFrom + (1 - scaleFrom) * t, child: kid),
          ),
        );
      },
    );
  }
}

/// showFieldToast — in-language confirmation toast (floating, hairline, accented).
void showFieldToast(
  BuildContext context,
  String message, {
  Color? accent,
  DGlyph? icon,
  Duration duration = const Duration(milliseconds: 2800),
}) {
  final c = accent ?? MSig.accent;
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: EdgeInsets.fromLTRB(MSp.gutter, 0, MSp.gutter, bottomInset + 96),
        content: Container(
          decoration: BoxDecoration(
            color: Dp.isDark ? const Color(0xFF101A2B) : Colors.white,
            borderRadius: BorderRadius.circular(Dp.rSm),
            border: Border.all(color: c.withValues(alpha: 0.45), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: Dp.isDark ? 0.5 : 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 11),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 11, 14, 11),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Drishti.icon(icon, size: 14, color: c, stroke: 1.9),
                        const SizedBox(width: 9),
                      ],
                      Expanded(
                        child: Text(
                          message,
                          style: MT.caption(size: 12, color: Dp.ink).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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

/// showFieldSheet — one bottom-sheet entry point so every mobile sheet shares the
/// same scrim, spring, and corner treatment.
Future<T?> showFieldSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: Dp.isDark ? 0.66 : 0.45),
    elevation: 0,
    builder: builder,
  );
}

/// MSheetFrame — drag handle + title + scrollable body for mobile sheets.
class MSheetFrame extends StatelessWidget {
  const MSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.accent,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Color? accent;
  final DGlyph? icon;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? MSig.accent;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: Dp.isDark ? const Color(0xFF0A1120) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dp.rLg)),
        border: Border(
          top: BorderSide(
            color: Dp.isDark ? const Color(0xFF22334F) : const Color(0xFFCBD5E1),
            width: 1.4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Dp.isDark ? 0.6 : 0.22),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Dp.isDark ? const Color(0xFF2C3E5E) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(Dp.rFull),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MSp.gutter, 14, MSp.gutter, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Drishti.icon(icon!, size: 17, color: c, stroke: 1.8),
                    ),
                  ),
                  const SizedBox(width: 11),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: MT.title(size: 15, color: Dp.ink),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!, style: MT.body(size: 11.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                MSp.gutter,
                12,
                MSp.gutter,
                MediaQuery.viewInsetsOf(context).bottom + 22,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// MStepBadge — numbered workflow step marker used by Verify & Fix.
class MStepBadge extends StatelessWidget {
  const MStepBadge({super.key, required this.index, required this.color, this.done = false});

  final int index;
  final Color color;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Center(
        child: done
            ? Drishti.icon(DGlyph.check, size: 13, color: color, stroke: 2.2)
            : Text(
                '$index',
                style: MT.eyebrow(size: 11, color: color, ls: 0),
              ),
      ),
    );
  }
}

/// A soft status ring used behind a glyph inside cards and headers.
class MRing extends StatelessWidget {
  const MRing({
    super.key,
    required this.color,
    required this.glyph,
    this.size = 36,
    this.iconSize = 17,
    this.stroke = 1.8,
    this.solid = false,
  });

  final Color color;
  final DGlyph glyph;
  final double size;
  final double iconSize;
  final double stroke;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(
          color: solid ? color : color.withValues(alpha: 0.42),
          width: 1.1,
        ),
      ),
      child: Center(
        child: Drishti.icon(
          glyph,
          size: iconSize,
          color: solid ? (Dp.isDark ? const Color(0xFF04121A) : Colors.white) : color,
          stroke: stroke,
        ),
      ),
    );
  }
}

/// Shared entrance curve for staggered mobile reveals.
Curve mRevealCurve() => Mo.easeOutTech;
