import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../core/models.dart';
import '../core/sim.dart';
import '../ui/chrome.dart';
import '../ui/glyphs.dart';

/// Network Insight — Mobbin gallery-white design language.
/// Road-condition corridor grid, 24h congestion trend line,
/// defect breakdown progress bars, and origin–destination flow telemetry.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    return ColoredBox(
      color: Dp.canvas,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _Header(cc: cc),
            const SizedBox(height: 16),
            _KpiRow(cc: cc),
            const SizedBox(height: 18),
            const SectionHeader('ROAD NETWORK HEALTH · CORRIDOR MONITOR'),
            const SizedBox(height: 8),
            _CorridorPanel(cc: cc),
            const SizedBox(height: 18),
            const SectionHeader('CONGESTION PROFILE · 24H LIVE VS BASELINE'),
            const SizedBox(height: 8),
            _TrendPanel(cc: cc),
            const SizedBox(height: 18),
            const SectionHeader('EDGE DETECTION CLASSIFICATION BREAKDOWN'),
            const SizedBox(height: 8),
            _BreakdownPanel(cc: cc),
            const SizedBox(height: 18),
            const SectionHeader('ORIGIN → DESTINATION · FLOW NETWORK'),
            const SizedBox(height: 8),
            _OdPanel(cc: cc),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NETWORK INSIGHT',
                style: AppText.displayTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PUNE METROPOLITAN GRID · ${_date()}',
                style: AppText.dataTiny.copyWith(
                  color: Dp.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          const LivePill(dense: true, label: 'SYSTEM LIVE'),
        ],
      ),
    );
  }

  static String _date() {
    final t = DateTime.now();
    const mn = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${t.day.toString().padLeft(2, '0')} ${mn[t.month - 1]} ${t.year}';
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(14),
            child: StatBlock(
              number: cc.total.toString(),
              label: 'DETECTIONS',
              color: Dp.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(14),
            child: StatBlock(
              number: '${cc.busesOnline}',
              label: 'ACTIVE NODES',
              color: Dp.accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(14),
            child: StatBlock(
              number: '${cc.coveragePercent}%',
              label: 'CITY COVERAGE',
              color: Dp.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _CorridorPanel extends StatelessWidget {
  const _CorridorPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final corridors = cc.corridors;
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Dp.canvasSoft,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dp.rSm - 1),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: CustomPaint(
                  painter: _CorridorSkyPainter(corridors),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in corridors)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Dp.canvasSoft,
                    borderRadius: BorderRadius.circular(Dp.rFull),
                    border: Border.all(color: Dp.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _scoreColor(c.score),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${c.id} · ${c.name} (${c.score.toStringAsFixed(0)}%)',
                        style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(double s) {
    if (s >= 82) return Dp.accent;
    if (s >= 68) return Dp.watch;
    if (s >= 55) return Dp.elevated;
    return Dp.critical;
  }
}

class _CorridorSkyPainter extends CustomPainter {
  _CorridorSkyPainter(this.corridors);
  final List<Corridor> corridors;

  @override
  void paint(Canvas canvas, Size size) {
    double mnLat = 90, mxLat = -90, mnLng = 180, mxLng = -180;
    for (final c in corridors) {
      for (final (lat, lng) in c.geo) {
        if (lat < mnLat) mnLat = lat;
        if (lat > mxLat) mxLat = lat;
        if (lng < mnLng) mnLng = lng;
        if (lng > mxLng) mxLng = lng;
      }
    }
    const margin = 26.0;
    double X(double lng) =>
        margin + (lng - mnLng) / (mxLng - mnLng) * (size.width - margin * 2);
    double Y(double lat) =>
        margin + (mxLat - lat) / (mxLat - mnLat) * (size.height - margin * 2);

    final grid = Paint()
      ..color = Dp.hairline
      ..strokeWidth = 1.0;
    for (var i = 0; i <= 4; i++) {
      final fx = size.width * i / 4;
      canvas.drawLine(Offset(fx, 0), Offset(fx, size.height), grid);
      final fy = size.height * i / 4;
      canvas.drawLine(Offset(0, fy), Offset(size.width, fy), grid);
    }

    for (final c in corridors) {
      final col = _CorridorPanel._scoreColor(c.score);
      final pts = [for (final g in c.geo) Offset(X(g.$2), Y(g.$1))];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      for (final p in pts) {
        canvas.drawCircle(p, 3, Paint()..color = Colors.white);
        canvas.drawCircle(p, 2, Paint()..color = col);
      }
      final end = pts.last;
      final tp = TextPainter(
        text: TextSpan(
            text: c.id,
            style: monoTxt(8.5, color: Dp.ink, w: FontWeight.w700, ls: 0.5)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, end + const Offset(6, -4));
    }
  }

  @override
  bool shouldRepaint(_CorridorSkyPainter old) => old.corridors != corridors;
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final baseline = SimWorld.congestionBaseline();
    final live = cc.congestionSeries;
    final spots = [for (var i = 0; i < 24; i++) (FlSpot(i.toDouble(), live[i]))];
    final base = [for (var i = 0; i < 24; i++) (FlSpot(i.toDouble(), baseline[i]))];

    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Dp.hairline, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 0.5,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '${(v * 100).toStringAsFixed(0)}%',
                          style: AppText.dataTiny.copyWith(color: Dp.textMuted, fontSize: 8),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${v.toInt()}:00',
                          style: AppText.dataTiny.copyWith(color: Dp.textMuted, fontSize: 8),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: base,
                    color: Dp.textFaint,
                    barWidth: 1.5,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spots,
                    color: Dp.accent,
                    barWidth: 2.8,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Dp.accent.withValues(alpha: 0.08),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(Dp.textFaint, 'HISTORICAL BASELINE'),
              const SizedBox(width: 16),
              _legendDot(Dp.accent, 'LIVE INFERENCE PROFILE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(1.5))),
        const SizedBox(width: 6),
        Text(label, style: AppText.dataTiny.copyWith(color: Dp.textMuted, fontSize: 8.5)),
      ],
    );
  }
}

class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final rows = DetectionKind.values
        .map((k) => (k, cc.countOf(k)))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    if (rows.isEmpty) return const SizedBox.shrink();
    final max = rows.first.$2;

    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final (kind, count) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Dp.canvasSoft,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Dp.hairline),
                    ),
                    alignment: Alignment.center,
                    child: Drishti.icon(
                      _glyphFor(kind),
                      size: 14,
                      color: Dp.severityColor(kind.baseSeverity),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Text(
                      kind.label.toUpperCase(),
                      style: AppText.dataTiny.copyWith(
                        color: Dp.ink,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 7,
                        color: Dp.field,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: max == 0 ? 0 : count / max),
                          duration: Mo.standard,
                          curve: Mo.easeOutTech,
                          builder: (context, t, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: t.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Dp.severityColor(kind.baseSeverity),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: monoTxt(12, color: Dp.ink, w: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  DGlyph _glyphFor(DetectionKind k) => switch (k) {
        DetectionKind.pothole => DGlyph.target,
        DetectionKind.roadFracture => DGlyph.route,
        DetectionKind.signLoss => DGlyph.info,
        DetectionKind.congestion => DGlyph.stacks,
        DetectionKind.pedRisk => DGlyph.pin,
        DetectionKind.plateCapture => DGlyph.plate,
      };
}

class _OdPanel extends StatelessWidget {
  const _OdPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final zones = SimWorld.zones();
    final pairs = cc.odCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = pairs.take(6).toList();

    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Dp.canvasSoft,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dp.rSm - 1),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: CustomPaint(
                  painter: _OdSkyPainter(zones, top),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final z in zones)
                Text(
                  '${z.id + 1} · ${z.name}',
                  style: AppText.dataTiny.copyWith(color: Dp.textMuted, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OdSkyPainter extends CustomPainter {
  _OdSkyPainter(this.zones, this.top);
  final List<Zone> zones;
  final List<MapEntry<(int, int), int>> top;

  @override
  void paint(Canvas canvas, Size size) {
    Offset P(Zone z) => Offset(z.x * size.width, z.y * size.height);

    for (final entry in top) {
      final from = zones[entry.key.$1];
      final to = zones[entry.key.$2];
      final a = P(from);
      final b = P(to);
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final ctrl = a + Offset(dx / 2 - dy * 0.28, dy / 2 + dx * 0.28);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      final count = entry.value;
      final intensity = (count / 40).clamp(0.25, 1.0);
      canvas.drawPath(
        path,
        Paint()
          ..color = Dp.accent.withValues(alpha: intensity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 + intensity * 2.2
          ..strokeCap = StrokeCap.round,
      );
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: monoTxt(8.5, color: Dp.accent, w: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mid.translate(-tp.width / 2, -tp.height - 1));
    }

    for (final z in zones) {
      final p = P(z);
      final n = math.max(z.id == 2 ? 5.0 : 4.0, 3.5);
      canvas.drawCircle(p, n + 2, Paint()..color = Colors.white);
      canvas.drawCircle(p, n, Paint()..color = Dp.primary);
      final tp = TextPainter(
        text: TextSpan(
          text: '${z.id + 1}',
          style: monoTxt(7.5, color: Colors.white, w: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_OdSkyPainter old) => true;
}