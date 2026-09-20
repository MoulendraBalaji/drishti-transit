import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../core/models.dart';
import '../core/street_engine.dart';
import '../ui/chrome.dart';
import '../ui/glyphs.dart';

/// Incident detail screen — Mobbin gallery-white design language.
/// Evidence frame snapshot, plate extraction OCR, structured data specifications,
/// and instant command report transmission.
class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final e = cc.byId(id);
    if (e == null) {
      return const Scaffold(
        backgroundColor: Dp.canvas,
        body: Center(child: Text('Incident record not found')),
      );
    }
    return Scaffold(
      backgroundColor: Dp.canvas,
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.list(
              children: [
                _EvidenceFrame(event: e),
                const SizedBox(height: 14),
                if (e.plate != null) _PlatePanel(event: e),
                if (e.plate != null) const SizedBox(height: 14),
                _FactsPanel(event: e),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: CommandButton(
                    label: 'GENERATE INCIDENT REPORT',
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
    final topPad = MediaQuery.paddingOf(context).top + 8;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Dp.canvasSoft,
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(color: Dp.hairline),
              ),
              child: Center(
                child: Drishti.icon(DGlyph.chevronLeft, size: 16, color: Dp.ink),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INCIDENT // ${id.toUpperCase()}',
                style: AppText.dataTiny.copyWith(
                  color: Dp.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DETECTION RECORD',
                style: AppText.displaySmall(size: 15).copyWith(
                  color: Dp.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dp.rMd - 1),
        child: AspectRatio(
          aspectRatio: 16 / 9.6,
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
                    plate: event.plate,
                  ),
                  boxProgress: 1,
                  confProgress: 1,
                  locked: true,
                  confidence: event.confidence,
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Dp.canvas.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(Dp.rFull),
                    border: Border.all(color: Dp.hairline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Dp.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'EVIDENCE FRAME ${event.sceneSeed % 512}',
                        style: monoTxt(9, color: Dp.ink, w: FontWeight.w700, ls: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Dp.canvasSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Dp.hairline),
            ),
            child: Drishti.icon(DGlyph.plate, size: 24, color: Dp.accent),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LICENSE PLATE OCR · CONF ${event.confLabel}',
                style: AppText.dataTiny.copyWith(color: Dp.textMuted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                event.plate!,
                style: monoTxt(22, color: Dp.ink, w: FontWeight.w800, ls: 1.8),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Drishti.icon(DGlyph.target, size: 20, color: col),
              const SizedBox(height: 4),
              Text(
                'OCR MATCH',
                style: AppText.dataTiny.copyWith(color: col, fontWeight: FontWeight.w700, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactsPanel extends StatelessWidget {
  const _FactsPanel({required this.event});
  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final col = Dp.severityColor(event.severity);
    final timeStr = '${event.timeLabel} · ${_day(event.ts)}';
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Dp.canvasSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Dp.hairline),
                ),
                alignment: Alignment.center,
                child: Drishti.icon(_glyphFor(event.kind), size: 16, color: col),
              ),
              const SizedBox(width: 10),
              Text(
                event.kind.label.toUpperCase(),
                style: AppText.dataStrong.copyWith(
                  color: Dp.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Dp.canvasSoft,
                  borderRadius: BorderRadius.circular(Dp.rFull),
                  border: Border.all(color: Dp.hairline),
                ),
                child: Text(
                  event.confLabel,
                  style: monoTxt(12, color: Dp.ink, w: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.kind.detail,
            style: AppText.body.copyWith(color: Dp.textMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          const HairDivider(color: Dp.hairline, thickness: double.infinity),
          const SizedBox(height: 10),
          DataRow('TIMESTAMP', timeStr),
          DataRow('COORDINATES', event.gpsLabel),
          DataRow('DETECTOR BUS', '${event.busId} (${event.busRoute})'),
          DataRow('CORRIDOR', event.corridorId),
          if (event.trackId != null) DataRow('TRACK ID', event.trackId!),
          if (event.speedKmh != null) DataRow('VELOCITY', '${event.speedKmh!.toStringAsFixed(1)} KM/H'),
          if (event.distanceM != null) DataRow('DISTANCE', '${event.distanceM!.toStringAsFixed(1)} METERS'),
          DataRow('MODEL CONF', event.confLabel, valueColor: Dp.accent),
        ],
      ),
    );
  }

  static String _day(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')} ${_months[t.month - 1]} ${t.year}';

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
      '{',
      '  "incident_id": "${e.id}",',
      '  "category": "${e.kind.label}",',
      '  "severity": "${e.severity.label}",',
      '  "confidence_score": ${e.confidence.toStringAsFixed(3)},',
      '  "coordinates": {"lat": ${e.lat.toStringAsFixed(5)}, "lng": ${e.lng.toStringAsFixed(5)}},',
      if (e.plate != null) '  "plate_number": "${e.plate}",',
      if (e.trackId != null) '  "tracking_id": "${e.trackId}",',
      if (e.speedKmh != null) '  "speed_kmh": ${e.speedKmh!.toStringAsFixed(1)},',
      '  "source_node": {"bus_id": "${e.busId}", "corridor": "${e.corridorId}"},',
      '  "timestamp": "${e.ts.toUtc().toIso8601String()}",',
      '  "routing": "DISPATCH_DEPT_PUNE_MUNICIPAL"',
      '}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Dp.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dp.rMd)),
        border: Border(top: BorderSide(color: Dp.hairline)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Dp.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const SectionHeader('TELEMETRY DISPATCH RECORD'),
                  const Spacer(),
                  SeverityTag(widget.event.severity, size: 9.5),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Dp.canvasSoft,
                  borderRadius: BorderRadius.circular(Dp.rSm),
                  border: Border.all(color: Dp.hairline),
                ),
                child: Text(
                  _report,
                  style: monoTxt(11, color: Dp.ink, ls: 0.3),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CommandButton(
                  label: _sent
                      ? 'TRANSMITTED TO MUNICIPAL CONTROL'
                      : _transmitting
                          ? 'ENCRYPTING DISPATCH …'
                          : 'DISPATCH TELEMETRY TO CITY OPS',
                  icon: DGlyph.signal,
                  loading: _transmitting && !_sent,
                  onTap: _transmitting || _sent
                      ? () {}
                      : () {
                          setState(() => _transmitting = true);
                          HapticFeedback.selectionClick();
                          Future.delayed(const Duration(milliseconds: 750), () {
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