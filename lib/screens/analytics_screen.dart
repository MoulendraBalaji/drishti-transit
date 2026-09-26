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
import '../ui/gov_masthead.dart';

/// Screen D: Analytics
///
/// Simple, high-precision ops charts driven by the same simulated
/// CommandCenter data stream as the map and detection feed:
/// 1. Defect Ingestion Trend (defect counts grouped by category/hour)
/// 2. 24-Hour Congestion Profile (baseline vs live inference)
/// 3. Defect Classification breakdown with calibrated severity tags
/// 4. Corridor Road Network Health Monitor
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return ColoredBox(
      color: Dp.canvas,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            14,
            isDesktop ? 32 : 16,
            isDesktop ? 40 : 100,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(cc: cc),
                  const SizedBox(height: 16),
                  _KpiRow(cc: cc),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    'ROAD DEFECT INGESTION TREND · LIVE INCIDENTS BY SEVERITY',
                  ),
                  const SizedBox(height: 8),
                  _DefectTrendPanel(cc: cc),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    'CONGESTION PROFILE · 24H LIVE PEAK VS HISTORICAL BASELINE',
                  ),
                  const SizedBox(height: 8),
                  _TrendPanel(cc: cc),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    'DEFECT CLASSIFICATION BREAKDOWN · AI DETECTION CONFIDENCE',
                  ),
                  const SizedBox(height: 8),
                  _BreakdownPanel(cc: cc),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    'ROAD NETWORK HEALTH · 8 KEY TRANSIT CORRIDORS',
                  ),
                  const SizedBox(height: 8),
                  _CorridorPanel(cc: cc),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        children: [
          const GovTricolorBar(height: 2.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AshokaChakra(size: 24, color: Color(0xFF000080)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'पुणे नागरी वेधशाला • ',
                            style: TextStyle(
                              fontFamily: AppText.sans,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF9933),
                            ),
                          ),
                          Text(
                            'NETWORK ANALYTICS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.displayTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PUNE METROPOLITAN GRID · AIS-140 REAL-TIME OBSERVATORY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: monoTxt(9.5, color: Dp.accent, w: FontWeight.w700, ls: 0.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const GovBadge(label: 'NIC GOV-NET', sublabel: 'ACTIVE', dense: true),
              ],
            ),
          ),
        ],
      ),
    );
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
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Dp.card,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: StatBlock(
              number: cc.total.toString(),
              label: 'TOTAL DEFECTS',
              color: Dp.ink,
              trend: 'LIVE',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Dp.card,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: StatBlock(
              number: '${cc.busesOnline}',
              label: 'ACTIVE BUS SCANNERS',
              color: Dp.accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Dp.card,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: StatBlock(
              number: '${cc.coveragePercent}%',
              label: 'GRID COVERAGE',
              color: Dp.note,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Dp.card,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: StatBlock(
              number: '${cc.countOf(DetectionKind.pothole)}',
              label: 'POTHOLES TRIAGED',
              color: Dp.critical,
            ),
          ),
        ),
      ],
    );
  }
}

/// Chart 1: Defect Ingestion Trend (Bar chart showing road defects by category)
class _DefectTrendPanel extends StatelessWidget {
  const _DefectTrendPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final potholes = cc.countOf(DetectionKind.pothole);
    final fractures = cc.countOf(DetectionKind.roadFracture);
    final congestion = cc.countOf(DetectionKind.congestion);
    final pedRisk = cc.countOf(DetectionKind.pedRisk);
    final signs = cc.countOf(DetectionKind.signLoss);

    final bars = [
      (label: 'POTHOLES', count: potholes, color: Dp.critical),
      (label: 'FRACTURES', count: fractures, color: Dp.elevated),
      (label: 'CONGESTION', count: congestion, color: Dp.watch),
      (label: 'PED RISK', count: pedRisk, color: Dp.note),
      (label: 'SIGN LOSS', count: signs, color: Dp.accent),
    ];

    final maxCount = bars.map((b) => b.count).fold<int>(1, math.max).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxCount * 1.25,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: monoTxt(8, color: Dp.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= 0 && idx < bars.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              bars[idx].label,
                              style: monoTxt(8, color: Dp.textMuted, w: FontWeight.w700),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFF1E2D47),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: bars[i].count.toDouble(),
                          color: bars[i].color,
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final b in bars)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: b.color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('${b.count}', style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w700)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chart 2: 24-Hour Congestion Trend (Line chart comparing baseline vs live)
class _TrendPanel extends StatelessWidget {
  const _TrendPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final baseline = SimWorld.congestionBaseline();
    final live = cc.congestionSeries;
    final spots = [for (var i = 0; i < 24; i++) FlSpot(i.toDouble(), live[i])];
    final base = [for (var i = 0; i < 24; i++) FlSpot(i.toDouble(), baseline[i])];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
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
                maxY: 1.0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFF1E2D47),
                    strokeWidth: 1,
                  ),
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
                          style: monoTxt(8, color: Dp.textMuted),
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
                          style: monoTxt(8, color: Dp.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: base,
                    color: const Color(0xFF5B6E84),
                    barWidth: 1.6,
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
                      color: Dp.accent.withValues(alpha: 0.10),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(const Color(0xFF5B6E84), 'HISTORICAL BASELINE'),
              const SizedBox(width: 16),
              _legendDot(Dp.accent, 'LIVE DETECTED CONGESTION PEAKS'),
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
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: monoTxt(8.5, color: Dp.textMuted)),
      ],
    );
  }
}

/// Breakdown of defect classification percentages
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        children: [
          for (final (kind, count) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Dp.field,
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
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    child: Text(
                      kind.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 7,
                        color: Dp.field,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: max == 0 ? 0 : count / max),
                          duration: Mo.standard,
                          curve: Mo.easeTech,
                          builder: (context, t, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: t.clamp(0.0, 1.0),
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
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
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

/// Corridor health cards
class _CorridorPanel extends StatelessWidget {
  const _CorridorPanel({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final corridors = cc.corridors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final c in corridors)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Dp.field,
                borderRadius: BorderRadius.circular(Dp.rSm),
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
                  const SizedBox(width: 8),
                  Text(
                    '${c.id} · ${c.name}',
                    style: monoTxt(10, color: Dp.ink, w: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${c.score.toStringAsFixed(0)}% HEALTH',
                    style: monoTxt(9.5, color: _scoreColor(c.score), w: FontWeight.w700),
                  ),
                ],
              ),
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