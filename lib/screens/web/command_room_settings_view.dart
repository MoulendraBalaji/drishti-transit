import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../app/typography.dart';
import '../../core/command_center.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/tactile.dart';

/// CommandRoomSettingsView — Dedicated Settings view for the Command Room (Web) experience.
///
/// Scope: City Authority / Transit Grid Command Center
/// Contains:
/// - Inference thresholds & Edge-AI confidence floors
/// - Urban corridor surveillance & municipal zone management
/// - Map overlays & multi-monitor display aesthetics
/// - MoRTH AIS-140 MQTT broker telemetry & server node health
/// - Operator session credentials & audit compliance
///
/// Completely independent from any on-ground field interfaces.
class CommandRoomSettingsView extends StatelessWidget {
  const CommandRoomSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: Dp.canvas,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        children: [
          _buildAuthorityBanner(context),
          const SizedBox(height: 20),

          _buildSectionHeader('EDGE-AI INFERENCE ENGINE & DISPATCH THRESHOLDS'),
          const SizedBox(height: 8),
          _buildInferenceCard(context, cc),
          const SizedBox(height: 20),

          _buildSectionHeader('TRANSIT GRID GIS & MAP TELEMETRY LAYERS'),
          const SizedBox(height: 8),
          _buildMapLayersCard(context, cc),
          const SizedBox(height: 20),

          _buildSectionHeader('COMMAND CENTER DISPLAY THEME (MULTI-MONITOR CONSOLE)'),
          const SizedBox(height: 8),
          _buildThemeSelector(context, cc, isDark),
          const SizedBox(height: 20),

          _buildSectionHeader('SERVER CLUSTER & AIS-140 TELEMETRY BROKER HEALTH'),
          const SizedBox(height: 8),
          _buildClusterHealthCard(context, cc),
          const SizedBox(height: 24),

          _buildResetButton(context, cc),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppText.dataTiny.copyWith(
        color: Dp.textFaint,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildAuthorityBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9933), width: 1.5),
            ),
            child: Image.asset(
              'assets/images/dristhi.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: AshokaChakra(size: 22, color: Dp.accent),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PUNE MUNICIPAL CORPORATION · PMPML TRANSIT CONTROL',
                      style: monoTxt(9, color: const Color(0xFFFF9933), w: FontWeight.w800, ls: 0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF138808).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(Dp.rFull),
                        border: Border.all(color: const Color(0xFF138808)),
                      ),
                      child: Text(
                        'SECURE NODE · TIER-1 ADMIN',
                        style: monoTxt(8.5, color: const Color(0xFF138808), w: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Central Operations Dashboard Configuration',
                  style: AppText.label.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: Dp.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'Operator: Chief Controller · Node: PMC-HQ-SERVER-01 · Active Corridors: 8 Managed Sectors',
                  style: monoTxt(9.5, color: Dp.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInferenceCard(BuildContext context, CommandCenter cc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETECTION CONFIDENCE FLOOR',
                    style: AppText.label.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Minimum Edge-AI model confidence score required to ingest incident into municipal grid',
                    style: AppText.bodySmall.copyWith(color: Dp.textMuted, fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Dp.canvas,
                  borderRadius: BorderRadius.circular(Dp.rFull),
                  border: Border.all(color: Dp.hairline),
                ),
                child: Text(
                  '${(cc.confidenceThreshold * 100).toStringAsFixed(0)}%',
                  style: monoTxt(11, w: FontWeight.w800, color: Dp.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Dp.accent,
              inactiveTrackColor: Dp.hairline,
              thumbColor: Dp.accent,
              overlayColor: Dp.accent.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: cc.confidenceThreshold,
              min: 0.85,
              max: 0.98,
              divisions: 13,
              onChanged: (v) => cc.setConfidenceThreshold(v),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Dp.hairline),
          const SizedBox(height: 6),
          _settingSwitchTile(
            title: 'AUTOMATED DISPATCH WORK ORDER RULE',
            description: 'Instantly issue electronic work orders to nearest municipal maintenance unit on Critical potholes',
            value: cc.autoDispatch,
            padding: EdgeInsets.zero,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              cc.toggleAutoDispatch();
            },
          ),
          const SizedBox(height: 6),
          Divider(height: 1, color: Dp.hairline),
          const SizedBox(height: 6),
          _settingSwitchTile(
            title: 'ANPR LICENSE PLATE OCR EXTRACTION',
            description: 'Extract registration tags of commercial heavy vehicles inducing road fracturing',
            value: cc.plateOcrEnabled,
            padding: EdgeInsets.zero,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              cc.togglePlateOcr();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayersCard(BuildContext context, CommandCenter cc) {
    return Container(
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        children: [
          _settingSwitchTile(
            title: 'TRANSIT CORRIDOR POLYLINES',
            description: 'Overlay all 8 monitored PMPML bus corridor routes on city map canvas',
            value: cc.showCorridors,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              cc.toggleCorridors();
            },
          ),
          Divider(height: 1, color: Dp.hairline),
          _settingSwitchTile(
            title: 'INCIDENT DENSITY HEATMAP',
            description: 'Compute and render spatial kernel density estimation for road cavities & fractures',
            value: cc.showHeatmap,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              cc.toggleHeatmap();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, CommandCenter cc, bool isDark) {
    final currentMode = cc.themeMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _themeOption(
                  label: 'OBSIDIAN DARK',
                  subtitle: 'Video Wall Recommended',
                  icon: DGlyph.moon,
                  active: currentMode == ThemeMode.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cc.setThemeMode(ThemeMode.dark);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _themeOption(
                  label: 'DAYLIGHT DESK',
                  subtitle: 'Office White',
                  icon: DGlyph.sun,
                  active: currentMode == ThemeMode.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cc.setThemeMode(ThemeMode.light);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _themeOption(
                  label: 'SYSTEM AUTO',
                  subtitle: 'Follow OS Theme',
                  icon: DGlyph.stacks,
                  active: currentMode == ThemeMode.system,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cc.setThemeMode(ThemeMode.system);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Obsidian Dark theme reduces eye strain during 24x7 control room shifts and increases high-contrast visibility for live dashcam video and heatmap overlays.',
            style: AppText.bodySmall.copyWith(color: Dp.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required String label,
    required String subtitle,
    required DGlyph icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Tactile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? Dp.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Dp.accent : Dp.hairline,
            width: active ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Drishti.icon(icon, size: 18, color: active ? Dp.accent : Dp.inkSoft),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? Dp.accent : Dp.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppText.dataTiny.copyWith(fontSize: 8.5, color: Dp.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterHealthCard(BuildContext context, CommandCenter cc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AshokaChakra(size: 15, color: Color(0xFF000080)),
              const SizedBox(width: 8),
              Text(
                'MUNICIPAL TELEMETRY CLUSTER STATUS',
                style: monoTxt(10, color: Dp.ink, w: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF138808), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('CLUSTER HEALTHY', style: monoTxt(8.5, color: const Color(0xFF138808), w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          _diagRow('Buses Online & Telemetry Active', '${cc.busesOnline} Buses (PMPML Transit Grid)'),
          _diagRow('Total Ingested Defect Vectors', '${cc.total} Events'),
          _diagRow('MQTT Message Broker', 'mqtts://telemetry.pune-transit.gov.in:8883 (QoS 1)'),
          _diagRow('AIS-140 Compliance Standard', 'Section 125-E CMVR 1989 & ARAI AIS-140 Spec 2'),
          _diagRow('Certificate Authority', 'National Informatics Centre (NIC) Municipal Root CA'),
        ],
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: monoTxt(9.5, color: Dp.textMuted)),
          Flexible(
            child: Text(
              value,
              style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w700),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, CommandCenter cc) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tactile(
        onTap: () {
          HapticFeedback.mediumImpact();
          cc.clearTelemetryCache();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Dp.accent,
              content: Text(
                'Municipal pipeline state reset to default initialization.',
                style: monoTxt(10, color: Colors.white, w: FontWeight.w700),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Dp.rSm),
            border: Border.all(color: Dp.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Drishti.icon(DGlyph.refresh, size: 14, color: Dp.textMuted),
              const SizedBox(width: 8),
              Text(
                'RESET SYSTEM SIMULATION STATE',
                style: monoTxt(9.5, color: Dp.textMuted, w: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingSwitchTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.label.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppText.bodySmall.copyWith(color: Dp.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: Dp.accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
