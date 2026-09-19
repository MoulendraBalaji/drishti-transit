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

/// Network Insight — road-condition corridor map, congestion trend, defect
/// breakdown and origin–destination sketch, all driven by the live stream.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    return ColoredBox(
      color: Dp.bg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          children: [
            _Header(cc: cc),
            const SizedBox(height: 14),
            _KpiRow(cc: cc),
            const SizedBox(height: 16),
            const SectionHeader('ROAD CONDITION · CORRIDOR GRID'),
            const SizedBox(height: 8),
            _CorridorPanel(cc: cc),
            const SizedBox(height: 16),
            const SectionHeader('CONGESTION TREND · 24H'),
            const SizedBox(height: 8),
            _TrendPanel(cc: cc),
            const SizedBox(height: 16),
            const SectionHeader('DEFECT BREAKDOWN'),
            const SizedBox(height: 8),
            _BreakdownPanel(cc: cc),
            const SizedBox(height: 16),
            const SectionHeader('ORIGIN → DESTINATION · PEAK FLOW'),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NETWORK INSIGHT',
                style: AppText.displayTitle.copyWith(fontSize: 24)),
            Text('PUNE METRO · ${_date()}',
                style: AppText.dataTiny.copyWith(color: Dp.saffron, letterSpacing: 1.2)),
          ],
        ),
        const Spacer(),
        const LivePill(label: 'LIVE'),
      ],
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
            padding: const EdgeInsets.all(12),
            child: StatBlock(
              number: cc.total.toString(),
              label: 'INCIDENTS · TODAY',
              color: Dp.signal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(12),
            child: StatBlock(
              number: '${cc.busesOnline}',
              label: 'SENSOR BUSES',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(12),
            child: StatBlock(
              number: '${cc.coveragePercent}%',
              label: 'GRID COVERED',
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _CorridorPanel extends StatelessWidget {
  const _CorridorPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final corridors = cc.corridors;
    return Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.45,
            child: CustomPaint(
              painter: _CorridorSkyPainter(corridors),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              for (final c in corridors)
                Row(
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
                    const SizedBox(width: 5),
                    Text('${c.id} ${c.name} ${c.score.toStringAsFixed(0)}',
                        style: AppText.dataTiny.copyWith(color: Dp.mist)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          const HairDivider(color: Dp.line, thickness: 90),
        ],
      ),
    );
  }

  static Color _scoreColor(double s) {
    if (s >= 82) return Dp.signal;
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
    // fit corridor grid into the canvas
    double mnLat = 90, mxLat = -90, mnLng = 180, mxLng = -180;
    for (final c in corridors) {
      for (final (lat, lng) in c.geo) {
        if (lat < mnLat) mnLat = lat;
        if (lat > mxLat) mxLat = lat;
        if (lng < mnLng) mnLng = lng;
        if (lng > mxLng) mxLng = lng;
      }
    }
    const margin = 24.0;
    double X(double lng) =>
        margin + (lng - mnLng) / (mxLng - mnLng) * (size.width - margin * 2);
    double Y(double lat) =>
        margin + (mxLat - lat) / (mxLat - mnLat) * (size.height - margin * 2);

    // faint survey grid
    final grid = Paint()
      ..color = Dp.line.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
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
          ..color = col.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      // nodes + endpoint tag
      for (final p in pts) {
        canvas.drawCircle(p, 2.2, Paint()..color = col);
      }
      final end = pts.last;
      final tp = TextPainter(
        text: TextSpan(
            text: c.id,
            style: monoTxt(8, color: col, w: FontWeight.w700, ls: 0.6)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, end + const Offset(6, -4));
    }

    // center crosshair
    final cx = Paint()
      ..color = Dp.lineBright.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, margin),
        Offset(size.width / 2, size.height - margin), cx);
    canvas.drawLine(Offset(margin, size.height / 2),
        Offset(size.width - margin, size.height / 2), cx);
  }

  @override
  bool shouldRepaint(_CorridorSkyPainter old) => old.corridors != corridors;
}

// ---------------------------------------------------------------------------

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
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 14, right: 14),
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
                      FlLine(color: Dp.line, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 0.5,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          (v * 100).toStringAsFixed(0),
                          style: AppText.dataTiny.copyWith(
                              color: Dp.dim, fontSize: 7.5),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      reservedSize: 18,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${v.toInt()}',
                          style: AppText.dataTiny.copyWith(
                              color: Dp.dim, fontSize: 8),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: base,
                    color: Dp.fog.withValues(alpha: 0.5),
                    barWidth: 1.4,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spots,
                    color: Dp.signal,
                    barWidth: 2.4,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Dp.signal.withValues(alpha: 0.10),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _legendDot(Dp.fog.withValues(alpha: 0.6), 'BASELINE'),
              const SizedBox(width: 12),
              _legendDot(Dp.signal, 'TODAY · LIVE'),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 2,
          color: c,
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppText.dataTiny.copyWith(color: Dp.mist, fontSize: 8)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final (kind, count) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Drishti.icon(_glyphFor(kind),
                        size: 15,
                        color: Dp.severityColor(kind.baseSeverity)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Text(kind.label.toUpperCase(),
                        style: AppText.dataTiny.copyWith(
                            color: Dp.mist, letterSpacing: 0.6)),
                  ),
                  Expanded(
                    flex: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        height: 7,
                        color: Dp.raised2,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0, end: max == 0 ? 0 : count / max),
                          duration: Mo.standard,
                          curve: Mo.easeOutTech,
                          builder: (context, t, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: t.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Dp.severityColor(kind.baseSeverity),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 26,
                    child: Text('$count',
                        textAlign: TextAlign.right,
                        style: monoTxt(11,
                            color: Dp.ink, w: FontWeight.w700, ls: 0)),
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

// ---------------------------------------------------------------------------

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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: CustomPaint(
              painter: _OdSkyPainter(zones, top),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final z in zones)
                Text('${z.id + 1}·${z.name}',
                    style: AppText.dataTiny.copyWith(color: Dp.mist)),
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

    // arcs (drawn beneath nodes)
    for (final entry in top) {
      final from = zones[entry.key.$1];
      final to = zones[entry.key.$2];
      final a = P(from);
      final b = P(to);
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final ctrl = a +
          Offset(dx / 2 - dy * 0.28, dy / 2 + dx * 0.28);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      final count = entry.value;
      final intensity = (count / 40).clamp(0.2, 1.0);
      canvas.drawPath(
        path,
        Paint()
          ..color = Dp.signal.withValues(alpha: intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + intensity * 2.4
          ..strokeCap = StrokeCap.round,
      );
      // count label at arc midpoint
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final tp = TextPainter(
        text: TextSpan(
            text: '$count',
            style: monoTxt(8.5,
                color: Dp.signal.withValues(alpha: intensity),
                w: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mid.translate(-tp.width / 2, -tp.height - 1));
    }

    // nodes
    for (final z in zones) {
      final p = P(z);
      final n = math.max(z.id == 2 ? 4.5 : 3.5, 3.0);
      canvas.drawCircle(
          p, n + 2, Paint()..color = Dp.surface);
      canvas.drawCircle(
          p, n, Paint()..color = z.id == 1 ? Dp.saffron : Dp.signal);
      final tp = TextPainter(
        text: TextSpan(
            text: '${z.id + 1}',
            style: monoTxt(8,
                color: Dp.onSignal, w: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_OdSkyPainter old) => true;
}