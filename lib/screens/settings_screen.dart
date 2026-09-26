import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../ui/glyphs.dart';
import '../ui/gov_masthead.dart';

/// Settings screen for Drishti Transit — configuring theme (System default,
/// Light, Dark), map layers, edge-AI inference thresholds, and hardware telemetry.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: SafeArea(
          child: Column(
            children: [
              const GovTricolorBar(height: 3.5),
              _buildTopBar(context),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: width > 600 ? 32 : 20,
                      vertical: 16,
                    ),
                    children: [
                      _buildBrandTile(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader('APPEARANCE & THEME'),
                      const SizedBox(height: 10),
                      _buildThemeSelector(context, cc, isDark),
                      const SizedBox(height: 24),
                      _buildSectionHeader('MAP & TELEMETRY LAYERS'),
                      const SizedBox(height: 10),
                      _buildMapSettingsCard(context, cc),
                      const SizedBox(height: 24),
                      _buildSectionHeader('EDGE-AI INFERENCE ENGINE'),
                      const SizedBox(height: 10),
                      _buildAiSettingsCard(context, cc),
                      const SizedBox(height: 24),
                      _buildSectionHeader('GOVERNMENT NODE & HARDWARE TELEMETRY'),
                      const SizedBox(height: 10),
                      _buildHardwareCard(context, cc),
                      const SizedBox(height: 32),
                      _buildResetButton(context, cc),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Dp.canvas,
        border: Border(bottom: BorderSide(color: Dp.hairline, width: 1.0)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Dp.canvasSoft,
                shape: BoxShape.circle,
                border: Border.all(color: Dp.hairline),
              ),
              child: Center(
                child: Drishti.icon(
                  DGlyph.chevronLeft,
                  size: 16,
                  color: Dp.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYSTEM SETTINGS',
                style: AppText.label.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'MINISTRY OF ROAD TRANSPORT & HIGHWAYS • NIC GOV-NET',
                style: AppText.dataTiny.copyWith(
                  color: Dp.textMuted,
                  fontSize: 8.5,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Dp.canvasSoft,
              borderRadius: BorderRadius.circular(Dp.rFull),
              border: Border.all(color: Dp.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF138808),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'AIS-140 VERIFIED',
                  style: monoTxt(
                    9,
                    color: Dp.accent,
                    w: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandTile(BuildContext context) {
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
            children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Dp.hairline, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/dristhi.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Drishti.icon(DGlyph.bus, size: 24, color: Dp.accent),
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
                          'भारत सरकार',
                          style: TextStyle(
                            fontFamily: AppText.sans,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Dp.ink,
                          ),
                        ),
                        Text(
                          ' | GOVERNMENT OF INDIA',
                          style: monoTxt(9.5, color: Dp.textMuted, w: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DRISHTI-TRANSIT (दृष्टि-ट्रांसिट)',
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.6,
                        color: Dp.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'National AI Edge Intelligence Grid for Urban Transit & Road Safety',
                      style: AppText.bodySmall.copyWith(
                        color: Dp.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Dp.canvas,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairlineSoft),
            ),
            child: Row(
              children: [
                Drishti.icon(DGlyph.shield, size: 14, color: const Color(0xFF138808)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Certified under MoRTH AIS-140 Section 125-E CMVR 1989 for Intelligent Transport Systems & Municipal Fleet Edge Telemetry.',
                    style: AppText.bodySmall.copyWith(
                      color: Dp.textMuted,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  label: 'SYSTEM',
                  subtitle: 'Default',
                  icon: DGlyph.stacks,
                  active: currentMode == ThemeMode.system,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cc.setThemeMode(ThemeMode.system);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _themeOption(
                  label: 'LIGHT',
                  subtitle: 'Mobbin White',
                  icon: DGlyph.sun,
                  active: currentMode == ThemeMode.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cc.setThemeMode(ThemeMode.light);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _themeOption(
                  label: 'DARK',
                  subtitle: 'Obsidian',
                  icon: DGlyph.moon,
                  active: currentMode == ThemeMode.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cc.setThemeMode(ThemeMode.dark);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Dp.canvas,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairlineSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Dp.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentMode == ThemeMode.system
                        ? 'Following system default: currently rendering ${isDark ? 'Dark Mode' : 'Light Mode'}'
                        : 'Custom override: fixed to ${currentMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'}',
                    style: monoTxt(
                      10,
                      color: Dp.textMuted,
                    ),
                  ),
                ),
              ],
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeOutTech,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? Dp.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Dp.accent : Dp.hairline,
            width: active ? 1.8 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Dp.accent.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Drishti.icon(
              icon,
              size: 20,
              color: active ? Dp.accent : Dp.inkSoft,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? Dp.accent : Dp.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppText.dataTiny.copyWith(
                fontSize: 8.5,
                color: Dp.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSettingsCard(BuildContext context, CommandCenter cc) {
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
            description: 'Show active bus route corridors and connectivity branches',
            value: cc.showCorridors,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              cc.toggleCorridors();
            },
          ),
          Divider(height: 1, color: Dp.hairline),
          _settingSwitchTile(
            title: 'INCIDENT DENSITY HEATMAP',
            description: 'Render hazard clusters and road fracture heat zones',
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

  Widget _buildAiSettingsCard(BuildContext context, CommandCenter cc) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETECTION CONFIDENCE FLOOR',
                    style: AppText.label.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Minimum threshold to trigger dispatch alert',
                    style: AppText.bodySmall.copyWith(
                      color: Dp.textMuted,
                      fontSize: 10,
                    ),
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
                  style: monoTxt(
                    11,
                    w: FontWeight.w800,
                    color: Dp.accent,
                  ),
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
          const SizedBox(height: 10),
          Divider(height: 1, color: Dp.hairline),
          const SizedBox(height: 6),
          _settingSwitchTile(
            title: 'AUTOMATED EMERGENCY DISPATCH',
            description: 'Directly dispatch critical alerts to civic control room',
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
            title: 'ANPR LICENSE PLATE OCR',
            description: 'On-device Indian vehicle registration number extraction',
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

  Widget _settingSwitchTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.label.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppText.bodySmall.copyWith(
                    color: Dp.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeTrackColor: Dp.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareCard(BuildContext context, CommandCenter cc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        children: [
          _infoRow('GOVERNMENT AGENCY', 'MoRTH • Smart Cities Mission'),
          const SizedBox(height: 10),
          _infoRow('MUNICIPAL OPERATOR', 'Pune Mahanagar Parivahan (PMPML)'),
          const SizedBox(height: 10),
          _infoRow('COMPLIANCE SPEC', 'AIS-140 Section 125-E CMVR 1989'),
          const SizedBox(height: 10),
          _infoRow('EDGE COMPUTING UNIT', 'NVIDIA Jetson Orin Nano (8GB) Automotive'),
          const SizedBox(height: 10),
          _infoRow('NEURAL TENSORRT MODEL', 'YOLOv8-Transit-TRT v4.2 @ FP16'),
          const SizedBox(height: 10),
          _infoRow('ACTIVE FLEET SENSORS', '42 / 42 Municipal Buses Streaming'),
          const SizedBox(height: 10),
          _infoRow('GOV-NET RELAY LATENCY', '14 ms (Direct NIC Edge Gateway)'),
          const SizedBox(height: 10),
          _infoRow('MONITORED CORRIDORS', 'Katraj, Hadapsar, Swargate, Kothrud, Hinjewadi'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.dataTiny.copyWith(
            color: Dp.textFaint,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: monoTxt(
            10.5,
            color: Dp.ink,
            w: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, CommandCenter cc) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        cc.clearTelemetryCache();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Dp.ink,
            content: Text(
              'Telemetry cache cleared and simulations re-initialized.',
              style: TextStyle(color: Dp.canvas, fontSize: 12),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Dp.canvasSoft,
          borderRadius: BorderRadius.circular(Dp.rFull),
          border: Border.all(color: Dp.hairline),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Drishti.icon(DGlyph.refresh, size: 14, color: Dp.textMuted),
              const SizedBox(width: 8),
              Text(
                'CLEAR CACHE & RESTART TELEMETRY',
                style: AppText.dataTiny.copyWith(
                  color: Dp.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
