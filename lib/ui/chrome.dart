import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import 'glyphs.dart';

/// Live status pill — the small "system alive" affordance used all over.
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
    final col = widget.color ?? Dp.signal;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final pulse = 1.0 + 0.5 * (1 - t) * 0.18;
        return Container(
          padding: widget.dense
              ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: col.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pulse,
                child: CustomPaint(
                  size: const Size(7, 7),
                  painter: _PulseDotPainter(col),
                ),
              ),
              SizedBox(width: widget.dense ? 5 : 6),
              Text(
                widget.label,
                style: monoTxt(
                  widget.dense ? 8.5 : 10,
                  color: col,
                  w: FontWeight.w600,
                  ls: 1.4,
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
    canvas.drawCircle(
        c, size.width * 0.42, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulseDotPainter old) => old.color != color;
}

/// A bordered panel used across the command center.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Dp.raised,
    this.border = Dp.line,
    this.radius = Tok.cornerPanel,
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
        border: Border.all(color: glow ?? border),
        boxShadow: glow == null
            ? const []
            : [
                BoxShadow(
                  color: glow!.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: -4,
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
      color: color ?? Dp.line,
    );
  }
}

/// Section label: small mono caps with a leading tick.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.color});
  final String title;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Dp.mist;
    return Row(
      children: [
        Container(width: 8, height: 1, color: Dp.signal),
        const SizedBox(width: 8),
        Text(title, style: AppText.dataTiny.copyWith(color: c)),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// Severity tag chip for feed rows and details.
class SeverityTag extends StatelessWidget {
  const SeverityTag(this.severity, {super.key, this.size = 11});
  final SeverityClass severity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final col = Dp.severityColor(severity);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: size * 0.5, vertical: size * 0.32),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.45)),
      ),
      child: Text(
        severity.code,
        style: monoTxt(size, color: col, w: FontWeight.w700, ls: 1),
      ),
    );
  }
}

/// A thin key/value data row (mono).
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 92,
              child: Text(key_,
                  style: AppText.dataTiny.copyWith(color: Dp.fog))),
          Expanded(
            child: Text(
              value,
              style: AppText.data.copyWith(
                  color: valueColor ?? color ?? Dp.ink),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Tappable primary action with haptic + press feedback, not a Material button.
class CommandButton extends StatefulWidget {
  const CommandButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.accent = Dp.signal,
    this.loading = false,
  });
  final String label;
  final VoidCallback onTap;
  final DGlyph? icon;
  final Color accent;
  final bool loading;

  @override
  State<CommandButton> createState() => _CommandButtonState();
}

class _CommandButtonState extends State<CommandButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final col = widget.accent;
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: _down ? col : col.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Tok.cornerWell),
            border: Border.all(color: col.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Dp.signal)),
                )
              else if (widget.icon != null) ...[
                Drishti.icon(widget.icon!, size: 16, color: col),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppText.label.copyWith(color: _down ? Dp.bg : col),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small stat block (big number + dataTiny label).
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
        Text(number,
            style: AppText.displayNumber.copyWith(color: col, fontSize: 24)),
        const SizedBox(height: 3),
        Text(label,
            style: AppText.dataTiny.copyWith(color: Dp.fog, letterSpacing: 0.6)),
      ],
    );
  }
}