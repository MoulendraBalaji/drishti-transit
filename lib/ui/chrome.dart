import 'package:flutter/material.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import 'glyphs.dart';
import 'tactile.dart';

/// Live status pill — the small "system alive" affordance with continuous subtle pulse.
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
    vsync: this,
    duration: Mo.livePulse,
  )..repeat();

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
        final pulse = 1.0 + 0.3 * (1.0 - (t - 0.5).abs() * 2);
        return Container(
          padding: widget.dense
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5)
              : const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Dp.rFull),
            border: Border.all(color: col.withValues(alpha: 0.45), width: 1.0),
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
              SizedBox(width: widget.dense ? 5 : 7),
              Text(
                widget.label,
                style: monoTxt(
                  widget.dense ? 9.5 : 10.5,
                  color: col,
                  w: FontWeight.w700,
                  ls: 1.1,
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

/// A command-center card/panel: crisp 1px hairline border, deep navy background.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
    this.radius = Dp.rMd,
    this.glow,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? border;
  final double radius;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Dp.card;
    final b = border ?? Dp.hairline;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glow ?? b, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A hairline divider.
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

/// Section header with active accent notch.
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
            width: 3.5,
            height: 12,
            decoration: BoxDecoration(
              color: Dp.accent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppText.dataTiny.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
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
        horizontal: size * 0.75,
        vertical: size * 0.35,
      ),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(color: col.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Text(
        severity.code,
        style: monoTxt(size, color: col, w: FontWeight.w700, ls: 0.8),
      ),
    );
  }
}

/// Compatibility alias for key-value data rows
typedef DataRow = DataRowItem;

/// A thin key/value data row for ops logs.
class DataRowItem extends StatelessWidget {
  const DataRowItem(
    this.key_,
    this.value, {
    super.key,
    this.color,
    this.valueColor,
    this.trailing,
  });

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
            width: 110,
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

/// Command-center primary/secondary button built on Tactile.
class CommandButton extends StatelessWidget {
  const CommandButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.accent,
    this.outline = false,
    this.loading = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback onTap;
  final DGlyph? icon;
  final Color? accent;
  final bool outline;
  final bool loading;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      label: label,
      onTap: onTap,
      icon: icon,
      accent: accent,
      outline: outline,
      dense: dense,
      primary: !outline,
    );
  }
}

/// Stat block with Fraunces number and monospace label.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.number,
    required this.label,
    this.color,
    this.trend,
  });

  final String number;
  final String label;
  final Color? color;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    final col = color ?? Dp.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                number,
                style: AppText.displayNumber.copyWith(
                  color: col,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trend != null) ...[
              const SizedBox(width: 5),
              Text(
                trend!,
                style: AppText.dataTiny.copyWith(
                  color: Dp.accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.dataTiny.copyWith(
            color: Dp.textMuted,
            fontSize: 9.5,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}