import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../ui/glyphs.dart';
import 'mobile_tokens.dart';

/// MTap — the mobile press primitive.
///
/// A slightly deeper press than the desktop [Tactile] (0.955) because thumbs
/// cover more of the target, plus a light haptic and no ripple so the
/// tactical surfaces stay clean.
class MTap extends StatefulWidget {
  const MTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.955,
    this.haptic = HapticFeedback.lightImpact,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final VoidCallback haptic;
  final bool enabled;

  @override
  State<MTap> createState() => _MTapState();
}

class _MTapState extends State<MTap> {
  bool _down = false;

  bool get _live => widget.enabled && widget.onTap != null;

  void _press() {
    if (!_live || _down) return;
    setState(() => _down = true);
    widget.haptic();
  }

  void _up() {
    if (!_down) return;
    setState(() => _down = false);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_live) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(),
      onTapUp: (_) => _up(),
      onTapCancel: () {
        if (_down) setState(() => _down = false);
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Mo.micro,
        curve: Mo.easeTech,
        child: AnimatedOpacity(
          opacity: _down ? 0.9 : 1.0,
          duration: Mo.micro,
          curve: Mo.easeTech,
          child: widget.child,
        ),
      ),
    );
  }
}

typedef HapticFeedbackCallback = void Function();

/// Visual weight of an [MButton].
enum MButtonKind { primary, tonal, ghost, outline, danger, success }

/// MButton — the field action button.
///
/// 44–52dp tall so it is always thumb-safe, 12dp/18dp corners from the existing
/// radius ladder, an icon + label pair that never wraps, and a real disabled
/// state (disabled actions grey out instead of pretending to work).
class MButton extends StatelessWidget {
  const MButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.trailing,
    this.kind = MButtonKind.primary,
    this.accent,
    this.dense = false,
    this.tall = false,
    this.expand = true,
    this.pill = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final DGlyph? icon;
  final DGlyph? trailing;
  final MButtonKind kind;
  final Color? accent;
  final bool dense;
  final bool tall;
  final bool expand;
  final bool pill;
  final bool enabled;

  double get _height {
    if (tall) return 52;
    if (dense) return 38;
    return 46;
  }

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? MSig.accent;
    final (Color bg, Color fg, Color border, Color? glow) = switch (kind) {
      MButtonKind.primary => (
          tone,
          MSig.onColor(tone),
          tone,
          Dp.isDark ? tone.withValues(alpha: 0.34) : tone.withValues(alpha: 0.30),
        ),
      MButtonKind.tonal => (
          tone.withValues(alpha: Dp.isDark ? 0.14 : 0.11),
          tone,
          tone.withValues(alpha: Dp.isDark ? 0.5 : 0.38),
          null,
        ),
      MButtonKind.ghost => (Dp.field, Dp.ink, Dp.hairline, null),
      MButtonKind.outline => (
          Colors.transparent,
          tone,
          tone.withValues(alpha: 0.55),
          null,
        ),
      MButtonKind.danger => (
          MSig.offline,
          Colors.white,
          MSig.offline,
          MSig.offline.withValues(alpha: 0.28),
        ),
      MButtonKind.success => (
          MSig.resolved,
          Colors.white,
          MSig.resolved,
          MSig.resolved.withValues(alpha: 0.28),
        ),
    };

    final radius = pill ? BorderRadius.circular(Dp.rFull) : BorderRadius.circular(dense ? Dp.rSm : Dp.rMd);

    final content = AnimatedOpacity(
      duration: Mo.fast,
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        height: _height,
        padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: border, width: 1.2),
          boxShadow: glow == null || !enabled
              ? null
              : [
                  BoxShadow(color: glow, blurRadius: 16, offset: const Offset(0, 5)),
                ],
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Drishti.icon(
                icon!,
                size: dense ? 14 : 16,
                color: fg,
                stroke: 2.0,
              ),
              SizedBox(width: dense ? 6 : 9),
            ],
            Flexible(
              child: Text(
                label,
                style: MT.button(size: dense ? 11.5 : 12.5, color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: dense ? 6 : 9),
              Drishti.icon(
                trailing!,
                size: dense ? 14 : 16,
                color: fg.withValues(alpha: 0.85),
                stroke: 2.0,
              ),
            ],
          ],
        ),
      ),
    );

    return MTap(
      onTap: enabled ? onTap : null,
      haptic: kind == MButtonKind.primary || kind == MButtonKind.danger
          ? HapticFeedback.mediumImpact
          : HapticFeedback.lightImpact,
      scale: 0.96,
      child: content,
    );
  }
}

/// MIconButton — 40dp square tappable icon target for app bars and headers.
class MIconButton extends StatelessWidget {
  const MIconButton({
    super.key,
    required this.glyph,
    this.onTap,
    this.size = 40,
    this.iconSize = 17,
    this.color,
    this.background,
    this.borderColor,
    this.radius = 12,
    this.stroke = 1.8,
    this.badge = false,
    this.badgeColor,
    this.semanticLabel,
  });

