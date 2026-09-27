import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/palette.dart';
import '../../core/command_center.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/mobile/mobile_controls.dart';
import '../../ui/mobile/mobile_surfaces.dart';
import '../../ui/mobile/mobile_tokens.dart';

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
  bool _chime = true;
  bool _haptics = true;
  bool _slaWarnings = true;
  double _radiusKm = 1.5;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();

    return Scaffold(
      backgroundColor: Dp.canvas,
      body: GovCanvas(
        child: SafeArea(
          child: Column(
            children: [
              const GovTricolorBar(height: 3),
              _buildTopBar(context, cc),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(MSp.gutter, 18, MSp.gutter, 40),
                  children: [
                    _buildProfile(context, cc),
                    const SizedBox(height: 24),

                    const MSectionLabel('PATROL ROUTE & CORRIDOR'),
                    const SizedBox(height: 10),
                    _buildRouteCard(context, cc),
                    const SizedBox(height: 24),

                    const MSectionLabel('NOTIFICATION & DISPATCH ALERTS'),
                    const SizedBox(height: 10),
                    _buildNotificationCard(context),
                    const SizedBox(height: 24),

                    const MSectionLabel('OFFLINE BUFFER & TELEMETRY SYNC'),
                    const SizedBox(height: 10),
                    _buildOfflineCard(context, cc),
                    const SizedBox(height: 24),

                    const MSectionLabel('OUTDOOR DISPLAY & SUNLIGHT CONTRAST'),
                    const SizedBox(height: 10),
                    _buildThemeCard(context, cc),
                    const SizedBox(height: 24),

                    const MSectionLabel('DEVICE HARDWARE & AIS-140 LINK'),
                    const SizedBox(height: 10),
                    _buildHardwareCard(context),
                    const SizedBox(height: 28),

                    _buildSignOut(context),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'DRISHTI FIELD OPS · v1.0',
                        style: MT.eyebrow(size: 8.5, color: Dp.textFaint, ls: 1.6),
                      ),
                    ),
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
    final online = !cc.isFieldOffline;
    final color = online ? MSig.online : MSig.offline;

    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(12, 0, MSp.gutter, 0),
      decoration: BoxDecoration(
        color: Dp.isDark ? const Color(0xFF0A1120) : Colors.white,
        border: Border(bottom: BorderSide(color: Dp.hairline, width: 1.0)),
      ),
      child: Row(
        children: [
          MIconButton(
            glyph: DGlyph.chevronLeft,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
            size: 40,
            iconSize: 17,
            radius: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Field Settings', style: MT.title(size: 15, color: Dp.ink, w: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  'Officer preferences · Unit FC-04',
                  style: MT.data(size: 9.5, color: Dp.textMuted, w: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MPill(
            label: online ? 'ONLINE' : 'OFFLINE',
            color: color,
            dot: true,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, CommandCenter cc) {
    return MCard(
      padding: EdgeInsets.zero,
      glowColor: MSig.accent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MRing(color: MSig.saffron, glyph: DGlyph.shield, size: 48, iconSize: 22, stroke: 1.7),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Inspector R. Gaikwad',
                              style: MT.title(size: 15, color: Dp.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 7),
                          MPill(label: 'FC-04', color: MSig.accent, dense: true, solid: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PWD on-ground road repair & verification unit',
                        style: MT.body(size: 11.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Drishti.icon(DGlyph.clock, size: 12, color: Dp.textFaint, stroke: 1.6),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '08:00 – 16:30 IST',
                              style: MT.data(size: 10, color: Dp.textMuted, w: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Drishti.icon(DGlyph.bus, size: 13, color: Dp.textFaint, stroke: 1.5),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'MH-12-TR-4402',
                              style: MT.data(size: 10, color: Dp.textMuted, w: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const MDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Drishti.icon(DGlyph.check, size: 13, color: MSig.resolved, stroke: 2.2),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${cc.myResolvedToday.length} defects repaired today · SLA score 98.4%',
                    style: MT.caption(size: 11, color: Dp.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, CommandCenter cc) {
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MRing(color: MSig.accent, glyph: DGlyph.route, size: 34, iconSize: 16),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current patrol route', style: MT.title(size: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      'Alerts filter to this corridor instantly',
                      style: MT.caption(size: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final route in cc.availableRoutes)
                MChip(
                  label: route,
                  selected: cc.mobileAssignedRoute == route,
                  icon: cc.mobileAssignedRoute == route ? DGlyph.check : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    cc.setMobileAssignedRoute(route);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context) {
    return MCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          MInfoRow(
            leading: DGlyph.alert,
            title: 'Urgent dispatch chime',
            subtitle: 'Loud audible alarm when a critical hazard is assigned nearby',
            trailing: MToggle(
              value: _chime,
              onChanged: (v) => setState(() => _chime = v),
            ),
          ),
          const MDivider(),
          MInfoRow(
            leading: DGlyph.heat,
            title: 'High-priority haptics',
            subtitle: 'Strong vibration on entering 500 m of an unverified defect',
            trailing: MToggle(
              value: _haptics,
              onChanged: (v) => setState(() => _haptics = v),
            ),
          ),
          const MDivider(),
          MInfoRow(
            leading: DGlyph.clock,
            title: 'SLA escalation warnings',
            subtitle: 'Remind me when an assigned order has under 60 minutes left',
            trailing: MToggle(
              value: _slaWarnings,
              onChanged: (v) => setState(() => _slaWarnings = v),
            ),
          ),
          const MDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Proximity radar radius', style: MT.title(size: 13.5)),
                          const SizedBox(height: 3),
                          Text(
                            'Search distance around the patrol vehicle',
                            style: MT.caption(size: 10.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: MSig.accentFill(Dp.isDark ? 0.15 : 0.11),
                        borderRadius: BorderRadius.circular(Dp.rSm),
                        border: Border.all(color: MSig.accentRing),
                      ),
                      child: Text(
                        '${_radiusKm.toStringAsFixed(1)} km',
                        style: MT.data(size: 12, color: MSig.accent, w: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                MSlider(
                  value: _radiusKm,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  onChanged: (v) => setState(() => _radiusKm = v),
                  format: (v) => '${v.toStringAsFixed(1)} km',
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.5 km', style: MT.data(size: 9, color: Dp.textFaint, w: FontWeight.w500)),
                      Text('5.0 km', style: MT.data(size: 9, color: Dp.textFaint, w: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCard(BuildContext context, CommandCenter cc) {
    final offline = cc.isFieldOffline;
    final color = offline ? MSig.offline : MSig.online;

    return MCard(
      padding: EdgeInsets.zero,
      borderColor: color.withValues(alpha: Dp.isDark ? 0.32 : 0.24),
      child: Column(
        children: [
          MInfoRow(
            leading: DGlyph.offlineCloud,
            title: 'Offline buffer',
            subtitle: 'Simulate a tunnel or low-signal zone with local queueing',
            trailing: MToggle(
              value: offline,
              accent: MSig.offline,
              onChanged: (_) {
                HapticFeedback.selectionClick();
                cc.toggleFieldOffline();
              },
            ),
          ),
          const MDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Drishti.icon(DGlyph.stacks, size: 14, color: MSig.accent, stroke: 1.7),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'LOCAL BUFFER · ${cc.pendingSyncCount} PENDING',
                        style: MT.data(size: 10, color: Dp.ink, w: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  offline
                      ? 'Actions are held in the encrypted local queue and pushed the moment signal returns.'
                      : 'Connected to the municipal grid over the AIS-140 MQTT relay.',
                  style: MT.caption(size: 11),
                ),
                if (cc.pendingSyncCount > 0 && !offline) ...[
                  const SizedBox(height: 13),
                  MButton(
                    label: 'Force sync now',
                    icon: DGlyph.refresh,
                    kind: MButtonKind.tonal,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      cc.syncOfflineQueue();
                      showFieldToast(context, 'Offline queue flushed to command.',
                          accent: MSig.accent);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, CommandCenter cc) {
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MChoice<ThemeMode>(
            value: cc.themeMode,
            onChanged: (m) {
              HapticFeedback.selectionClick();
              cc.setThemeMode(m);
            },
            options: const [
              (ThemeMode.system, 'SYSTEM', DGlyph.stacks),
              (ThemeMode.light, 'OUTDOOR\nLIGHT', DGlyph.sun),
              (ThemeMode.dark, 'NIGHT\nPATROL', DGlyph.moon),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Drishti.icon(DGlyph.info, size: 13, color: Dp.textFaint, stroke: 1.6),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Outdoor Light maximises contrast for asphalt inspection in direct sun. Night Patrol is tuned for OLED night shifts.',
                  style: MT.caption(size: 10.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareCard(BuildContext context) {
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AshokaChakra(size: 15, color: Color(0xFF000080)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Government hardware telemetry',
                  style: MT.title(size: 13.5),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _DiagRow('Terminal', 'Panasonic Toughpad G2 · Android 14'),
          const _DiagRow('GNSS accuracy', '±0.8 m · NavIC L5 + GPS L1'),
          const _DiagRow('AIS-140 protocol', 'IRNSS MQTT v3.1 · Sec 125-E'),
          const _DiagRow('On-site camera', '50 MP macro laser-AF · active'),
        ],
      ),
    );
  }

  Widget _buildSignOut(BuildContext context) {
    return MButton(
      label: 'End shift & sign out',
      icon: DGlyph.chevronLeft,
      kind: MButtonKind.outline,
      accent: MSig.offline,
      tall: true,
      onTap: () {
        HapticFeedback.mediumImpact();
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              decoration: BoxDecoration(
                color: Dp.canvasSoft,
                borderRadius: BorderRadius.circular(Dp.rMd),
                border: Border.all(color: Dp.hairline),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MRing(color: MSig.offline, glyph: DGlyph.alert, size: 36, iconSize: 17),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text('End this shift?', style: MT.title(size: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your activity log stays recorded. Any offline un-synced actions remain in the encrypted cache until the next officer signs in.',
                    style: MT.body(size: 12),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: MButton(
                          label: 'Keep working',
                          kind: MButtonKind.ghost,
                          onTap: () => Navigator.of(dialogCtx).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MButton(
                          label: 'Sign out',
                          kind: MButtonKind.danger,
                          onTap: () {
                            Navigator.of(dialogCtx).pop();
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiagRow extends StatelessWidget {
  const _DiagRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label, style: MT.eyebrow(size: 8.5, color: Dp.textFaint, ls: 1.0)),
          ),
          Expanded(
            child: Text(
              value,
              style: MT.data(size: 10.5, color: Dp.ink, w: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
