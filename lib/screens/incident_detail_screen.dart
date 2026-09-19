import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../core/models.dart';
import '../core/street_engine.dart';
import '../ui/chrome.dart';
import '../ui/glyphs.dart';

/// Incident detail — pushed with the product's signature lift transition.
/// Evidence frame (the same renderer used by the live feed), plate + GPS +
/// confidence, and a one-tap report generator (stub).
class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final e = cc.byId(id);
    if (e == null) {
      return const Scaffold(body: Center(child: Text('Alert not found')));
    }
    return Scaffold(
      backgroundColor: Dp.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DetailHeader(
              onBack: () => context.pop(),
              id: id,
              severity: e.severity,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            sliver: SliverList.list(
              children: [
                _EvidenceFrame(event: e),
                const SizedBox(height: 12),
                if (e.plate != null) _PlatePanel(event: e),
                const SizedBox(height: 12),
                _FactsPanel(event: e),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CommandButton(
                    label: 'GENERATE REPORT',
                    icon: DGlyph.shield,
                    onTap: () => _openReport(context, e),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openReport(BuildContext context, DetectionEvent e) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x33000000),
      builder: (context) => _ReportSheet(event: e),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
    required this.id,
    required this.severity,
  });
  final VoidCallback onBack;
  final String id;
  final SeverityClass severity;

  @override
  Widget build(BuildContext context) {
    // top safe spacing borrowed from the shell's forced no-safe-area body
    final topPad = MediaQuery.paddingOf(context).top + 6;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, topPad, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Dp.raised,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Dp.line),
              ),
              child: Center(
                  child: Drishti.icon(DGlyph.chevronLeft,
                      size: 16, color: Dp.ink)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ALERT // ${id.toUpperCase()}',
                  style: AppText.dataTiny.copyWith(color: Dp.fog, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text('DETECTION RECORD',
                  style: AppText.displaySmall().copyWith(color: Dp.ink)),
            ],
          ),
          const Spacer(),
          SeverityTag(severity, size: 11),
        ],
      ),
    );
  }
}

class _EvidenceFrame extends StatelessWidget {
  const _EvidenceFrame({required this.event});
  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tok.cornerPanel),
      child: AspectRatio(
        aspectRatio: 16 / 9.4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: StreetScenePainter(
                seed: event.sceneSeed,
                time: event.sceneTime,
                detection: DetectionVisual(
                    kind: event.kind,
                    confidence: event.confidence,
                    plate: event.plate),
                boxProgress: 1,
                confProgress: 1,
                locked: true,
                confidence: event.confidence,
              ),
            ),
            // freeze stamp
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xCC0B1323),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Dp.signal.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Drishti.icon(DGlyph.clock, size: 10, color: Dp.signal),
                    const SizedBox(width: 6),
                    Text('EVIDENCE · FRAME ${event.sceneSeed % 512}',
                        style: monoTxt(8.5,
                            color: Dp.signal, w: FontWeight.w700, ls: 0.8)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatePanel extends StatelessWidget {
  const _PlatePanel({required this.event});
  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final col = Dp.severityColor(event.severity);
    return Panel(
      glow: col,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Drishti.icon(DGlyph.plate, size: 22, color: col),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXTRACTED PLATE · OCR CONF ${event.confLabel}',
                  style: AppText.dataTiny.copyWith(color: Dp.fog)),
              const SizedBox(height: 5),
              Text(event.plate!,
                  style: monoTxt(22, color: Dp.ink, w: FontWeight.w700, ls: 2.2)),
            ],
          ),
          const Spacer(),
          const _MatchingRing(),
        ],
      ),
    );
  }
}

class _MatchingRing extends StatelessWidget {
  const _MatchingRing();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Drishti.icon(DGlyph.target, size: 20, color: Dp.signal),
        const SizedBox(height: 4),
        Text('MATCH 3/6',
            style: AppText.dataTiny.copyWith(color: Dp.fog, fontSize: 8)),
      ],
    );
  }
}

class _FactsPanel extends StatelessWidget {
  const _FactsPanel({required this.event});
  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final col = Dp.severityColor(event.severity);
    final timeStr =
        '${event.timeLabel} · ${_day(event.ts)}';
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Drishti.icon(_glyphFor(event.kind), size: 16, color: col),
              const SizedBox(width: 8),
              Text(event.kind.label.toUpperCase(),
                  style: AppText.dataStrong.copyWith(color: Dp.ink)),
              const Spacer(),
              Text(event.confLabel,
                  style: monoTxt(15, color: col, w: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(event.kind.detail,
              style: AppText.bodySmall.copyWith(color: Dp.mist)),
          const SizedBox(height: 14),
          const HairDivider(color: Dp.line, thickness: double.infinity),
          const SizedBox(height: 6),
          DataRow('TIME', timeStr),
          DataRow('GPS', event.gpsLabel),
          DataRow('BUS', '${event.busId} · ${event.busRoute}'),
          DataRow('CORRIDOR', event.corridorId),
          DataRow('TRUST', event.confLabel,
              valueColor: col),
        ],
      ),
    );
  }

  static String _day(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')} ${_months[t.month - 1]} 2026';

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  DGlyph _glyphFor(DetectionKind k) => switch (k) {
        DetectionKind.pothole => DGlyph.target,
        DetectionKind.roadFracture => DGlyph.route,
        DetectionKind.signLoss => DGlyph.info,
        DetectionKind.congestion => DGlyph.stacks,
        DetectionKind.pedRisk => DGlyph.pin,
        DetectionKind.plateCapture => DGlyph.plate,
      };
}

/// Report stub — a command-style printout, transmission animation, then toast.
class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.event});
  final DetectionEvent event;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  bool _transmitting = false;
  bool _sent = false;

  String get _report {
    final e = widget.event;
    return [
      '{  "alert_id": "${e.id}",',
      '   "type": "${e.kind.label}",',
      '   "severity": "${e.severity.label}",',
      '   "confidence": ${e.confidence.toStringAsFixed(3)},',
      '   "gps": {"lat": ${e.lat.toStringAsFixed(5)}, "lng": ${e.lng.toStringAsFixed(5)}},',
      if (e.plate != null) '   "plate": "${e.plate}",',
      '   "bus": {"id": "${e.busId}", "route": "${e.busRoute}"},',
      '   "captured_at": "${e.ts.toUtc().toIso8601String()}",',
      '   "triage": "→ CITY OPS DESK #42"',
      '}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Dp.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Dp.fog.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SectionHeader('FIELD REPORT · AUTO'),
                  const Spacer(),
                  SeverityTag(widget.event.severity, size: 9),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Dp.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Dp.line),
                ),
                child: Text(_report,
                    style: monoTxt(11, color: Dp.signal, ls: 0.2)),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: CommandButton(
                  label: _sent
                      ? 'TRANSMITTED TO COMMAND LOG'
                      : _transmitting
                          ? 'ENCRYPTING …'
                          : 'CONFIRM TRANSMISSION · CMD-42',
                  icon: DGlyph.signal,
                  accent: Dp.saffron,
                  loading: _transmitting && !_sent,
                  onTap: _transmitting || _sent
                      ? () {}
                      : () {
                          setState(() => _transmitting = true);
                          HapticFeedback.selectionClick();
                          Future.delayed(const Duration(milliseconds: 900),
                              () {
                            if (!mounted) return;
                            setState(() {
                              _transmitting = false;
                              _sent = true;
                            });
                            HapticFeedback.heavyImpact();
                          });
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}