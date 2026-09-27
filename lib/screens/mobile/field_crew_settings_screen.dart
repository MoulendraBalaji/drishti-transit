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

/// Field Crew Settings Screen:
/// Configures how THIS app behaves for THIS field worker on-ground.
/// Features:
/// - Route & patrol zone reassignment
/// - Notification & urgent haptic dispatch preferences
/// - Offline queue tolerance & local cache buffer
/// - Outdoor sunlight readability theme selector
/// - Field officer profile & account logout
/// Zero exposure to central operations views or fleet-wide analytics.
class FieldCrewSettingsScreen extends StatefulWidget {
  const FieldCrewSettingsScreen({super.key});

  @override
  State<FieldCrewSettingsScreen> createState() => _FieldCrewSettingsScreenState();
}

class _FieldCrewSettingsScreenState extends State<FieldCrewSettingsScreen> {
  // Local notification preferences for field worker
  bool _urgentSoundAlerts = true;
  bool _hapticVibration = true;
  bool _slaEscalationWarnings = true;
  double _dispatchRadiusKm = 1.5;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: SafeArea(
          child: Column(
            children: [
              const GovTricolorBar(height: 3.0),
              _buildTopBar(context, cc),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    _buildOfficerProfileCard(context, cc),
                    const SizedBox(height: 20),

                    _buildSectionHeader('ASSIGNED PATROL ROUTE & CORRIDOR'),
                    const SizedBox(height: 8),
                    _buildRouteReassignmentCard(context, cc),
                    const SizedBox(height: 20),

                    _buildSectionHeader('NOTIFICATION & DISPATCH ALERTS'),
                    const SizedBox(height: 8),
                    _buildNotificationCard(context),
                    const SizedBox(height: 20),

                    _buildSectionHeader('OFFLINE BUFFER & TELEMETRY SYNC'),
                    const SizedBox(height: 8),
                    _buildOfflineCacheCard(context, cc),
                    const SizedBox(height: 20),

                    _buildSectionHeader('OUTDOOR DISPLAY & SUNLIGHT CONTRAST'),
                    const SizedBox(height: 8),
                    _buildThemeSelector(context, cc, isDark),
                    const SizedBox(height: 20),

                    _buildSectionHeader('DEVICE HARDWARE & AIS-140 SENSOR LINK'),
                    const SizedBox(height: 8),
                    _buildHardwareCard(context, cc),
                    const SizedBox(height: 24),

                    _buildSignOutButton(context),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, CommandCenter cc) {
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
              Navigator.of(context).pop();
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
                child: Drishti.icon(DGlyph.chevronLeft, size: 16, color: Dp.ink),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIELD SETTINGS',
                style: AppText.label.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'OFFICER PREFERENCES · PMPML WEST CORRIDOR',
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cc.isFieldOffline
                  ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                  : const Color(0xFF138808).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Dp.rFull),
              border: Border.all(
                color: cc.isFieldOffline ? const Color(0xFFDC2626) : const Color(0xFF138808),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cc.isFieldOffline ? const Color(0xFFDC2626) : const Color(0xFF138808),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  cc.isFieldOffline ? 'OFFLINE' : 'ONLINE',
                  style: monoTxt(
                    8.5,
                    color: cc.isFieldOffline ? const Color(0xFFDC2626) : const Color(0xFF138808),
                    w: FontWeight.w800,
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

  Widget _buildOfficerProfileCard(BuildContext context, CommandCenter cc) {
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9933), width: 1.5),
                ),
                child: Center(
                  child: Drishti.icon(DGlyph.shield, size: 22, color: const Color(0xFFFF9933)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Inspector R. Gaikwad',
                          style: AppText.label.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Dp.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Dp.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FC-04',
                            style: monoTxt(8.5, color: Dp.accent, w: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PWD On-Ground Road Repair & Verification Unit',
                      style: AppText.bodySmall.copyWith(
                        color: Dp.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shift: 08:00 - 16:30 IST · Vehicle MH-12-TR-4402',
                      style: monoTxt(9, color: Dp.textFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Dp.canvas,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairlineSoft),
            ),
            child: Row(
              children: [
                Drishti.icon(DGlyph.wrench, size: 12, color: const Color(0xFF138808)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${cc.myResolvedToday.length} defects repaired & verified today · SLA score 98.4%',
                    style: monoTxt(9.5, color: Dp.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteReassignmentCard(BuildContext context, CommandCenter cc) {
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
              Drishti.icon(DGlyph.route, size: 16, color: Dp.accent),
              const SizedBox(width: 8),
              Text(
                'CURRENT PATROL ROUTE',
                style: AppText.label.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9933).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Dp.rFull),
                  border: Border.all(color: const Color(0xFFFF9933)),
                ),
                child: Text(
                  cc.mobileAssignedRoute.toUpperCase(),
                  style: monoTxt(9.5, color: const Color(0xFFFF9933), w: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Select the municipal transit route assigned to your unit for today\'s shift. Alerts and urgent defect orders will immediately filter to this corridor.',
            style: AppText.bodySmall.copyWith(color: Dp.textMuted, fontSize: 10, height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cc.availableRoutes.map((route) {
              final active = cc.mobileAssignedRoute.toUpperCase() == route.toUpperCase();
              return Tactile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  cc.setMobileAssignedRoute(route);
                },
                child: AnimatedContainer(
                  duration: Mo.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? Dp.canvas : Colors.transparent,
                    borderRadius: BorderRadius.circular(Dp.rSm),
                    border: Border.all(
                      color: active ? Dp.accent : Dp.hairline,
                      width: active ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF138808),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        route,
                        style: monoTxt(
                          10,
                          color: active ? Dp.ink : Dp.textMuted,
                          w: active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        children: [
          _settingSwitchTile(
            title: 'URGENT DISPATCH CHIME',
            description: 'Audible loud chime when a Critical road hazard is assigned nearby',
            value: _urgentSoundAlerts,
            onChanged: (v) => setState(() => _urgentSoundAlerts = v),
          ),
          Divider(height: 1, color: Dp.hairline),
          _settingSwitchTile(
            title: 'HIGH-PRIORITY HAPTICS',
            description: 'Vibrate device strongly upon entering 500m proximity of unverified defect',
            value: _hapticVibration,
            onChanged: (v) => setState(() => _hapticVibration = v),
          ),
          Divider(height: 1, color: Dp.hairline),
          _settingSwitchTile(
            title: 'SLA ESCALATION WARNINGS',
            description: 'Push reminder if an assigned work order has under 60 minutes remaining',
            value: _slaEscalationWarnings,
            onChanged: (v) => setState(() => _slaEscalationWarnings = v),
          ),
          Divider(height: 1, color: Dp.hairline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROXIMITY RADAR RADIUS',
                      style: AppText.label.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_dispatchRadiusKm.toStringAsFixed(1)} KM',
                      style: monoTxt(10.5, color: Dp.accent, w: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Search distance around patrol vehicle to catch nearby reported potholes',
                  style: AppText.bodySmall.copyWith(color: Dp.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Dp.accent,
                    inactiveTrackColor: Dp.hairline,
                    thumbColor: Dp.accent,
                    overlayColor: Dp.accent.withValues(alpha: 0.15),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _dispatchRadiusKm,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    onChanged: (v) => setState(() => _dispatchRadiusKm = v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCacheCard(BuildContext context, CommandCenter cc) {
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
                    'OFFLINE BUFFER SIMULATION',
                    style: AppText.label.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Simulate field tunnel / low-signal zone with local queueing',
                    style: AppText.bodySmall.copyWith(color: Dp.textMuted, fontSize: 10),
                  ),
                ],
              ),
              Switch.adaptive(
                value: cc.isFieldOffline,
                activeTrackColor: const Color(0xFFDC2626),
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  cc.toggleFieldOffline();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Dp.canvas,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairlineSoft),
            ),
            child: Row(
              children: [
                Drishti.icon(DGlyph.stacks, size: 14, color: Dp.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOCAL BUFFER: ${cc.pendingSyncCount} ACTION(S) PENDING SYNC',
                        style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w800),
                      ),
                      Text(
                        cc.isFieldOffline
                            ? 'Actions buffered in encrypted SQLite memory. Will push when reconnecting.'
                            : 'Connected to Municipal Grid via 4G/AIS-140 MQTT relay.',
                        style: monoTxt(8.5, color: Dp.textMuted),
                      ),
                    ],
                  ),
                ),
                if (cc.pendingSyncCount > 0 && !cc.isFieldOffline) ...[
                  const SizedBox(width: 8),
                  Tactile(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      cc.syncOfflineQueue();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF138808),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FORCE SYNC',
                        style: monoTxt(8.5, color: Colors.white, w: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, CommandCenter cc, bool isDark) {
    final currentMode = cc.themeMode;

    return Container(
      padding: const EdgeInsets.all(14),
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
                  label: 'OUTDOOR LIGHT',
                  subtitle: 'Sunlight Contrast',
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
                  label: 'NIGHT PATROL',
                  subtitle: 'OLED Dark',
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
          const SizedBox(height: 10),
          Text(
            'Outdoor Light mode provides maximum high-contrast visibility when inspecting asphalt under direct sunlight.',
            style: AppText.bodySmall.copyWith(color: Dp.textMuted, fontSize: 9.5),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? Dp.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Dp.accent : Dp.hairline,
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Drishti.icon(icon, size: 16, color: active ? Dp.accent : Dp.inkSoft),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 9.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? Dp.accent : Dp.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppText.dataTiny.copyWith(fontSize: 8, color: Dp.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareCard(BuildContext context, CommandCenter cc) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const AshokaChakra(size: 14, color: Color(0xFF000080)),
              const SizedBox(width: 8),
              Text(
                'GOVERNMENT HARDWARE TELEMETRY',
                style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _diagRow('Terminal Model', 'Panasonic Toughpad G2 / Android 14 Rugged'),
          _diagRow('GNSS Accuracy', '±0.8m · NavIC Dual-Freq L5 + GPS L1'),
          _diagRow('AIS-140 Protocol', 'IRNSS MQTT v3.1 · Sec 125-E CMVR 1989'),
          _diagRow('On-Site Camera', '50MP Macro Laser-AF Optical Sensor Active'),
        ],
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: monoTxt(9, color: Dp.textMuted)),
          Flexible(
            child: Text(
              value,
              style: monoTxt(9, color: Dp.ink, w: FontWeight.w700),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Tactile(
      onTap: () {
        HapticFeedback.mediumImpact();
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: Dp.canvasSoft,
            title: Text(
              'Sign Out of Terminal?',
              style: AppText.label.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            content: Text(
              'Your shift activity log will remain recorded. Any offline un-synced actions will be stored in encrypted cache until the next officer signs in.',
              style: AppText.bodySmall.copyWith(color: Dp.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text('CANCEL', style: monoTxt(10, color: Dp.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Navigator.of(context).pop();
                },
                child: Text('SIGN OUT', style: monoTxt(10, color: Colors.white, w: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Dp.rSm),
          border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 14, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Text(
                'END SHIFT & SIGN OUT OF TERMINAL',
                style: monoTxt(10, color: const Color(0xFFDC2626), w: FontWeight.w800, ls: 0.6),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
