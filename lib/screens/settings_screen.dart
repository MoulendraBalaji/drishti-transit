import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../ui/glyphs.dart';

/// Settings screen for Drishti Transit — configuring theme (System default,
/// Light, Dark), map layers, edge-AI inference thresholds, and hardware telemetry.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  _buildSectionHeader('HARDWARE & DIAGNOSTICS'),
                  const SizedBox(height: 10),
                  _buildHardwareCard(context, cc),
                  const SizedBox(height: 32),
                  _buildResetButton(context, cc),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
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
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'COMMAND NODE CONFIGURATION',
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
            child: Text(
              'v1.0.2',
              style: monoTxt(
                10,
                color: Dp.accent,
                w: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRISHTI TRANSIT NETWORK',
                  style: AppText.label.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'On-device edge AI telemetry platform turning municipal bus fleets into real-time urban sensing grids.',
                  style: AppText.bodySmall.copyWith(
                    color: Dp.textMuted,
                    fontSize: 11,
                    height: 1.35,
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
          _infoRow('EDGE UNIT', 'NVIDIA Jetson Orin Nano (8GB)'),
          const SizedBox(height: 10),
          _infoRow('NEURAL MODEL', 'YOLOv8-Transit-TRT v4.2 @ FP16'),
          const SizedBox(height: 10),
          _infoRow('ACTIVE NODES', '42 / 42 Fleet Buses Streaming'),
          const SizedBox(height: 10),
          _infoRow('RELAY LATENCY', '14 ms (Direct 5G Edge Bridge)'),
          const SizedBox(height: 10),
          _infoRow('CORRIDORS', 'Majestic, Silk Board, Whitefield, Hebbal'),
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
