import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../core/command_center.dart';
import '../../core/models.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/mobile/mobile_controls.dart';
import '../../ui/mobile/mobile_nav.dart';
import '../../ui/mobile/mobile_surfaces.dart';
import '../../ui/mobile/mobile_tokens.dart';

/// ============================================================
/// MOBILE SCREEN 1: "MY ROUTE TODAY"
/// Scope: One assigned route/zone for the on-ground field worker.
/// Answers: "I'm near a bus route right now — what needs my attention?"
/// ============================================================
class MobileRouteScreen extends StatelessWidget {
  const MobileRouteScreen({super.key, required this.onSwitchToVerify});

  final ValueChanged<DetectionEvent> onSwitchToVerify;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final routeIncidents = cc.mobileRouteIncidents;
    final urgent = routeIncidents
        .where((e) =>
            e.status == IncidentStatus.assigned || e.status == IncidentStatus.newAlert)
        .firstOrNull;

    final bottom = MDockBar.contentClearance(context, extra: 74);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(MSp.gutter, 14, MSp.gutter, bottom),
        children: [
          _ShiftHeaderCard(cc: cc),
          const SizedBox(height: 12),
          _ConnectivityStrip(cc: cc),
          if (urgent != null) ...[
            const SizedBox(height: 16),
            _UrgentAlertCard(event: urgent, onStart: () => onSwitchToVerify(urgent)),
          ],
          const SizedBox(height: 20),
          MSectionLabel(
            'CORRIDOR ALERTS',
            trailing: MPill(
              label: '${routeIncidents.length} OPEN',
              color: routeIncidents.isEmpty ? MSig.online : MSig.pending,
              dot: true,
              dense: true,
            ),
          ),
          const SizedBox(height: 12),
          if (routeIncidents.isEmpty)
            MEmptyState(
              title: 'CORRIDOR ALL CLEAR',
              message:
                  'No unverified road defects on this corridor. Edge cameras keep rolling surveillance.',
              color: MSig.online,
            )
          else
            for (final e in routeIncidents)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RouteAlertCard(event: e, onOpen: () => onSwitchToVerify(e)),
              ),
        ],
      ),
    );
  }
}

/// Shift header: who you are, where you are, and the route you can switch to.
class _ShiftHeaderCard extends StatelessWidget {
  const _ShiftHeaderCard({required this.cc});

  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final assigned = cc.mobileRouteIncidents
        .where((e) => e.status == IncidentStatus.assigned)
        .length;
    final verified = cc.mobileRouteIncidents
        .where((e) => e.status == IncidentStatus.verified)
        .length;
    final resolved = cc.myResolvedToday.length;

    return MCard(
      padding: EdgeInsets.zero,
      glowColor: MSig.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MRing(color: MSig.accent, glyph: DGlyph.route, size: 40, iconSize: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "TODAY'S PATROL",
                        style: MT.eyebrow(size: 9, color: Dp.textMuted, ls: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cc.mobileAssignedRoute,
                        style: MT.display(size: 20, color: Dp.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PMPML West Corridor · Unit FC-04',
                        style: MT.body(size: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SHIFT',
                      style: MT.eyebrow(size: 8.5, color: Dp.textFaint, ls: 1.3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _shiftClock(),
                      style: MT.data(size: 12, color: Dp.ink, w: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const MDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: MStat(value: '$assigned', label: 'ASSIGNED', color: MSig.assigned)),
                const MDivider(vertical: 30),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: MStat(value: '$verified', label: 'VERIFIED', color: MSig.verified),
                  ),
                ),
                const MDivider(vertical: 30),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: MStat(value: '$resolved', label: 'RESOLVED', color: MSig.resolved),
                  ),
                ),
              ],
            ),
          ),
          const MDivider(),
          // Route reassignment: a real chip row beats a squeezed dropdown.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Drishti.icon(DGlyph.target, size: 12, color: Dp.textFaint, stroke: 1.7),
                    const SizedBox(width: 6),
                    Text(
                      'SWITCH CORRIDOR',
                      style: MT.eyebrow(size: 9, color: Dp.textFaint, ls: 1.4),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in cc.availableRoutes)
                      MChip(
                        label: r,
                        dense: true,
                        selected: cc.mobileAssignedRoute == r,
                        icon: cc.mobileAssignedRoute == r ? DGlyph.check : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          cc.setMobileAssignedRoute(r);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shiftClock() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}';
  }
}

