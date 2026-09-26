import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/palette.dart';
import '../../app/typography.dart';
import '../../core/command_center.dart';
import '../../core/models.dart';
import '../../ui/chrome.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/tactile.dart';

/// ============================================================
/// MOBILE SCREEN 1: "MY ROUTE TODAY"
/// Scope: One assigned route/zone for the on-ground field worker.
/// Answers: "I'm near a bus route right now — what needs my attention?"
/// ============================================================
class MobileRouteScreen extends StatelessWidget {
  const MobileRouteScreen({
    super.key,
    required this.onSwitchToVerify,
  });

  final ValueChanged<DetectionEvent> onSwitchToVerify;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final routeIncidents = cc.mobileRouteIncidents;
    final urgentAlert = routeIncidents.where((e) => e.status == IncidentStatus.assigned || e.status == IncidentStatus.newAlert).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.black,
        elevation: 6,
        icon: Drishti.icon(DGlyph.shield, size: 16, color: Colors.black),
        label: Text(
          'FLAG DEFECT',
          style: monoTxt(11, color: Colors.black, w: FontWeight.w800, ls: 0.6),
        ),
        onPressed: () => _openManualFlagModal(context, cc),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Field Controls: Route Selector & Offline Tolerance Bar
            _buildRouteAndOfflineBar(context, cc),
            const SizedBox(height: 12),

            // Push-Style Live Alert Notification ("Needs Attention Right Now")
            if (urgentAlert != null) ...[
              _buildPushAlertBanner(context, urgentAlert),
              const SizedBox(height: 14),
            ],

            // Assigned Route Summary Cards
            _buildRouteSummaryCards(cc, routeIncidents),
            const SizedBox(height: 18),

