import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import 'glyphs.dart';

/// Live status pill — the small "system alive" affordance with electric blue accent.
class LivePill extends StatefulWidget {
  const LivePill({super.key, this.label = 'LIVE', this.dense = false, this.color});
  final String label;
  final bool dense;
  final Color? color;

  @override
  State<LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Mo.livePulse)
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? Dp.accent;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final pulse = 1.0 + 0.4 * (1 - t) * 0.18;
        return Container(
          padding: widget.dense
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5)
              : const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(Dp.rFull),
            border: Border.all(color: col.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pulse,
                child: CustomPaint(
                  size: const Size(6.5, 6.5),
                  painter: _PulseDotPainter(col),
                ),
              ),
              SizedBox(width: widget.dense ? 5 : 6),
              Text(
                widget.label,
                style: monoTxt(
                  widget.dense ? 9 : 10.5,
                  color: col,
                  w: FontWeight.w700,
                  ls: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseDotPainter extends CustomPainter {
  _PulseDotPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, size.width * 0.45, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulseDotPainter old) => old.color != color;
}

/// A Mobbin-styled card/panel: crisp 1px hairline border (#E0E0E0), 24px or 16px geometry.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Dp.canvas,
    this.border = Dp.hairline,
    this.radius = Dp.rMd,
    this.glow,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color border;
  final double radius;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glow ?? border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A hairline horizontal divider.
class HairDivider extends StatelessWidget {
  const HairDivider({super.key, this.color, this.thickness = 45});
  final Color? color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: thickness,
      color: color ?? Dp.hairline,
    );
  }
}

/// Section label: small uppercase typography with Mobbin style.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.color});
  final String title;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Dp.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: Dp.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppText.dataTiny.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Severity tag chip for feed rows and details — clean stadium pill.
class SeverityTag extends StatelessWidget {
  const SeverityTag(this.severity, {super.key, this.size = 11});
  final SeverityClass severity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final col = Dp.severityColor(severity);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: size * 0.7, vertical: size * 0.35),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(color: col.withValues(alpha: 0.35)),
      ),
      child: Text(
        severity.code,
        style: monoTxt(size, color: col, w: FontWeight.w700, ls: 0.8),
      ),
    );
  }
}

/// A thin key/value data row with Mobbin typography.
class DataRow extends StatelessWidget {
  const DataRow(this.key_, this.value,
      {super.key, this.color, this.valueColor, this.trailing});
  final String key_;
  final String value;
  final Color? color;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              key_,
              style: AppText.dataTiny.copyWith(color: Dp.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.data.copyWith(
                color: valueColor ?? color ?? Dp.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Mobbin Primary Stadium Button (Solid black #141414, white text, pill geometry)
class CommandButton extends StatefulWidget {
  const CommandButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.accent,
    this.outline = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final DGlyph? icon;
  final Color? accent;
  final bool outline;
  final bool loading;

  @override
  State<CommandButton> createState() => _CommandButtonState();
}

class _CommandButtonState extends State<CommandButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bgCol = widget.outline
        ? Dp.canvas
        : (widget.accent ?? Dp.primary);
    final textCol = widget.outline
        ? Dp.ink
        : (widget.accent != null ? Colors.white : Dp.onPrimary);
    final borderCol = widget.outline ? Dp.hairline : Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: Mo.micro,
        curve: Mo.easeOutTech,
        child: AnimatedContainer(
          duration: Mo.fast,
          curve: Mo.easeOutTech,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _down ? bgCol.withValues(alpha: 0.85) : bgCol,
            borderRadius: BorderRadius.circular(Dp.rFull),
            border: Border.all(color: borderCol, width: 1.0),
            boxShadow: widget.outline
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textCol),
                  ),
                )
              else if (widget.icon != null) ...[
                Drishti.icon(widget.icon!, size: 16, color: textCol),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppText.label.copyWith(
                  color: textCol,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat block with Mobbin typography (crisp black display number + muted label).
class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.number, required this.label, this.color});
  final String number;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final col = color ?? Dp.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: AppText.displayNumber.copyWith(
            color: col,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppText.dataTiny.copyWith(
            color: Dp.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}