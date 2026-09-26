import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../ui/chrome.dart';
import '../ui/glyphs.dart';
import '../ui/tactile.dart';

/// Screen A: Home / Mission
///
/// Brief, confident introduction to Drishti-Transit:
/// Explaining the software-only premise (leveraging mandated AIS-140 bus cameras),
/// highlighting the 4-stage edge-to-command pipeline, displaying live fleet telemetry,
/// and providing direct tactile paths to the Detection Feed and Command Map.
class MissionScreen extends StatelessWidget {
  const MissionScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

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
            isDesktop ? 32 : 18,
            16,
            isDesktop ? 32 : 18,
            isDesktop ? 40 : 100,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildHeroIntro(context, cc),
                  const SizedBox(height: 24),
                  _buildLiveFleetPulse(context, cc),
                  const SizedBox(height: 24),
                  const SectionHeader('EDGE-TO-MUNICIPAL ARCHITECTURE PIPELINE'),
                  const SizedBox(height: 10),
                  _buildArchitecturePipeline(context),
                  const SizedBox(height: 24),
                  const SectionHeader('CORE PLATFORM ADVANTAGES · ZERO CAPEX'),
                  const SizedBox(height: 10),
                  _buildPillarsGrid(context),
                  const SizedBox(height: 28),
                  _buildActionControls(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Dp.card,
            borderRadius: BorderRadius.circular(Dp.rSm),
            border: Border.all(color: Dp.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Drishti.icon(DGlyph.shield, size: 14, color: Dp.accent),
              const SizedBox(width: 6),
              Text(
                'AIS-140 / VLTD EDGE SPEC',
                style: monoTxt(10.5, color: Dp.accent, w: FontWeight.w700, ls: 0.8),
              ),
            ],
          ),
        ),
        const Spacer(),
        const LivePill(label: 'FLEET SCANNER ACTIVE', dense: true),
      ],
    );
  }

  Widget _buildHeroIntro(BuildContext context, CommandCenter cc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rLg),
        border: Border.all(color: Dp.hairline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DRISHTI-TRANSIT',
                style: AppText.displayHero.copyWith(
                  fontSize: 32,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Dp.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Dp.rFull),
                  border: Border.all(color: Dp.accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'v1.0-PROTOTYPE',
                  style: monoTxt(9.5, color: Dp.accent, w: FontWeight.w700, ls: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Autonomous Road & Congestion Intelligence via Existing Transit Fleets',
            style: AppText.displaySection.copyWith(
              color: Dp.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Buses already carry government-mandated cameras (AIS-140 VLTD/CCTV). '
            'Drishti-Transit is the sovereign software layer that converts those routine feeds '
            'into a continuous, 24/7 road-defect and congestion radar for municipal authorities — '
            'with zero additional hardware, zero road crews, and zero network bloat.',
            style: AppText.body.copyWith(
              color: Dp.textMuted,
              height: 1.55,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildBadge('ZERO HARDWARE CAPEX', DGlyph.check),
              _buildBadge('ON-DEVICE EDGE INFERENCE', DGlyph.scan),
              _buildBadge('SUB-METER DEFECT GEO-TAGGING', DGlyph.pin),
              _buildBadge('AUTONOMOUS PWD DISPATCH', DGlyph.arrowUpRight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, DGlyph glyph) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Dp.field,
        borderRadius: BorderRadius.circular(Dp.rSm),
        border: Border.all(color: Dp.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Drishti.icon(glyph, size: 12, color: Dp.accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: monoTxt(10, color: Dp.inkSoft, w: FontWeight.w600, ls: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFleetPulse(BuildContext context, CommandCenter cc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Dp.field,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: StatBlock(
              number: '${cc.busesOnline}',
              label: 'ACTIVE BUS SCANNERS',
              trend: 'LIVE',
            ),
          ),
          Container(width: 1, height: 38, color: Dp.hairline),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: StatBlock(
                number: '${cc.total}',
                label: 'DEFECTS TRIAGED',
                color: Dp.accent,
                trend: '+${cc.incidents.length > 5 ? 5 : cc.incidents.length}',
              ),
            ),
          ),
          Container(width: 1, height: 38, color: Dp.hairline),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: StatBlock(
                number: '${cc.coveragePercent}%',
                label: 'METRO GRID SURVEYED',
              ),
            ),
          ),
          Container(width: 1, height: 38, color: Dp.hairline),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: StatBlock(
                number: '11.8ms',
                label: 'EDGE LATENCY',
                color: Dp.note,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitecturePipeline(BuildContext context) {
    final stages = [
      (
        step: '01',
        title: 'MANDATED CAMERA',
        subtitle: 'AIS-140 VLTD / CCTV',
        detail: 'Taps existing front dashcam RTSP feed at 1080p 30fps without modifying vehicle electronics.',
        glyph: DGlyph.camera,
        accent: Dp.note,
      ),
      (
        step: '02',
        title: 'EDGE NEURAL ENGINE',
        subtitle: 'Quantized YOLO / MobileNet',
        detail: 'Runs localized inference on low-power in-vehicle compute (11.8ms per frame) to isolate road defects.',
        glyph: DGlyph.scan,
        accent: Dp.accent,
      ),
      (
        step: '03',
        title: 'GEO-TELEMETRY SYNC',
        subtitle: 'Low-Bandwidth Vectors',
        detail: 'Transmits sub-kilobyte incident packets with GPS, bounding polygon, and severity score — zero video upload.',
        glyph: DGlyph.signal,
        accent: Dp.watch,
      ),
      (
        step: '04',
        title: 'MUNICIPAL COMMAND',
        subtitle: 'Drishti Ops Console',
        detail: 'Renders real-time road degradation heatmaps and automates road repair work orders for city engineers.',
        glyph: DGlyph.target,
        accent: Dp.critical,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _buildStageCard(stages[i])),
              ],
            ],
          );
        } else {
          return Column(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildStageCard(stages[i]),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildStageCard(({Color accent, String detail, DGlyph glyph, String step, String subtitle, String title}) s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.step,
                style: monoTxt(12, color: s.accent, w: FontWeight.w700),
              ),
              const Spacer(),
              Drishti.icon(s.glyph, size: 16, color: s.accent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.title,
            style: monoTxt(11, color: Dp.ink, w: FontWeight.w700, ls: 0.6),
          ),
          const SizedBox(height: 2),
          Text(
            s.subtitle,
            style: monoTxt(9.5, color: s.accent, w: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            s.detail,
            style: AppText.bodySmall.copyWith(
              fontSize: 11.5,
              height: 1.4,
              color: Dp.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsGrid(BuildContext context) {
    final pillars = [
      (
        title: 'Zero New Hardware Costs',
        desc: 'Leverages mandated AIS-140 VLTD devices and front dashboard CCTV. Deploys as a pure firmware/software update without municipal tender cycles.',
        glyph: DGlyph.shield,
      ),
      (
        title: 'Continuous Rolling Audits',
        desc: 'Transit buses traverse key municipal corridors every 15 minutes, surveying 100% of public roads daily instead of annual manual inspections.',
        glyph: DGlyph.route,
      ),
      (
        title: 'Autonomous Severity Triage',
        desc: 'Classifies potholes, structural cracks, and road degradation on a calibrated scale (Watch, Alert, Critical) to prioritize emergency asphalt repairs.',
        glyph: DGlyph.alert,
      ),
      (
        title: 'Congestion Heatmap Telemetry',
        desc: 'Measures bus dwell times, transit headway delays, and corridor bottlenecks to give traffic controllers live corridor choke maps.',
        glyph: DGlyph.heat,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final p in pillars)
              SizedBox(
                width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Dp.card,
                    borderRadius: BorderRadius.circular(Dp.rMd),
                    border: Border.all(color: Dp.hairline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Dp.field,
                          borderRadius: BorderRadius.circular(Dp.rSm),
                          border: Border.all(color: Dp.hairline),
                        ),
                        child: Drishti.icon(p.glyph, size: 18, color: Dp.accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: AppText.label.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.desc,
                              style: AppText.bodySmall.copyWith(
                                fontSize: 12,
                                height: 1.4,
                                color: Dp.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Dp.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPLORE LIVE SIMULATION',
                  style: monoTxt(12, color: Dp.accent, w: FontWeight.w700, ls: 0.8),
                ),
                const SizedBox(height: 3),
                Text(
                  'Trace a real-time detection from the camera bounding box feed to the live city map and analytics.',
                  style: AppText.bodySmall.copyWith(color: Dp.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TactileButton(
            label: 'DETECTION FEED',
            icon: DGlyph.camera,
            accent: Dp.accent,
            dense: false,
            onTap: () {
              if (onNavigateToTab != null) {
                onNavigateToTab!(1);
              } else {
                context.go('/edge');
              }
            },
          ),
          const SizedBox(width: 10),
          TactileButton(
            label: 'COMMAND MAP',
            icon: DGlyph.markRadar,
            outline: true,
            dense: false,
            onTap: () {
              if (onNavigateToTab != null) {
                onNavigateToTab!(2);
              } else {
                context.go('/command');
              }
            },
          ),
        ],
      ),
    );
  }
}