            // Active Route Incidents Header
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Dp.accent,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${cc.mobileAssignedRoute} CORRIDOR ALERTS',
                  style: monoTxt(10.5, color: Dp.textMuted, w: FontWeight.w700, ls: 0.8),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Dp.field,
                    borderRadius: BorderRadius.circular(Dp.rFull),
                    border: Border.all(color: Dp.hairline),
                  ),
                  child: Text(
                    '${routeIncidents.length} TOTAL',
                    style: monoTxt(9, color: Dp.ink, w: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Route Alerts Feed
            if (routeIncidents.isEmpty)
              _buildEmptyRouteCard(cc)
            else
              for (final e in routeIncidents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRouteAlertCard(context, e),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteAndOfflineBar(BuildContext context, CommandCenter cc) {
    final isDark = Dp.isDark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Drishti.icon(DGlyph.route, size: 16, color: Dp.accent),
              const SizedBox(width: 8),
              Text(
                'ASSIGNED ROUTE:',
                style: monoTxt(9.5, color: Dp.textMuted, w: FontWeight.w700, ls: 0.5),
              ),
              const Spacer(),
              // Route Switcher Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF142036) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(Dp.rSm),
                  border: Border.all(color: isDark ? const Color(0xFF2C4166) : const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: cc.mobileAssignedRoute,
                    isDense: true,
                    dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    icon: Icon(Icons.arrow_drop_down, size: 18, color: Dp.accent),
                    style: monoTxt(11, color: Dp.ink, w: FontWeight.w800),
                    items: cc.availableRoutes.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        cc.setMobileAssignedRoute(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, width: double.infinity, color: Dp.hairline),
          const SizedBox(height: 10),
          // Offline-Tolerant Connectivity Toggle & Pending Sync Badge
          Row(
            children: [
              Tactile(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  cc.toggleFieldOffline();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cc.isFieldOffline
                        ? const Color(0xFFE53935).withValues(alpha: 0.15)
                        : const Color(0xFF138808).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Dp.rFull),
                    border: Border.all(
                      color: cc.isFieldOffline ? const Color(0xFFE53935) : const Color(0xFF138808),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cc.isFieldOffline ? const Color(0xFFE53935) : const Color(0xFF138808),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        cc.isFieldOffline ? 'OFFLINE BUFFER (GHAT)' : 'FIELD ONLINE',
                        style: monoTxt(8.5, color: cc.isFieldOffline ? const Color(0xFFE53935) : const Color(0xFF138808), w: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (cc.pendingSyncCount > 0) ...[
                Tactile(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    cc.syncOfflineQueue();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9933).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(Dp.rFull),
                      border: Border.all(color: const Color(0xFFFF9933)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, size: 12, color: Color(0xFFFF9933)),
                        const SizedBox(width: 4),
                        Text(
                          '${cc.pendingSyncCount} PENDING SYNC',
                          style: monoTxt(8.5, color: const Color(0xFFFF9933), w: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Text(
                  'ALL LOCAL ACTIONS SYNCED',
                  style: monoTxt(8, color: Dp.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPushAlertBanner(BuildContext context, DetectionEvent e) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9933).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: const Color(0xFFFF9933), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9933).withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9933),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high, size: 14, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NEW ON-ROUTE ALERT · IMMEDIATE ACTION',
                  style: monoTxt(10, color: const Color(0xFFFF9933), w: FontWeight.w800, ls: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SeverityTag(e.severity, size: 9),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${e.kind.label.toUpperCase()} · LOCATED ON ${e.busRoute}',
            style: AppText.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            'GPS ${e.gpsLabel} · Reported by transit bus ${e.busId} (${e.confLabel} AI Confidence)',
            style: monoTxt(9, color: Dp.textMuted),
          ),
          const SizedBox(height: 12),
          TactileButton(
            label: 'START ON-SITE VERIFICATION & RESOLVE',
            icon: DGlyph.wrench,
            accent: const Color(0xFFFF9933),
            dense: true,
            expanded: true,
            onTap: () {
              HapticFeedback.heavyImpact();
              onSwitchToVerify(e);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummaryCards(CommandCenter cc, List<DetectionEvent> list) {
    final assignedCount = list.where((e) => e.status == IncidentStatus.assigned).length;
    final verifiedCount = list.where((e) => e.status == IncidentStatus.verified).length;
    final resolvedTodayCount = cc.myResolvedToday.length;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Dp.card,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: StatBlock(
              number: '$assignedCount',
              label: 'ASSIGNED',
              color: const Color(0xFF38BDF8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Dp.card,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: StatBlock(
              number: '$verifiedCount',
              label: 'VERIFIED',
              color: const Color(0xFFA855F7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Dp.card,
              borderRadius: BorderRadius.circular(Dp.rSm),
              border: Border.all(color: Dp.hairline),
            ),
            child: StatBlock(
              number: '$resolvedTodayCount',
              label: 'RESOLVED',
              color: const Color(0xFF10B981),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteAlertCard(BuildContext context, DetectionEvent e) {
    final statusColor = e.status.color;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  e.status.label,
                  style: monoTxt(8.5, color: statusColor, w: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              SeverityTag(e.severity, size: 8),
              if (e.isManualFlag) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9933).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'MANUAL FLAG',
                    style: monoTxt(7.5, color: const Color(0xFFFF9933), w: FontWeight.w800),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                e.timeShort,
                style: monoTxt(9, color: Dp.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            e.kind.label.toUpperCase(),
            style: AppText.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'GPS: ${e.gpsLabel} · Bus ${e.busId} · Assigned: ${e.assignedCrew ?? 'Pending Dispatch'}',
            style: monoTxt(8.5, color: Dp.textMuted),
          ),
          if (e.resolutionNote != null) ...[
            const SizedBox(height: 4),
            Text(
              'Resolution: ${e.resolutionNote}',
              style: monoTxt(8.5, color: const Color(0xFF10B981), w: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TactileButton(
                  label: e.status == IncidentStatus.resolved ? 'VIEW CLOSED TICKET' : 'VERIFY & RESOLVE FLOW',
                  icon: DGlyph.wrench,
                  accent: e.status == IncidentStatus.resolved ? const Color(0xFF10B981) : Dp.accent,
                  dense: true,
                  outline: e.status == IncidentStatus.resolved,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSwitchToVerify(e);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRouteCard(CommandCenter cc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Center(
        child: Column(
          children: [
            const AshokaChakra(size: 24, color: Color(0xFF138808)),
            const SizedBox(height: 10),
            Text(
              'CORRIDOR ALL CLEAR',
              style: monoTxt(11, color: const Color(0xFF138808), w: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'No unverified road defects on ${cc.mobileAssignedRoute}. Edge cameras continue rolling surveillance.',
              textAlign: TextAlign.center,
              style: monoTxt(9, color: Dp.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _openManualFlagModal(BuildContext context, CommandCenter cc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualFlagSheet(cc: cc),
    );
  }
}

/// Modal Sheet: Human-in-the-Loop Manual Flagging
class _ManualFlagSheet extends StatefulWidget {
  const _ManualFlagSheet({required this.cc});
  final CommandCenter cc;

  @override
  State<_ManualFlagSheet> createState() => _ManualFlagSheetState();
}

class _ManualFlagSheetState extends State<_ManualFlagSheet> {
  DetectionKind _selectedKind = DetectionKind.pothole;
  final TextEditingController _noteCtrl = TextEditingController(text: 'Substantial asphalt crater in transit lane');

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090E17) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dp.rLg)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFCBD5E1),
            width: 1.4,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C3E5E) : const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(Dp.rFull),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Drishti.icon(DGlyph.shield, size: 16, color: const Color(0xFFFF9933)),
              const SizedBox(width: 8),
              Text(
                'HUMAN-IN-THE-LOOP · MANUAL FLAG',
                style: monoTxt(11, color: const Color(0xFFFF9933), w: FontWeight.w800, ls: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Field worker acting as fallback sensor for defect missed by bus camera.',
            style: monoTxt(8.5, color: Dp.textMuted),
          ),
          const SizedBox(height: 14),
          Text('SELECT DEFECT TYPE', style: monoTxt(9.5, color: Dp.textMuted, w: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DetectionKind.values.map((k) {
              final sel = _selectedKind == k;
              return Tactile(
                onTap: () => setState(() => _selectedKind = k),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFF9933).withValues(alpha: 0.2) : Dp.card,
                    borderRadius: BorderRadius.circular(Dp.rSm),
                    border: Border.all(
                      color: sel ? const Color(0xFFFF9933) : Dp.hairline,
                      width: sel ? 1.4 : 1.0,
                    ),
                  ),
                  child: Text(
                    k.label.toUpperCase(),
                    style: monoTxt(9, color: sel ? const Color(0xFFFF9933) : Dp.ink, w: FontWeight.w700),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('FIELD NOTE / SEVERITY OBSERVATION', style: monoTxt(9.5, color: Dp.textMuted, w: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            style: monoTxt(11, color: Dp.ink),
            decoration: InputDecoration(
              filled: true,
              fillColor: Dp.field,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dp.rSm), borderSide: BorderSide(color: Dp.hairline)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Dp.field,
              borderRadius: BorderRadius.circular(Dp.rSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, size: 14, color: Color(0xFF138808)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AUTO-CAPTURED GPS: 18.5204° N, 73.8567° E (±0.4m NavIC)\nROUTE: ${widget.cc.mobileAssignedRoute}',
                    style: monoTxt(8.5, color: Dp.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TactileButton(
            label: widget.cc.isFieldOffline ? 'QUEUE OFFLINE (BUFFER UNTIL SYNC)' : 'TRANSMIT MANUAL FLAG TO COMMAND',
            icon: DGlyph.check,
            accent: const Color(0xFFFF9933),
            expanded: true,
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.cc.addManualFlag(
                kind: _selectedKind,
                note: _noteCtrl.text.trim(),
                lat: 18.5204,
                lng: 73.8567,
                route: widget.cc.mobileAssignedRoute,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.cc.isFieldOffline
                        ? 'Manual defect queued in local offline buffer.'
                        : 'Manual defect transmitted to City Command Center.',
                    style: monoTxt(10.5, color: Colors.white),
                  ),
                ),
              );
            },
          ),
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
  const MobileVerifyScreen({
    super.key,
    this.initialEvent,
  });

  final DetectionEvent? initialEvent;

  @override
  State<MobileVerifyScreen> createState() => _MobileVerifyScreenState();
}

class _MobileVerifyScreenState extends State<MobileVerifyScreen> {
  DetectionEvent? _selectedEvent;
  String _repairRemark = 'Cold-mix asphalt patch applied & tamped';
  bool _photoAttached = false;

  @override
  void initState() {
    super.initState();
    _selectedEvent = widget.initialEvent;
  }

  @override
  void didUpdateWidget(MobileVerifyScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialEvent != null && widget.initialEvent?.id != _selectedEvent?.id) {
      setState(() => _selectedEvent = widget.initialEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final routeAlerts = cc.mobileRouteIncidents;

    final target = _selectedEvent ?? routeAlerts.firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Drishti.icon(DGlyph.wrench, size: 16, color: Dp.accent),
                const SizedBox(width: 8),
                Text(
                  'ON-SITE VERIFY & RESOLVE WORKFLOW',
                  style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w800, ls: 0.6),
                ),
                const Spacer(),
                const GovBadge(label: 'SLA < 24H', dense: true),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Close the inspection cycle in 2-3 tactile taps directly at the road asset.',
              style: monoTxt(8.5, color: Dp.textMuted),
            ),
            const SizedBox(height: 14),

            if (target == null)
              _buildNoTargetView()
            else ...[
              // Step 1: AI Evidence Frame with Bounding Box
              _buildAiEvidenceCard(target),
              const SizedBox(height: 14),

              // Step 2: On-site Confirm vs False Positive
              _buildStepTwoConfirm(context, cc, target),
              const SizedBox(height: 14),

              // Step 3: Mark Repaired and Resolve
              _buildStepThreeResolve(context, cc, target),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiEvidenceCard(DetectionEvent target) {
    return Container(
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('STEP 1: AI DETECTION PREVIEW', style: monoTxt(8.5, color: const Color(0xFF38BDF8), w: FontWeight.w800)),
                ),
                const Spacer(),
                SeverityTag(target.severity, size: 9),
              ],
            ),
          ),
          // Synthetic / Real Evidence Canvas with Bounding Box
          Container(
            height: 160,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/dristhi.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                // Simulated AI Bounding Box
                Positioned(
                  left: 36,
                  top: 28,
                  right: 50,
                  bottom: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFF9933), width: 2.0),
                      color: const Color(0xFFFF9933).withValues(alpha: 0.12),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        color: const Color(0xFFFF9933),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        child: Text(
                          '${target.kind.label.toUpperCase()} · ${target.confLabel}',
                          style: monoTxt(8, color: Colors.black, w: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INCIDENT #${target.id} · ${target.kind.label.toUpperCase()}',
                  style: AppText.label.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'GPS: ${target.gpsLabel} · Bus: ${target.busId} on ${target.busRoute}',
                  style: monoTxt(9, color: Dp.textMuted),
                ),
                if (target.verifyVerdict != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Field Status: ${target.verifyVerdict}',
                    style: monoTxt(9, color: const Color(0xFFA855F7), w: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwoConfirm(BuildContext context, CommandCenter cc, DetectionEvent target) {
    final isVerified = target.status == IncidentStatus.verified || target.status == IncidentStatus.resolved;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('STEP 2: ON-SITE INSPECTION', style: monoTxt(8.5, color: const Color(0xFFA855F7), w: FontWeight.w800)),
              ),
              const Spacer(),
              if (isVerified)
                Text('COMPLETED', style: monoTxt(8.5, color: const Color(0xFF10B981), w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Confirm if the defect visually matches the edge-AI classification.',
            style: monoTxt(9, color: Dp.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TactileButton(
                  label: 'CONFIRMED MATCHES',
                  icon: DGlyph.check,
                  accent: const Color(0xFF10B981),
                  dense: true,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    cc.verifyIncident(target.id, confirmed: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Alert #${target.id} verified as confirmed defect.', style: monoTxt(10.5, color: Colors.white))),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TactileButton(
                  label: 'FALSE POSITIVE',
                  outline: true,
                  dense: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    cc.verifyIncident(target.id, confirmed: false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Alert #${target.id} rejected as false positive.', style: monoTxt(10.5, color: Colors.white))),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepThreeResolve(BuildContext context, CommandCenter cc, DetectionEvent target) {
    final isResolved = target.status == IncidentStatus.resolved;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: isResolved ? const Color(0xFF10B981) : Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('STEP 3: REPAIR & CLOSE OUT', style: monoTxt(8.5, color: const Color(0xFF10B981), w: FontWeight.w800)),
              ),
              const Spacer(),
              if (isResolved)
                Text('RESOLVED ✅', style: monoTxt(9, color: const Color(0xFF10B981), w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Select repair action and attach evidence photo to seal work order.',
            style: monoTxt(9, color: Dp.textMuted),
          ),
          const SizedBox(height: 10),
          // Quick Remark Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'Cold-mix asphalt patch',
              'Bitumen crack sealed',
              'Sign reinstalled',
              'Debris removed',
            ].map((remark) {
              final sel = _repairRemark == remark;
              return Tactile(
                onTap: () => setState(() => _repairRemark = remark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF10B981).withValues(alpha: 0.18) : Dp.field,
                    borderRadius: BorderRadius.circular(Dp.rSm),
                    border: Border.all(color: sel ? const Color(0xFF10B981) : Dp.hairline),
                  ),
                  child: Text(remark, style: monoTxt(8.5, color: sel ? const Color(0xFF10B981) : Dp.inkSoft, w: FontWeight.w700)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Photo proof attachment simulation
          Tactile(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _photoAttached = !_photoAttached);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Dp.field,
                borderRadius: BorderRadius.circular(Dp.rSm),
                border: Border.all(color: _photoAttached ? const Color(0xFF10B981) : Dp.hairline),
              ),
              child: Row(
                children: [
                  Icon(_photoAttached ? Icons.check_circle : Icons.camera_alt, size: 14, color: _photoAttached ? const Color(0xFF10B981) : Dp.accent),
                  const SizedBox(width: 8),
                  Text(
                    _photoAttached ? 'PROOF ATTACHED: repair_photo_01.jpg' : 'ATTACH REPAIR PROOF PHOTO (OPTIONAL)',
                    style: monoTxt(9, color: _photoAttached ? const Color(0xFF10B981) : Dp.textMuted, w: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TactileButton(
            label: isResolved ? 'REPAIR ALREADY RECORDED' : 'MARK REPAIRED & CLOSE TICKET',
            icon: DGlyph.check,
            accent: const Color(0xFF10B981),
            expanded: true,
            onTap: () {
              HapticFeedback.heavyImpact();
              cc.resolveIncident(target.id, remark: _repairRemark);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text('Ticket #${target.id} marked RESOLVED! Logged into My Work Today.', style: monoTxt(10.5, color: Colors.white, w: FontWeight.w700)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoTargetView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline),
      ),
      child: Center(
        child: Column(
          children: [
            const AshokaChakra(size: 24, color: Color(0xFF138808)),
            const SizedBox(height: 10),
            Text('NO ACTIVE REPAIR QUEUE', style: monoTxt(11, color: const Color(0xFF138808), w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Select an incident from "My Route" to begin on-site verification.', style: monoTxt(9, color: Dp.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// MOBILE SCREEN 3: "MY LOG TODAY"
/// Scope: Personal activity log showing field worker's closed tasks.
/// Answers: "What did I accomplish today?"
/// ============================================================
class MobileLogScreen extends StatelessWidget {
  const MobileLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final resolvedList = cc.myResolvedToday;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Productivity Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Dp.card,
                borderRadius: BorderRadius.circular(Dp.rMd),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AshokaChakra(size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'MY ACTIVITY LOG · FIELD CREW 04',
                        style: monoTxt(10.5, color: const Color(0xFF10B981), w: FontWeight.w800, ls: 0.6),
                      ),
                      const Spacer(),
                      Text('SLA PASSED', style: monoTxt(8.5, color: const Color(0xFF10B981), w: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatBlock(
                          number: '${resolvedList.length}',
                          label: 'RESOLVED TODAY',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Container(width: 1, height: 36, color: Dp.hairline),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: StatBlock(
                            number: '< 3.2h',
                            label: 'AVG CYCLE TIME',
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'COMPLETED REPAIR AUDIT TRAIL',
              style: monoTxt(10, color: Dp.textMuted, w: FontWeight.w700, ls: 0.8),
            ),
            const SizedBox(height: 10),

            if (resolvedList.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Dp.card,
                  borderRadius: BorderRadius.circular(Dp.rSm),
                  border: Border.all(color: Dp.hairline),
                ),
                child: Center(
                  child: Text(
                    'No repairs completed yet today. Items resolved in "Verify & Fix" will appear here.',
                    textAlign: TextAlign.center,
                    style: monoTxt(9, color: Dp.textMuted),
                  ),
                ),
              )
            else
              for (final e in resolvedList)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Dp.card,
                      borderRadius: BorderRadius.circular(Dp.rSm),
                      border: Border.all(color: Dp.hairline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.kind.label.toUpperCase()} #${e.id}',
                                style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w700),
                              ),
                              Text(
                                '${e.resolutionNote ?? 'Patched & sealed'} · Route ${e.busRoute}',
                                style: monoTxt(8.5, color: Dp.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          e.resolvedAt != null ? '${e.resolvedAt!.hour}:${e.resolvedAt!.minute.toString().padLeft(2, '0')}' : e.timeShort,
                          style: monoTxt(9, color: const Color(0xFF10B981), w: FontWeight.w700),
                        ),
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