/// Connectivity + offline queue state, always one tap from the crew.
class _ConnectivityStrip extends StatelessWidget {
  const _ConnectivityStrip({required this.cc});

  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final offline = cc.isFieldOffline;
    final color = offline ? MSig.offline : MSig.online;
    final pending = cc.pendingSyncCount;

    return MCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderColor: color.withValues(alpha: Dp.isDark ? 0.32 : 0.24),
      child: Row(
        children: [
          Flexible(
            child: MTap(
              onTap: () {
                HapticFeedback.mediumImpact();
                cc.toggleFieldOffline();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 7, spreadRadius: 1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          offline ? 'OFFLINE BUFFER' : 'FIELD ONLINE',
                          style: MT.eyebrow(size: 9.5, color: color, ls: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offline ? 'Actions queue locally' : 'Municipal grid connected',
                          style: MT.caption(size: 10.5, color: Dp.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (pending > 0)
            MButton(
              label: 'SYNC $pending',
              icon: DGlyph.refresh,
              kind: MButtonKind.tonal,
              accent: MSig.pending,
              dense: true,
              expand: false,
              pill: true,
              onTap: () {
                HapticFeedback.heavyImpact();
                cc.syncOfflineQueue();
                showFieldToast(context, 'Offline queue flushed to command.', accent: MSig.pending);
              },
            )
          else
            MPill(
              label: 'IN SYNC',
              color: MSig.online,
              icon: DGlyph.check,
              dense: true,
            ),
        ],
      ),
    );
  }
}

/// The push-style "act now" card.
class _UrgentAlertCard extends StatelessWidget {
  const _UrgentAlertCard({required this.event, required this.onStart});

  final DetectionEvent event;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final sev = Dp.severityColor(event.severity);

    return MCard(
      padding: EdgeInsets.zero,
      accentEdge: sev,
      borderColor: sev.withValues(alpha: Dp.isDark ? 0.45 : 0.32),
      glowColor: sev,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              children: [
                MPill(label: 'ACT NOW', color: sev, icon: DGlyph.alert, dense: true, solid: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'New on-route alert',
                    style: MT.eyebrow(size: 9.5, color: Dp.textMuted, ls: 1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${event.ageMinutes}m ago',
                  style: MT.data(size: 9.5, color: Dp.textMuted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.kind.label,
                  style: MT.title(size: 17, color: Dp.ink),
                  maxLines: 2,
                ),
                const SizedBox(height: 5),
                Text(
                  event.kind.detail,
                  style: MT.body(size: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: MKeyValue(label: 'INCIDENT', value: '#${event.id}')),
                    const SizedBox(width: 10),
                    Expanded(child: MKeyValue(label: 'GPS', value: event.gpsLabel)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MKeyValue(
                        label: 'CONFIDENCE',
                        value: event.confLabel,
                        valueColor: MSig.verified,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    MPill(
                      label: event.status.label,
                      color: event.status.color,
                      dense: true,
                    ),
                    const SizedBox(width: 7),
                    MPill(label: event.severity.code, color: sev, dense: true),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Bus ${event.busId}',
                        style: MT.data(size: 9.5, color: Dp.textFaint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: MButton(
              label: 'Start on-site verification',
              icon: DGlyph.wrench,
              trailing: DGlyph.chevronRight,
              accent: sev,
              onTap: () {
                HapticFeedback.heavyImpact();
                onStart();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single corridor alert in the shift feed.
class _RouteAlertCard extends StatelessWidget {
  const _RouteAlertCard({required this.event, required this.onOpen});

  final DetectionEvent event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final resolved = event.status == IncidentStatus.resolved;
    final sev = Dp.severityColor(event.severity);

    return MCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MPill(
                label: event.status.label,
                color: event.status.color,
                dot: true,
                dense: true,
              ),
              const SizedBox(width: 6),
              MPill(label: event.severity.code, color: sev, dense: true),
              if (event.isManualFlag) ...[
                const SizedBox(width: 6),
                MPill(
                  label: 'MANUAL',
                  color: MSig.saffron,
                  icon: DGlyph.shield,
                  dense: true,
                ),
              ],
              const Spacer(),
              Text(event.timeShort, style: MT.data(size: 9.5, color: Dp.textFaint)),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            event.kind.label,
            style: MT.title(size: 14.5, color: Dp.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            event.kind.detail,
            style: MT.body(size: 11.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: MKeyValue(label: 'LOCATION', value: event.gpsLabel, dense: true),
              ),
              Expanded(
                flex: 3,
                child: MKeyValue(
                  label: 'SOURCE BUS',
                  value: event.busId,
                  dense: true,
                ),
              ),
              Expanded(
                flex: 3,
                child: MKeyValue(
                  label: 'ASSIGNED',
                  value: event.assignedCrew ?? 'Pending',
                  dense: true,
                ),
              ),
            ],
          ),
          if (event.resolutionNote != null) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: MSig.resolved.withValues(alpha: Dp.isDark ? 0.12 : 0.09),
                borderRadius: BorderRadius.circular(Dp.rSm),
                border: Border.all(color: MSig.resolved.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Drishti.icon(DGlyph.check, size: 12, color: MSig.resolved, stroke: 2.2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.resolutionNote!,
                      style: MT.caption(size: 11, color: MSig.resolved),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 13),
          MButton(
            label: resolved ? 'View closed ticket' : 'Verify & resolve',
            icon: resolved ? DGlyph.clipboard : DGlyph.wrench,
            trailing: DGlyph.chevronRight,
            kind: resolved ? MButtonKind.ghost : MButtonKind.tonal,
            accent: resolved ? MSig.resolved : MSig.accent,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpen();
            },
          ),
        ],
      ),
    );
  }
}

/// ManualFlagSheet — Human-in-the-Loop manual flagging from the road.
class ManualFlagSheet extends StatefulWidget {
  const ManualFlagSheet({super.key, required this.cc});

  final CommandCenter cc;

  @override
  State<ManualFlagSheet> createState() => _ManualFlagSheetState();
}

class _ManualFlagSheetState extends State<ManualFlagSheet> {
  DetectionKind _kind = DetectionKind.pothole;
  final _note = TextEditingController(text: 'Substantial asphalt crater in transit lane');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = widget.cc.isFieldOffline;

    return MSheetFrame(
      title: 'Human-in-the-loop flag',
      subtitle: 'You are the fallback sensor for anything the bus camera missed.',
      accent: MSig.saffron,
      icon: DGlyph.shield,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEFECT TYPE', style: MT.eyebrow(size: 9, color: Dp.textFaint, ls: 1.5)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in DetectionKind.values)
                MChip(
                  label: k.label,
                  dense: true,
                  selected: _kind == k,
                  accent: MSig.saffron,
                  icon: _kind == k ? DGlyph.check : null,
                  onTap: () => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('FIELD NOTE / SEVERITY OBSERVATION', style: MT.eyebrow(size: 9, color: Dp.textFaint, ls: 1.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 2,
            style: MT.body(size: 12.5, color: Dp.ink),
            cursorColor: MSig.accent,
            decoration: InputDecoration(
              filled: true,
              fillColor: Dp.field,
              contentPadding: const EdgeInsets.all(12),
              hintStyle: MT.body(size: 12.5, color: Dp.textFaint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dp.rSm),
                borderSide: BorderSide(color: Dp.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dp.rSm),
                borderSide: BorderSide(color: Dp.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dp.rSm),
                borderSide: BorderSide(color: MSig.accentRing, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Dp.canvas,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairlineSoft),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Drishti.icon(DGlyph.crosshair, size: 14, color: MSig.online, stroke: 1.8),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AUTO-CAPTURED GPS',
                        style: MT.eyebrow(size: 8.5, color: Dp.textFaint, ls: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '18.52040 N, 73.85670 E',
                        style: MT.data(size: 11, color: Dp.ink, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '±0.4 m NavIC · ${widget.cc.mobileAssignedRoute}',
                        style: MT.data(size: 9.5, color: Dp.textMuted, w: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MButton(
            label: offline ? 'Queue in offline buffer' : 'Transmit to command',
            icon: offline ? DGlyph.offlineCloud : DGlyph.check,
            accent: MSig.saffron,
            tall: true,
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.cc.addManualFlag(
                kind: _kind,
                note: _note.text.trim(),
                lat: 18.5204,
                lng: 73.8567,
                route: widget.cc.mobileAssignedRoute,
              );
              Navigator.of(context).pop();
              showFieldToast(
                context,
                offline
                    ? 'Defect queued in the local offline buffer.'
                    : 'Manual defect transmitted to City Command Center.',
                accent: MSig.saffron,
                icon: DGlyph.shield,
              );
            },
          ),
          if (offline) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Drishti.icon(DGlyph.offlineCloud, size: 13, color: MSig.offline, stroke: 1.7),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline: the flag will sync automatically when signal returns.',
                    style: MT.caption(size: 10.5, color: MSig.offline),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ============================================================
/// MOBILE SCREEN 2: "VERIFY & FIX WORKFLOW"
/// Scope: On-site verification & repair flow for field crew.
/// Answers: "How do I close the loop on this specific alert right now?"
/// ============================================================
class MobileVerifyScreen extends StatefulWidget {
  const MobileVerifyScreen({super.key, this.initialEvent});

  final DetectionEvent? initialEvent;

  @override
  State<MobileVerifyScreen> createState() => _MobileVerifyScreenState();
}

class _MobileVerifyScreenState extends State<MobileVerifyScreen> {
  DetectionEvent? _selected;
  String _remark = 'Cold-mix asphalt patch applied & tamped';
  bool _photo = false;

  static const _remarks = [
    'Cold-mix asphalt patch',
    'Bitumen crack sealed',
    'Sign reinstalled',
    'Debris removed',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialEvent;
  }

  @override
  void didUpdateWidget(MobileVerifyScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialEvent != null && widget.initialEvent?.id != _selected?.id) {
      setState(() => _selected = widget.initialEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final queue = cc.mobileRouteIncidents;
    final target = _selected ?? queue.firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          MSp.gutter,
          14,
          MSp.gutter,
          MDockBar.contentClearance(context),
        ),
        children: [
          _ScreenHeading(
            eyebrow: 'ON-SITE VERIFY & RESOLVE WORKFLOW',
            title: 'Verify & Fix',
            body: 'Close the loop in two or three tactile taps, standing at the road asset.',
            trailing: const GovBadge(label: 'SLA < 24H', dense: true),
          ),
          const SizedBox(height: 18),
          MSectionLabel(
            'WORK QUEUE',
            trailing: MPill(
              label: '${queue.length} ITEM${queue.length == 1 ? '' : 'S'}',
              color: queue.isEmpty ? MSig.online : MSig.assigned,
              dense: true,
            ),
          ),
          const SizedBox(height: 10),
          if (queue.isEmpty)
            MEmptyState(
              title: 'NO ACTIVE REPAIR QUEUE',
              message: 'Assign a corridor from My Route — alerts will appear here instantly.',
              color: MSig.online,
              compact: true,
            )
          else
            _QueueStrip(
              queue: queue,
              selectedId: target?.id,
              onSelect: (e) => setState(() => _selected = e),
            ),
          if (target != null) ...[
            const SizedBox(height: 20),
            _StepCard(
              step: 1,
              color: MSig.info,
              title: 'AI detection preview',
              body: 'Confirm the on-ground asset matches the edge-AI classification.',
              child: _EvidenceFrame(event: target),
            ),
            const SizedBox(height: 14),
            _StepCard(
              step: 2,
              color: MSig.verified,
              title: 'On-site inspection',
              body: 'Confirm the defect visually, or reject it as a false positive.',
              done: target.status == IncidentStatus.verified ||
                  target.status == IncidentStatus.resolved,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (target.verifyVerdict != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                      decoration: BoxDecoration(
                        color: MSig.verified.withValues(alpha: Dp.isDark ? 0.13 : 0.09),
                        borderRadius: BorderRadius.circular(Dp.rSm),
                        border: Border.all(
                          color: MSig.verified.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Text(
                        target.verifyVerdict!,
                        style: MT.caption(size: 11.5, color: MSig.verified),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: MButton(
                          label: 'Confirmed',
                          icon: DGlyph.check,
                          kind: MButtonKind.success,
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            cc.verifyIncident(target.id, confirmed: true);
                            showFieldToast(
                              context,
                              'Alert #${target.id} verified as a confirmed defect.',
                              accent: MSig.resolved,
                              icon: DGlyph.check,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MButton(
                          label: 'False positive',
                          icon: DGlyph.chevronLeft,
                          kind: MButtonKind.ghost,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            cc.verifyIncident(target.id, confirmed: false);
                            showFieldToast(
                              context,
                              'Alert #${target.id} rejected as a false positive.',
                              accent: MSig.pending,
                              icon: DGlyph.info,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _StepCard(
              step: 3,
              color: MSig.resolved,
              title: 'Repair & close out',
              body: 'Record the repair action and attach proof to seal the work order.',
              done: target.status == IncidentStatus.resolved,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REPAIR ACTION', style: MT.eyebrow(size: 9, color: Dp.textFaint, ls: 1.5)),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in _remarks)
                        MChip(
                          label: r,
                          dense: true,
                          selected: _remark == r,
                          accent: MSig.resolved,
                          icon: _remark == r ? DGlyph.check : null,
                          onTap: () => setState(() => _remark = r),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MTap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _photo = !_photo);
                    },
                    child: AnimatedContainer(
                      duration: Mo.fast,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Dp.field,
                        borderRadius: BorderRadius.circular(Dp.rSm),
                        border: Border.all(
                          color: _photo ? MSig.resolved : Dp.hairline,
                          width: _photo ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Drishti.icon(
                            _photo ? DGlyph.check : DGlyph.camera,
                            size: 15,
                            color: _photo ? MSig.resolved : Dp.textMuted,
                            stroke: 1.9,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _photo
                                  ? 'Proof attached · repair_photo_01.jpg'
                                  : 'Attach repair proof photo (optional)',
                              style: MT.caption(
                                size: 11.5,
                                color: _photo ? MSig.resolved : Dp.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MButton(
                    label: target.status == IncidentStatus.resolved
                        ? 'Repair already recorded'
                        : 'Mark repaired & close ticket',
                    icon: DGlyph.check,
                    kind: target.status == IncidentStatus.resolved
                        ? MButtonKind.ghost
                        : MButtonKind.success,
                    accent: MSig.resolved,
                    tall: true,
                    enabled: target.status != IncidentStatus.resolved,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      cc.resolveIncident(target.id, remark: _remark);
                      showFieldToast(
                        context,
                        'Ticket #${target.id} resolved and logged into My Work.',
                        accent: MSig.resolved,
                        icon: DGlyph.check,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Horizontal work-queue selector so the crew can move between alerts in place.
class _QueueStrip extends StatelessWidget {
  const _QueueStrip({
    required this.queue,
    required this.selectedId,
    required this.onSelect,
  });

  final List<DetectionEvent> queue;
  final String? selectedId;
  final ValueChanged<DetectionEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: queue.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final e = queue[i];
          final sel = e.id == selectedId;
          final sev = Dp.severityColor(e.severity);
          return MTap(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(e);
            },
            child: AnimatedContainer(
              duration: Mo.fast,
              curve: Mo.easeTech,
              width: 168,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: sel ? sev.withValues(alpha: Dp.isDark ? 0.14 : 0.10) : Dp.card,
                borderRadius: BorderRadius.circular(Dp.rSm),
                border: Border.all(
                  color: sel ? sev.withValues(alpha: 0.6) : Dp.hairline,
                  width: sel ? 1.4 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: sev, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '#${e.id}',
                          style: MT.data(size: 9.5, color: Dp.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(e.timeShort, style: MT.data(size: 9, color: Dp.textFaint)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    e.kind.label,
                    style: MT.title(size: 12.5, color: sel ? Dp.ink : Dp.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    e.status.label,
                    style: MT.eyebrow(size: 8.5, color: e.status.color, ls: 1.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EvidenceFrame extends StatelessWidget {
  const _EvidenceFrame({required this.event});

  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final sev = Dp.severityColor(event.severity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dp.rSm),
          child: Container(
            height: 168,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/drishti.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF0F172A)),
                ),
                Container(color: Colors.black.withValues(alpha: 0.42)),
                // Simulated AI bounding box
                Positioned(
                  left: 30,
                  top: 24,
                  right: 44,
                  bottom: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: sev, width: 2),
                      color: sev.withValues(alpha: 0.12),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        color: sev,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          '${event.kind.code} · ${event.confLabel}',
                          style: MT.eyebrow(
                            size: 8.5,
                            color: MSig.onColor(sev),
                            ls: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: MPill(
                    label: 'EDGE FRAME ${event.timeLabel}',
                    color: Colors.white,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: MKeyValue(label: 'INCIDENT', value: '#${event.id}')),
            Expanded(flex: 4, child: MKeyValue(label: 'GPS', value: event.gpsLabel)),
            Expanded(flex: 3, child: MKeyValue(label: 'BUS', value: event.busId)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            MPill(label: event.status.label, color: event.status.color, dot: true, dense: true),
            const SizedBox(width: 7),
            MPill(label: event.severity.label.toUpperCase(), color: sev, dense: true),
          ],
        ),
      ],
    );
  }
}

/// A numbered workflow step with a title, a sentence of guidance, and content.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.color,
    required this.title,
    required this.body,
    required this.child,
    this.done = false,
  });

  final int step;
  final Color color;
  final String title;
  final String body;
  final Widget child;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return MCard(
      padding: EdgeInsets.zero,
      borderColor: done ? color.withValues(alpha: 0.4) : Dp.hairline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MStepBadge(index: step, color: color, done: done),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: MT.title(size: 14.5, color: Dp.ink)),
                      const SizedBox(height: 4),
                      Text(body, style: MT.body(size: 11.5)),
                    ],
                  ),
                ),
                if (done) ...[
                  const SizedBox(width: 8),
                  MPill(label: 'DONE', color: color, icon: DGlyph.check, dense: true, solid: true),
                ],
              ],
            ),
          ),
          const MDivider(),
          Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 14), child: child),
        ],
      ),
    );
  }
}

/// Shared mobile screen heading: eyebrow, Fraunces title, one-line guidance.
class _ScreenHeading extends StatelessWidget {
  const _ScreenHeading({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eyebrow, style: MT.eyebrow(size: 9, color: MSig.accent, ls: 1.6)),
              const SizedBox(height: 6),
              Text(title, style: MT.display(size: 22, color: Dp.ink)),
              const SizedBox(height: 5),
              Text(body, style: MT.body(size: 12)),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Padding(padding: const EdgeInsets.only(top: 2), child: trailing!),
        ],
      ],
    );
  }
}

/// ============================================================
/// MOBILE SCREEN 3: "MY WORK TODAY"
/// Scope: Personal activity log showing field worker's closed tasks.
/// Answers: "What did I accomplish today?"
/// ============================================================
class MobileLogScreen extends StatelessWidget {
  const MobileLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final done = cc.myResolvedToday;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          MSp.gutter,
          14,
          MSp.gutter,
          MDockBar.contentClearance(context),
        ),
        children: [
          const _ScreenHeading(
            eyebrow: 'PERSONAL SHIFT RECORD',
            title: 'My Work',
            body: 'Every defect you closed today, with the audit trail command sees.',
            trailing: GovBadge(label: 'FC-04', dense: true),
          ),
          const SizedBox(height: 18),
          MCard(
            padding: EdgeInsets.zero,
            borderColor: MSig.resolved.withValues(alpha: Dp.isDark ? 0.4 : 0.28),
            glowColor: MSig.resolved,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
                  child: Row(
                    children: [
                      AshokaChakra(size: 16, color: MSig.resolved),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'MY ACTIVITY LOG · FIELD CREW 04',
                          style: MT.eyebrow(size: 9.5, color: MSig.resolved, ls: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      MPill(label: 'SLA MET', color: MSig.resolved, icon: DGlyph.check, dense: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const MDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MStat(
                          value: '${done.length}',
                          label: 'RESOLVED TODAY',
                          color: MSig.resolved,
                          caption: 'tickets closed',
                        ),
                      ),
                      const MDivider(vertical: 32),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: MStat(
                            value: '< 3.2h',
                            label: 'AVG CYCLE TIME',
                            color: MSig.info,
                            caption: 'detect → close',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MSectionLabel(
            'COMPLETED REPAIR AUDIT TRAIL',
            trailing: MPill(
              label: '${done.length} ENTRY${done.length == 1 ? '' : 'IES'}',
              color: done.isEmpty ? Dp.textMuted : MSig.resolved,
              dense: true,
            ),
          ),
          const SizedBox(height: 12),
          if (done.isEmpty)
            MEmptyState(
              title: 'NOTHING CLOSED YET',
              message: 'Tickets you resolve in Verify & Fix land here with a timestamp.',
              color: MSig.assigned,
            )
          else
            for (final e in done)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AuditRow(event: e),
              ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.event});

  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    return MCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      radius: Dp.rSm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: MSig.resolved.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: MSig.resolved.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Drishti.icon(DGlyph.check, size: 14, color: MSig.resolved, stroke: 2.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.kind.label,
                  style: MT.title(size: 13, color: Dp.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  event.resolutionNote ?? 'Patched & sealed',
                  style: MT.caption(size: 11, color: MSig.resolved),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '#${event.id}  ·  ${event.busRoute}',
                        style: MT.data(size: 9.5, color: Dp.textFaint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.resolvedAt != null
                          ? _clockOf(event.resolvedAt!)
                          : event.timeShort,
                      style: MT.data(size: 9.5, color: MSig.resolved, w: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _clockOf(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}