  final DGlyph glyph;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? background;
  final Color? borderColor;
  final double radius;
  final double stroke;
  final bool badge;
  final Color? badgeColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Dp.ink;
    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? Dp.field,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Dp.hairline, width: 1.0),
      ),
      child: Center(
        child: Drishti.icon(glyph, size: iconSize, color: c, stroke: stroke),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MTap(onTap: onTap, child: box),
        if (badge)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: badgeColor ?? MSig.offline,
                shape: BoxShape.circle,
                border: Border.all(color: Dp.canvas, width: 1.6),
              ),
            ),
          ),
      ],
    );
  }
}

/// MChip — selectable option chip (defect type, repair action, severity filter).
class MChip extends StatelessWidget {
  const MChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.accent,
    this.icon,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;
  final DGlyph? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? MSig.accent;
    return MTap(
      onTap: onTap,
      haptic: HapticFeedback.selectionClick,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeTech,
        padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 6 : 8),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: Dp.isDark ? 0.18 : 0.13) : Dp.field,
          borderRadius: BorderRadius.circular(dense ? Dp.rSm : Dp.rMd),
          border: Border.all(
            color: selected ? c.withValues(alpha: 0.6) : Dp.hairline,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Drishti.icon(
                icon!,
                size: dense ? 12 : 13,
                color: selected ? c : Dp.textMuted,
                stroke: 1.9,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: MT.button(
                size: dense ? 11 : 11.5,
                color: selected ? c : Dp.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// MChoice — a two/three-way segmented selector with a sliding indicator.
class MChoice<T> extends StatelessWidget {
  const MChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.accent,
  });

  final T value;
  final List<(T, String, DGlyph)> options;
  final ValueChanged<T> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? MSig.accent;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Dp.field,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, c2) {
          final w = c2.maxWidth;
          final seg = w / options.length;
          final index = options.indexWhere((o) => o.$1 == value);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Mo.standard,
                curve: Mo.easeTech,
                left: seg * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: seg,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: Dp.isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(Dp.rSm),
                    border: Border.all(color: c.withValues(alpha: 0.5), width: 1.2),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    SizedBox(
                      width: seg,
                      child: MTap(
                        onTap: () {
                          if (o.$1 == value) return;
                          HapticFeedback.selectionClick();
                          onChanged(o.$1);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Drishti.icon(
                                o.$3,
                                size: 15,
                                color: o.$1 == value ? c : Dp.textMuted,
                                stroke: o.$1 == value ? 2.0 : 1.6,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                o.$2,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: MT.tab(
                                  size: 9.5,
                                  color: o.$1 == value ? c : Dp.textMuted,
                                  w: o.$1 == value ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// MToggle — in-language switch (no Material track/thumb mismatch).
class MToggle extends StatelessWidget {
  const MToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.accent,
    this.width = 50,
    this.height = 29,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? MSig.accent;
    return MTap(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      scale: 0.92,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeTech,
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? c.withValues(alpha: Dp.isDark ? 0.9 : 0.85) : Dp.field,
          borderRadius: BorderRadius.circular(Dp.rFull),
          border: Border.all(
            color: value ? c.withValues(alpha: 0.9) : Dp.hairline,
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: Mo.fast,
          curve: Mo.easeTech,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: height - 8,
            height: height - 8,
            decoration: BoxDecoration(
              color: value ? Colors.white : Dp.textMuted,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: Dp.isDark ? 0.45 : 0.22),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// MSlider — the field-radius control.
///
/// A precision track with detents instead of a bare Material slider: the thumb
/// grows and glows while dragging, every division is drawn as a tick, and the
/// live value rides above the thumb so a gloved hand can still read it.
class MSlider extends StatefulWidget {
  const MSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.divisions,
    this.accent,
    this.format,
    this.height = 40,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final int? divisions;
  final Color? accent;
  final String Function(double)? format;
  final double height;

  @override
  State<MSlider> createState() => _MSliderState();
}

class _MSliderState extends State<MSlider> {
  bool _dragging = false;
  int _lastDetent = -1;

  static const double _thumbR = 12;

  double _quantise(double raw) {
    final v = raw.clamp(widget.min, widget.max);
    final d = widget.divisions;
    if (d == null || d <= 0) return v;
    final step = (widget.max - widget.min) / d;
    final snapped = (v - widget.min) / step;
    final idx = snapped.round().clamp(0, d);
    return widget.min + step * idx;
  }

  void _emit(double raw, {bool end = false}) {
    final v = _quantise(raw);
    final idx = ((v - widget.min) / ((widget.max - widget.min) / (widget.divisions ?? 1))).round();
    if (idx != _lastDetent) {
      _lastDetent = idx;
      HapticFeedback.selectionClick();
    }
    widget.onChanged(v);
    if (end) {
      widget.onChangeEnd?.call(v);
      _lastDetent = -1;
    }
  }

  void _fromX(double dx, double width, {bool end = false}) {
    final usable = math.max(1.0, width - _thumbR * 2);
    final t = ((dx - _thumbR) / usable).clamp(0.0, 1.0);
    _emit(widget.min + (widget.max - widget.min) * t, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.accent ?? MSig.accent;
    return LayoutBuilder(
      builder: (context, cons) {
        final t = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
        return SizedBox(
          height: widget.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              setState(() => _dragging = true);
              _fromX(d.localPosition.dx, cons.maxWidth);
            },
            onTapUp: (d) {
              _fromX(d.localPosition.dx, cons.maxWidth, end: true);
              if (mounted) setState(() => _dragging = false);
            },
            onTapCancel: () {
              if (mounted) setState(() => _dragging = false);
            },
            onHorizontalDragStart: (d) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (d) => _fromX(d.localPosition.dx, cons.maxWidth),
            onHorizontalDragEnd: (d) {
              _fromX(d.localPosition.dx, cons.maxWidth, end: true);
              if (mounted) setState(() => _dragging = false);
            },
            child: CustomPaint(
              painter: _MSliderPainter(
                value: t,
                accent: c,
                divisions: widget.divisions,
                dragging: _dragging,
                isDark: Dp.isDark,
                bubble: widget.format?.call(widget.value),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MSliderPainter extends CustomPainter {
  _MSliderPainter({
    required this.value,
    required this.accent,
    required this.divisions,
    required this.dragging,
    required this.isDark,
    required this.bubble,
  });

  final double value;
  final Color accent;
  final int? divisions;
  final bool dragging;
  final bool isDark;
  final String? bubble;

  static const double _thumbR = 12;
  static const double _trackH = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2 + (dragging ? 0 : 0);
    final usable = size.width - _thumbR * 2;
    final thumbX = _thumbR + usable * value;
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF1B2A44) : const Color(0xFFDCE3EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _trackH
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(_thumbR, cy), Offset(size.width - _thumbR, cy), trackPaint);

    // Active track
    if (value > 0) {
      final active = Paint()
        ..shader = LinearGradient(
          colors: [accent.withValues(alpha: 0.45), accent],
        ).createShader(Rect.fromLTRB(0, 0, thumbX, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = _trackH
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(_thumbR, cy), Offset(thumbX, cy), active);
    }

    // Detent ticks
    final d = divisions;
    if (d != null && d > 0) {
      for (var i = 1; i < d; i++) {
        final x = _thumbR + usable * (i / d);
        final passed = (i / d) <= value;
        final paint = Paint()
          ..color = passed
              ? accent.withValues(alpha: 0.85)
              : (isDark ? const Color(0xFF31456A) : const Color(0xFFB9C4D2));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, cy), width: 2, height: _trackH + 5),
            const Radius.circular(1),
          ),
          paint,
        );
      }
    }

    // Thumb halo while dragging
    if (dragging) {
      canvas.drawCircle(
        Offset(thumbX, cy),
        _thumbR + 7,
        Paint()
          ..color = accent.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Thumb
    canvas.drawCircle(
      Offset(thumbX, cy),
      _thumbR,
      Paint()..color = isDark ? const Color(0xFF0B1220) : Colors.white,
    );
    canvas.drawCircle(
      Offset(thumbX, cy),
      _thumbR,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = dragging ? 3 : 2.2,
    );
    canvas.drawCircle(
      Offset(thumbX, cy),
      _thumbR - 5.5,
      Paint()..color = accent.withValues(alpha: dragging ? 1.0 : 0.75),
    );

    // Live value bubble
    final label = bubble;
    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: isDark ? const Color(0xFF04121A) : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final padH = 8.0;
      final padV = 4.0;
      final bw = tp.width + padH * 2;
      final bh = tp.height + padV * 2;
      var bx = thumbX - bw / 2;
      bx = bx.clamp(0.0, math.max(0.0, size.width - bw));
      final by = cy - _thumbR - 8 - bh;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, Paint()..color = accent);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      tp.paint(canvas, Offset(bx + padH, by + padV));
    }
  }

  @override
  bool shouldRepaint(_MSliderPainter old) =>
      old.value != value ||
      old.dragging != dragging ||
      old.accent != accent ||
      old.bubble != bubble ||
      old.isDark != isDark ||
      old.divisions != divisions;
}

/// MInfoRow — label + switch row used across the mobile settings surface.
class MInfoRow extends StatelessWidget {
  const MInfoRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final DGlyph? leading;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            Drishti.icon(leading!, size: 16, color: Dp.textMuted, stroke: 1.7),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: MT.title(size: 13, color: titleColor ?? Dp.ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: MT.caption(size: 11, color: Dp.textMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return body;
    return MTap(onTap: onTap, child: body);
  }
}
