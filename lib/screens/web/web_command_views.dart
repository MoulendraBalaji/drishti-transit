import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/motion.dart';
import '../../app/palette.dart';
import '../../app/typography.dart';
import '../../core/command_center.dart';
import '../../core/models.dart';
import '../../core/sim.dart';
import '../../ui/chrome.dart';
import '../../ui/glyphs.dart';
import '../../ui/gov_masthead.dart';
import '../../ui/map_overlays.dart';
import '../../ui/tactile.dart';

/// ============================================================
/// WEB VIEW 1: CITY-WIDE LIVE MAP
/// Scope: The WHOLE fleet, ALL routes, aggregated in one situational view.
/// Answers: "Where are the problems across Pune, and how severe are they?"
/// ============================================================
class WebCityMapView extends StatefulWidget {
  const WebCityMapView({super.key});

  @override
  State<WebCityMapView> createState() => _WebCityMapViewState();
}

class _WebCityMapViewState extends State<WebCityMapView> {
  final MapController _map = MapController();
  DetectionEvent? _inspectingEvent;

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = cc.isDarkMode;
    final corridors = SimWorld.corridors();

    return Stack(
      children: [
        // Live OpenStreetMap with Fleet Bus Markers & Defect Pins
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: const LatLng(SimWorld.cityLat, SimWorld.cityLng),
            initialZoom: 12.8,
            minZoom: 10,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            backgroundColor: isDark ? const Color(0xFF090E17) : const Color(0xFFE2E8F0),
          ),
          children: [
            TileLayer(
              key: ValueKey(isDark ? 'osm_dark_web' : 'osm_light_web'),
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'in.drishti.transit',
              maxZoom: 19,
            ),
            if (cc.showCorridors)
              PolylineLayer(
                polylines: [
                  for (var i = 0; i < corridors.length; i++)
                    Polyline(
                      points: [
                        for (final (lat, lng) in corridors[i].geo)
                          LatLng(lat, lng),
                      ],
                      color: isDark
                          ? Dp.accent.withValues(alpha: 0.45 + (i % 3) * 0.10)
                          : const Color(0xFF0284C7).withValues(alpha: 0.55 + (i % 3) * 0.10),
                      strokeWidth: 3.5,
                    ),
                ],
              ),
            ValueListenableBuilder<List<Bus>>(
              valueListenable: cc.busPositions,
              builder: (context, buses, _) => MarkerLayer(
                markers: [
                  for (final b in buses)
                    Marker(
                      point: LatLng(b.lat, b.lng),
                      width: b.hero ? 40 : 32,
                      height: b.hero ? 40 : 32,
                      child: BusMarker(bus: b),
                    ),
                ],
              ),
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < cc.incidents.length; i++)
                  Marker(
                    point: LatLng(cc.incidents[i].lat, cc.incidents[i].lng),
                    width: 52,
                    height: 60,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _inspectingEvent = cc.incidents[i]);
                      },
                      child: IncidentPin(
                        event: cc.incidents[i],
                        newest: i == 0,
                      ),
                    ),
                  ),
              ],
            ),
            if (cc.showHeatmap) HeatOverlay(points: cc.heatPoints),
            RippleLayer(ripples: cc.ripples),
          ],
        ),

        // Top Command HUD
        Positioned(
          top: 14,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1526).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(Dp.rSm),
                      border: Border.all(color: Dp.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AshokaChakra(size: 14, color: Color(0xFF000080)),
                        const SizedBox(width: 8),
                        Text(
                          'CITY-WIDE COMMAND & CONTROL · 8 CORRIDORS',
                          style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w800, ls: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 16, color: Dp.hairline),
                        const SizedBox(width: 12),
                        Text(
                          '${cc.busesOnline} BUSES STREAMING AIS-140',
                          style: monoTxt(9.5, color: const Color(0xFF138808), w: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${cc.total} TOTAL DEFECTS',
                          style: monoTxt(9.5, color: const Color(0xFFFF9933), w: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Map Layer Quick Toggles
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1526).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(Dp.rSm),
                  border: Border.all(color: Dp.hairline),
                ),
                child: Row(
                  children: [
                    TactileButton(
                      label: 'HEATMAP',
                      icon: DGlyph.heat,
                      accent: cc.showHeatmap ? const Color(0xFFFF9933) : Dp.textMuted,
                      dense: true,
                      outline: !cc.showHeatmap,
                      onTap: cc.toggleHeatmap,
                    ),
                    const SizedBox(width: 6),
                    TactileButton(
                      label: 'CORRIDORS',
                      icon: DGlyph.route,
                      accent: cc.showCorridors ? Dp.accent : Dp.textMuted,
                      dense: true,
                      outline: !cc.showCorridors,
                      onTap: cc.toggleCorridors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Incident Inspector Bottom Card (if selected)
        if (_inspectingEvent != null)
          Positioned(
            left: 20,
            bottom: 20,
            width: 420,
            child: _buildInspectorCard(context, cc, _inspectingEvent!),
          ),
      ],
    );
  }

  Widget _buildInspectorCard(BuildContext context, CommandCenter cc, DetectionEvent e) {
    final isDark = Dp.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1526).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(Dp.rMd),
        border: Border.all(color: Dp.hairline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: e.status.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: e.status.color, width: 0.8),
                ),
                child: Text(e.status.label, style: monoTxt(8.5, color: e.status.color, w: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              SeverityTag(e.severity, size: 9),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 16),
                color: Dp.textMuted,
                onPressed: () => setState(() => _inspectingEvent = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${e.kind.label.toUpperCase()} · #${e.id}',
            style: AppText.label.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Location: ${e.busRoute} · GPS ${e.gpsLabel}\nDetected by transit bus ${e.busId} (${e.confLabel} Edge Confidence)',
            style: monoTxt(9.5, color: Dp.textMuted),
          ),
          if (e.assignedCrew != null) ...[
            const SizedBox(height: 6),
            Text(
              'Assigned Unit: ${e.assignedCrew}',
              style: monoTxt(9.5, color: const Color(0xFF38BDF8), w: FontWeight.w700),
            ),
          ],
          if (e.verifyVerdict != null) ...[
            const SizedBox(height: 2),
            Text(
              'Inspection Verdict: ${e.verifyVerdict}',
              style: monoTxt(9, color: const Color(0xFFA855F7), w: FontWeight.w600),
            ),
          ],
          if (e.resolutionNote != null) ...[
            const SizedBox(height: 2),
            Text(
              'Resolution: ${e.resolutionNote}',
              style: monoTxt(9, color: const Color(0xFF10B981), w: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

/// ============================================================
/// WEB VIEW 2: ASSIGN & DISPATCH PIPELINE
/// Scope: City Authority allocates resources to unresolved alerts.
/// Web ASSIGNS, Mobile RESOLVES!
/// Shared Pipeline: New → Assigned → Field-Verified → Resolved
/// ============================================================
class WebDispatchView extends StatefulWidget {
  const WebDispatchView({super.key});

  @override
  State<WebDispatchView> createState() => _WebDispatchViewState();
}

class _WebDispatchViewState extends State<WebDispatchView> {
  IncidentStatus? _filterStatus;
  String _filterCorridor = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Dp.isDark;

    final allList = cc.incidents;
    final newCount = allList.where((e) => e.status == IncidentStatus.newAlert).length;
    final assignedCount = allList.where((e) => e.status == IncidentStatus.assigned).length;
    final verifiedCount = allList.where((e) => e.status == IncidentStatus.verified).length;
    final resolvedCount = allList.where((e) => e.status == IncidentStatus.resolved).length;

    var filtered = allList.where((e) {
      if (_filterStatus != null && e.status != _filterStatus) return false;
      if (_filterCorridor != 'ALL' && e.busRoute != _filterCorridor) return false;
      if (_searchQuery.isNotEmpty &&
          !e.id.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !e.kind.label.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header & Role Isolation Notice
            Row(
              children: [
                Drishti.icon(DGlyph.target, size: 20, color: Dp.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MUNICIPAL TRIAGE & DISPATCH CONSOLE',
                        style: AppText.displaySmall(size: 16).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Dp.ink,
                        ),
                      ),
                      Text(
                        'Command Center: Assign road defects to municipal maintenance units. Track live repair milestones across transit corridors.',
                        style: monoTxt(9.5, color: Dp.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const GovBadge(label: 'SHARED STATE PIPELINE', sublabel: 'LIVE SYNC', dense: true),
              ],
            ),
            const SizedBox(height: 18),

            // Pipeline KPI Cards (New -> Assigned -> Verified -> Resolved)
            Row(
              children: [
                Expanded(
                  child: _buildPipelineCard(
                    title: '1. NEW ALERTS',
                    count: '$newCount',
                    color: const Color(0xFFFF9933),
                    subtitle: 'Awaiting Unit Dispatch',
                    selected: _filterStatus == IncidentStatus.newAlert,
                    onTap: () => setState(() => _filterStatus = _filterStatus == IncidentStatus.newAlert ? null : IncidentStatus.newAlert),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPipelineCard(
                    title: '2. ASSIGNED',
                    count: '$assignedCount',
                    color: const Color(0xFF38BDF8),
                    subtitle: 'Dispatched to Unit',
                    selected: _filterStatus == IncidentStatus.assigned,
                    onTap: () => setState(() => _filterStatus = _filterStatus == IncidentStatus.assigned ? null : IncidentStatus.assigned),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPipelineCard(
                    title: '3. ON-SITE VERIFIED',
                    count: '$verifiedCount',
                    color: const Color(0xFFA855F7),
                    subtitle: 'Inspected on Ground',
                    selected: _filterStatus == IncidentStatus.verified,
                    onTap: () => setState(() => _filterStatus = _filterStatus == IncidentStatus.verified ? null : IncidentStatus.verified),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPipelineCard(
                    title: '4. RESOLVED',
                    count: '$resolvedCount',
                    color: const Color(0xFF10B981),
                    subtitle: 'Repaired & Closed',
                    selected: _filterStatus == IncidentStatus.resolved,
                    onTap: () => setState(() => _filterStatus = _filterStatus == IncidentStatus.resolved ? null : IncidentStatus.resolved),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Dp.card,
                borderRadius: BorderRadius.circular(Dp.rSm),
                border: Border.all(color: Dp.hairline),
              ),
              child: Row(
                children: [
                  // Status filter chips
                  Text('STATUS:', style: monoTxt(9.5, color: Dp.textMuted, w: FontWeight.w700)),
                  const SizedBox(width: 8),
                  _buildFilterChip('ALL', _filterStatus == null, () => setState(() => _filterStatus = null)),
                  const SizedBox(width: 6),
                  _buildFilterChip('NEW', _filterStatus == IncidentStatus.newAlert, () => setState(() => _filterStatus = IncidentStatus.newAlert)),
                  const SizedBox(width: 6),
                  _buildFilterChip('ASSIGNED', _filterStatus == IncidentStatus.assigned, () => setState(() => _filterStatus = IncidentStatus.assigned)),
                  const SizedBox(width: 6),
                  _buildFilterChip('VERIFIED', _filterStatus == IncidentStatus.verified, () => setState(() => _filterStatus = IncidentStatus.verified)),
                  const SizedBox(width: 6),
                  _buildFilterChip('RESOLVED', _filterStatus == IncidentStatus.resolved, () => setState(() => _filterStatus = IncidentStatus.resolved)),
                  const SizedBox(width: 20),
                  // Corridor filter
                  Text('ROUTE:', style: monoTxt(9.5, color: Dp.textMuted, w: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _filterCorridor,
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF142036) : Colors.white,
                    style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w700),
                    items: ['ALL', ...cc.availableRoutes].map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _filterCorridor = v);
                    },
                  ),
                  const Spacer(),
                  // Search box
                  SizedBox(
                    width: 200,
                    height: 32,
                    child: TextField(
                      style: monoTxt(10, color: Dp.ink),
                      decoration: InputDecoration(
                        hintText: 'Search ID or type...',
                        hintStyle: monoTxt(9.5, color: Dp.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 14),
                        filled: true,
                        fillColor: Dp.field,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Dp.hairline)),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Incident Triage Table
            Container(
              decoration: BoxDecoration(
                color: Dp.card,
                borderRadius: BorderRadius.circular(Dp.rMd),
                border: Border.all(color: Dp.hairline),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Dp.rMd)),
                      border: Border(bottom: BorderSide(color: Dp.hairline)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 85, child: Text('INCIDENT', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 140, child: Text('DEFECT TYPE', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 90, child: Text('SEVERITY', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 110, child: Text('CORRIDOR', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 100, child: Text('CONFIDENCE', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 120, child: Text('STATUS', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        Expanded(child: Text('ASSIGNED UNIT / AUDIT', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 150, child: Text('ACTION (WEB ONLY)', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),

                  // Table Body
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No incidents matching selected filters.',
                          style: monoTxt(11, color: Dp.textMuted),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < filtered.length; i++)
                      _buildTableRow(context, cc, filtered[i], isEven: i % 2 == 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active, VoidCallback onTap) {
    return Tactile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Dp.accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? Dp.accent : Dp.hairline),
        ),
        child: Text(label, style: monoTxt(8.5, color: active ? Dp.ink : Dp.textMuted, w: active ? FontWeight.w800 : FontWeight.w500)),
      ),
    );
  }

  Widget _buildPipelineCard({
    required String title,
    required String count,
    required Color color,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Tactile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Dp.card,
          borderRadius: BorderRadius.circular(Dp.rSm),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.35),
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: monoTxt(9, color: color, w: FontWeight.w800)),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: monoTxt(22, color: Dp.ink, w: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: monoTxt(8.5, color: Dp.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, CommandCenter cc, DetectionEvent e, {required bool isEven}) {
    final isDark = Dp.isDark;
    final rowBg = isEven
        ? Colors.transparent
        : (isDark ? const Color(0xFF0D1526).withValues(alpha: 0.35) : const Color(0xFFF8FAFC));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(bottom: BorderSide(color: Dp.hairline, width: 0.6)),
      ),
      child: Row(
        children: [
          // ID
          SizedBox(
            width: 85,
            child: Text('#${e.id}', style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w700)),
          ),
          // Kind
          SizedBox(
            width: 140,
            child: Text(e.kind.label.toUpperCase(), style: monoTxt(9.5, color: Dp.inkSoft, w: FontWeight.w700)),
          ),
          // Severity
          SizedBox(
            width: 90,
            child: Align(alignment: Alignment.centerLeft, child: SeverityTag(e.severity, size: 8)),
          ),
          // Route
          SizedBox(
            width: 110,
            child: Text(e.busRoute, style: monoTxt(9, color: Dp.textMuted)),
          ),
          // Confidence
          SizedBox(
            width: 100,
            child: Text(e.confLabel, style: monoTxt(9, color: Dp.textMuted)),
          ),
          // Status
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: e.status.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: e.status.color, width: 0.8),
                ),
                child: Text(e.status.label, style: monoTxt(8, color: e.status.color, w: FontWeight.w800)),
              ),
            ),
          ),
          // Assigned Unit
          Expanded(
            child: Text(
              e.assignedCrew != null
                  ? '${e.assignedCrew!} ${e.resolutionNote != null ? "· ${e.resolutionNote}" : ""}'
                  : '— Unassigned —',
              style: monoTxt(8.5, color: e.assignedCrew != null ? Dp.inkSoft : Dp.textFaint),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Web Action Button
          SizedBox(
            width: 150,
            child: Align(
              alignment: Alignment.centerRight,
              child: e.status == IncidentStatus.resolved
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text('RESOLVED', style: monoTxt(8.5, color: const Color(0xFF10B981), w: FontWeight.w800)),
                      ],
                    )
                  : TactileButton(
                      label: e.assignedCrew != null ? 'REASSIGN' : 'ASSIGN UNIT',
                      icon: DGlyph.target,
                      accent: e.assignedCrew != null ? const Color(0xFF38BDF8) : const Color(0xFFFF9933),
                      dense: true,
                      onTap: () => _openAssignModal(context, cc, e),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAssignModal(BuildContext context, CommandCenter cc, DetectionEvent e) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _AssignModal(cc: cc, event: e),
    );
  }
}

class _AssignModal extends StatefulWidget {
  const _AssignModal({required this.cc, required this.event});
  final CommandCenter cc;
  final DetectionEvent event;

  @override
  State<_AssignModal> createState() => _AssignModalState();
}

class _AssignModalState extends State<_AssignModal> {
  String _selectedCrew = 'Maintenance Unit 04 (Karve Rd - Fast Response)';
  String _priority = 'CRITICAL (SLA < 4H)';
  final TextEditingController _notesCtrl = TextEditingController(text: 'Urgent asphalt defect requiring cold-mix patch');

  final List<String> _crews = const [
    'Maintenance Unit 04 (Karve Rd - Fast Response)',
    'Maintenance Unit 12 (Shivajinagar Corridor)',
    'PWD Roads Infra Alpha (Heavy Repairs)',
    'PMPML Rapid Transit Unit',
    'PMC Encroachment Clearance Wing',
    'Electrical & Utility Division',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0D1526) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dp.rMd)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Drishti.icon(DGlyph.target, size: 18, color: const Color(0xFFFF9933)),
                const SizedBox(width: 8),
                Text(
                  'DISPATCH WORK ORDER TO UNIT',
                  style: monoTxt(12, color: Dp.ink, w: FontWeight.w800, ls: 0.6),
                ),
                const Spacer(),
                const GovBadge(label: 'WEB ONLY', dense: true),
              ],
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INCIDENT #${widget.event.id} · ${widget.event.kind.label.toUpperCase()}', style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w700)),
                        Text('Corridor: ${widget.event.busRoute} · GPS ${widget.event.gpsLabel}', style: monoTxt(8.5, color: Dp.textMuted)),
                      ],
                    ),
                  ),
                  SeverityTag(widget.event.severity, size: 8),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('ASSIGN TO MAINTENANCE UNIT / DEPARTMENT', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Dp.field,
                borderRadius: BorderRadius.circular(Dp.rSm),
                border: Border.all(color: Dp.hairline),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCrew,
                underline: const SizedBox(),
                dropdownColor: isDark ? const Color(0xFF142036) : Colors.white,
                style: monoTxt(10, color: Dp.ink, w: FontWeight.w600),
                items: _crews.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCrew = v);
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('DISPATCH PRIORITY', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                'CRITICAL (SLA < 4H)',
                'HIGH (SLA < 12H)',
                'STANDARD (SLA < 24H)',
              ].map((p) {
                final sel = _priority == p;
                return Tactile(
                  onTap: () => setState(() => _priority = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFFF9933).withValues(alpha: 0.18) : Dp.field,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: sel ? const Color(0xFFFF9933) : Dp.hairline),
                    ),
                    child: Text(p, style: monoTxt(8, color: sel ? const Color(0xFFFF9933) : Dp.inkSoft, w: FontWeight.w700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text('DISPATCH INSTRUCTIONS', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              style: monoTxt(10, color: Dp.ink),
              decoration: InputDecoration(
                filled: true,
                fillColor: Dp.field,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dp.rSm), borderSide: BorderSide(color: Dp.hairline)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TactileButton(
                    label: 'CANCEL',
                    outline: true,
                    dense: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TactileButton(
                    label: 'DISPATCH WORK ORDER',
                    icon: DGlyph.check,
                    accent: const Color(0xFFFF9933),
                    dense: true,
                    onTap: () {
                      widget.cc.assignIncident(widget.event.id, _selectedCrew);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0284C7),
                          content: Text(
                            'Incident #${widget.event.id} dispatched to $_selectedCrew. Municipal work order generated.',
                            style: monoTxt(10, color: Colors.white, w: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// WEB VIEW 3: FLEET-WIDE MULTI-PANEL ANALYTICS
/// Scope: Executive aggregate trend charts across the entire city.
/// Features: Defects over time, 24h congestion profile, breakdown,
/// and 8 Key Transit Corridors Health Scorecard.
/// ============================================================
class WebAnalyticsView extends StatelessWidget {
  const WebAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Drishti.icon(DGlyph.stats, size: 20, color: Dp.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PUNE METROPOLITAN FLEET ANALYTICS',
                        style: AppText.displaySmall(size: 16).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Dp.ink,
                        ),
                      ),
                      Text(
                        'Aggregated municipal intelligence derived from real-time Edge-AI transit inference.',
                        style: monoTxt(9.5, color: Dp.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const GovBadge(label: 'FLEET SCALE', sublabel: 'AGGREGATE', dense: true),
              ],
            ),
            const SizedBox(height: 18),

            // Top KPI Strip
            Row(
              children: [
                Expanded(child: _kpiBox('TOTAL DEFECTS LOGGED', '${cc.total}', const Color(0xFFFF9933))),
                const SizedBox(width: 12),
                Expanded(child: _kpiBox('ACTIVE BUS SCANNERS', '${cc.busesOnline}', const Color(0xFF138808))),
                const SizedBox(width: 12),
                Expanded(child: _kpiBox('AVG ROAD ROUGHNESS (IRI)', '2.4 m/km', const Color(0xFF38BDF8))),
                const SizedBox(width: 12),
                Expanded(child: _kpiBox('AVG CYCLE TIME TO FIX', '< 3.2h', const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 20),

            // 2-Column Grid: Defect Ingestion Trend & 24H Congestion Profile
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel 1: Defect Ingestion Trend
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
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
                            Expanded(
                              child: Text(
                                'DEFECT INGESTION BY HOUR',
                                style: monoTxt(10, color: Dp.ink, w: FontWeight.w800, ls: 0.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('HOURLY INFERENCE', style: monoTxt(8, color: Dp.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 20,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Text('${v.toInt()}:00', style: monoTxt(8, color: Dp.textMuted)),
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    getTitlesWidget: (v, _) => Text('${v.toInt()}', style: monoTxt(8, color: Dp.textMuted)),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(color: Dp.hairline, strokeWidth: 0.8),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                for (var h = 8; h <= 15; h++)
                                  BarChartGroupData(
                                    x: h,
                                    barRods: [
                                      BarChartRodData(
                                        toY: (math.sin(h) * 6 + 10).clamp(4, 18),
                                        color: h == 12 ? const Color(0xFFFF9933) : Dp.accent,
                                        width: 14,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Panel 2: 24-Hour Live Congestion Profile
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
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
                            Expanded(
                              child: Text(
                                '24H CONGESTION PEAK PROFILE',
                                style: monoTxt(10, color: Dp.ink, w: FontWeight.w800, ls: 0.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('PEAK VS LIVE', style: monoTxt(8, color: Dp.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(color: Dp.hairline, strokeWidth: 0.8),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 4,
                                    getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: monoTxt(8, color: Dp.textMuted)),
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    getTitlesWidget: (v, _) => Text('${(v * 100).toInt()}%', style: monoTxt(7.5, color: Dp.textMuted)),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 24,
                              minY: 0,
                              maxY: 1.0,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (var h = 0; h <= 24; h++)
                                      FlSpot(h.toDouble(), (math.sin(h / 3) * 0.35 + 0.50).clamp(0.1, 0.95)),
                                  ],
                                  isCurved: true,
                                  color: Dp.accent,
                                  barWidth: 2.2,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Dp.accent.withValues(alpha: 0.10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Panel 3: 8 Transit Corridors Health Scorecard
            Container(
              padding: const EdgeInsets.all(18),
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
                      Text('TRANSIT CORRIDOR CONDITION SCORECARD · 8 ARTERIAL HIGHWAYS', style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w800, ls: 0.6)),
                      const Spacer(),
                      const GovBadge(label: 'AIS-140 COMPLIANT', dense: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Padding(
                            padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                            child: SizedBox(
                              width: 220,
                              child: _corridorCard(
                                name: ['Karve Road', 'FC Road', 'Pune-Solapur', 'Sinhagad Rd'][i],
                                route: ['ROUTE 12', 'ROUTE 08', 'ROUTE 04', 'ROUTE 19'][i],
                                defects: [8, 3, 14, 5][i],
                                iri: ['2.1', '1.4', '3.8', '2.6'][i],
                                status: ['MODERATE', 'OPTIMAL', 'CRITICAL', 'WATCH'][i],
                                statusColor: [const Color(0xFFFF9933), const Color(0xFF10B981), const Color(0xFFEF4444), const Color(0xFF38BDF8)][i],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiBox(String title, String val, Color col) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Dp.card,
        borderRadius: BorderRadius.circular(Dp.rSm),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: monoTxt(8.5, color: Dp.textMuted, w: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(val, style: monoTxt(20, color: col, w: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _corridorCard({
    required String name,
    required String route,
    required int defects,
    required String iri,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Dp.field,
        borderRadius: BorderRadius.circular(Dp.rSm),
        border: Border.all(color: Dp.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(route, style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(status, style: monoTxt(7.5, color: statusColor, w: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(name, style: AppText.label.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('$defects Defect Vectors · IRI $iri m/km', style: monoTxt(8.5, color: Dp.textMuted)),
        ],
      ),
    );
  }
}

/// ============================================================
/// WEB VIEW 4: HISTORICAL AUDIT EXPLORER & REPORT EXPORT
/// Scope: Browse past alerts/resolutions with multi-parameter filters
/// + Generate official Municipal Audit Certificate (PDF/CSV stub).
/// Meaningless on mobile, natural desktop municipal authority task.
/// ============================================================
class WebAuditView extends StatefulWidget {
  const WebAuditView({super.key});

  @override
  State<WebAuditView> createState() => _WebAuditViewState();
}

class _WebAuditViewState extends State<WebAuditView> {
  String _dateFilter = 'Last 24 Hours';
  String _typeFilter = 'ALL';
  final String _routeFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    final isDark = Dp.isDark;

    final historyList = cc.incidents.where((e) {
      if (_typeFilter != 'ALL' && e.kind.label.toUpperCase() != _typeFilter) return false;
      if (_routeFilter != 'ALL' && e.busRoute != _routeFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Export Button
            Row(
              children: [
                Drishti.icon(DGlyph.download, size: 20, color: const Color(0xFFFF9933)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HISTORICAL AUDIT & MUNICIPAL REPORT EXPORT',
                        style: AppText.displaySmall(size: 16).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Dp.ink,
                        ),
                      ),
                      Text(
                        'Certified audit trail for municipal budget justification and infrastructure accountability.',
                        style: monoTxt(9.5, color: Dp.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TactileButton(
                  label: 'EXPORT MUNICIPAL AUDIT REPORT',
                  icon: DGlyph.download,
                  accent: const Color(0xFFFF9933),
                  dense: true,
                  onTap: () => _openExportDialog(context, cc),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Dp.card,
                borderRadius: BorderRadius.circular(Dp.rSm),
                border: Border.all(color: Dp.hairline),
              ),
              child: Row(
                children: [
                  Text('DATE RANGE:', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _dateFilter,
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF142036) : Colors.white,
                    style: monoTxt(10, color: Dp.ink, w: FontWeight.w700),
                    items: ['Last 24 Hours', 'Last 7 Days', 'Month-to-Date'].map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _dateFilter = v);
                    },
                  ),
                  const SizedBox(width: 18),
                  Text('DEFECT TYPE:', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w700)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _typeFilter,
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF142036) : Colors.white,
                    style: monoTxt(10, color: Dp.ink, w: FontWeight.w700),
                    items: ['ALL', 'POTHOLE', 'ROAD FRACTURE', 'CONGESTION', 'PEDESTRIAN RISK'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _typeFilter = v);
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Dp.field,
                      borderRadius: BorderRadius.circular(Dp.rFull),
                    ),
                    child: Text('${historyList.length} AUDIT RECORDS', style: monoTxt(9, color: Dp.ink, w: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Audit Records Table
            Container(
              decoration: BoxDecoration(
                color: Dp.card,
                borderRadius: BorderRadius.circular(Dp.rMd),
                border: Border.all(color: Dp.hairline),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Dp.rMd)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 100, child: Text('TIMESTAMP', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 80, child: Text('INCIDENT', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 130, child: Text('DEFECT', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 100, child: Text('CORRIDOR', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        SizedBox(width: 120, child: Text('LIFECYCLE STATUS', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                        Expanded(child: Text('DISPATCH & RESOLUTION TRAIL', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w800))),
                      ],
                    ),
                  ),
                  for (final e in historyList)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Dp.hairline, width: 0.6)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text(e.timeShort, style: monoTxt(9.5, color: Dp.textMuted))),
                          SizedBox(width: 80, child: Text('#${e.id}', style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w700))),
                          SizedBox(width: 130, child: Text(e.kind.label.toUpperCase(), style: monoTxt(9.5, color: Dp.inkSoft, w: FontWeight.w700))),
                          SizedBox(width: 100, child: Text(e.busRoute, style: monoTxt(9, color: Dp.textMuted))),
                          SizedBox(
                            width: 120,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: e.status.color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: e.status.color, width: 0.8),
                                ),
                                child: Text(e.status.label, style: monoTxt(8, color: e.status.color, w: FontWeight.w800)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Dispatched: ${e.assignedCrew ?? "Unassigned"} · Verdict: ${e.verifyVerdict ?? "Pending"} · Resolution: ${e.resolutionNote ?? "None"}',
                              style: monoTxt(8.5, color: Dp.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExportDialog(BuildContext context, CommandCenter cc) {
    showDialog(
      context: context,
      builder: (_) => _ReportExportModal(cc: cc),
    );
  }
}

class _ReportExportModal extends StatelessWidget {
  const _ReportExportModal({required this.cc});
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0D1526) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dp.rMd)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AshokaChakra(size: 20, color: Color(0xFF000080)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PUNE MUNICIPAL CORPORATION (PMC)', style: AppText.displaySmall(size: 13).copyWith(fontWeight: FontWeight.w800, color: Dp.ink)),
                    Text('ROAD INFRASTRUCTURE COMPLIANCE CERTIFICATE', style: monoTxt(8.5, color: const Color(0xFFFF9933), w: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                const GovBadge(label: 'GOV-CERT', dense: true),
              ],
            ),
            const SizedBox(height: 16),
            const GovTricolorBar(height: 2.5),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Dp.field,
                borderRadius: BorderRadius.circular(Dp.rSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REPORT METRICS SUMMARY', style: monoTxt(9, color: Dp.textMuted, w: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('• Total Defect Vectors Detected: ${cc.total}', style: monoTxt(9.5, color: Dp.ink)),
                  Text('• Active AIS-140 Transit Scanners: ${cc.busesOnline} Buses', style: monoTxt(9.5, color: Dp.ink)),
                  Text('• Average Cycle Time to Repair: < 3.2 Hours', style: monoTxt(9.5, color: Dp.ink)),
                  Text('• Official Digital SHA-256 Seal:', style: monoTxt(9.5, color: Dp.ink)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.all(6),
                    color: isDark ? Colors.black : const Color(0xFFE2E8F0),
                    child: Text(
                      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                      style: monoTxt(7.5, color: Dp.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This export constitutes an official municipal audit log for state infrastructure funding compliance and budget justification under the AIS-140 framework.',
              style: monoTxt(8.5, color: Dp.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TactileButton(
                    label: 'EXPORT CSV AUDIT STUB',
                    icon: DGlyph.download,
                    outline: true,
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('CSV Audit dataset exported successfully (drishti_audit_pmc.csv).', style: monoTxt(10, color: Colors.white, w: FontWeight.w700)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TactileButton(
                    label: 'DOWNLOAD OFFICIAL PDF',
                    icon: DGlyph.download,
                    accent: const Color(0xFFFF9933),
                    dense: true,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('Certified PDF Report generated with PMC official cryptographic stamp.', style: monoTxt(10, color: Colors.white, w: FontWeight.w700)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// WEB VIEW 5: ALERT CONFIGURATION & ADMIN CONTROLS
/// Scope: Municipal Admin configures edge-AI thresholds per defect
/// and toggles which corridors are monitored. No mobile equivalent.
/// ============================================================
class WebConfigView extends StatefulWidget {
  const WebConfigView({super.key});

  @override
  State<WebConfigView> createState() => _WebConfigViewState();
}

class _WebConfigViewState extends State<WebConfigView> {
  double _potholeThreshold = 0.88;
  double _fractureThreshold = 0.85;
  double _pedThreshold = 0.90;
  double _waterlogThreshold = 0.82;

  final Map<String, bool> _corridorsMonitored = {
    'CORR-01: Karve Road Transit': true,
    'CORR-02: FC Road Arterial': true,
    'CORR-03: Pune-Solapur Highway': true,
    'CORR-04: Sinhagad Road Corridor': true,
    'CORR-05: Nagar Road Metro Line': true,
    'CORR-06: Paud Road Expressway': false,
    'CORR-07: Baner Link Corridor': true,
    'CORR-08: Hadapsar Central BRTS': true,
  };

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Drishti.icon(DGlyph.sliders, size: 20, color: Dp.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDGE-AI SEVERITY THRESHOLDS & CORRIDOR CONFIGURATION',
                        style: AppText.displaySmall(size: 16).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Dp.ink,
                        ),
                      ),
                      Text(
                        'Admin parameters governing edge-AI trigger confidence scores and active municipal monitoring zones.',
                        style: monoTxt(9.5, color: Dp.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const GovBadge(label: 'ADMIN PRIVILEGES', sublabel: 'CITY LEVEL', dense: true),
              ],
            ),
            const SizedBox(height: 20),

            // Sliders Section
            Container(
              padding: const EdgeInsets.all(20),
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
                      Text('SEVERITY THRESHOLD PER DEFECT TYPE', style: monoTxt(11, color: Dp.ink, w: FontWeight.w800)),
                      const Spacer(),
                      Text('MIN CONFIDENCE TO FLAG HIGH SEVERITY', style: monoTxt(8.5, color: Dp.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSliderRow(
                    label: 'POTHOLE SEVERITY THRESHOLD',
                    val: _potholeThreshold,
                    color: const Color(0xFFFF9933),
                    onChanged: (v) => setState(() => _potholeThreshold = v),
                  ),
                  const SizedBox(height: 12),
                  _buildSliderRow(
                    label: 'ROAD FRACTURE / CROWN CRACK THRESHOLD',
                    val: _fractureThreshold,
                    color: const Color(0xFF38BDF8),
                    onChanged: (v) => setState(() => _fractureThreshold = v),
                  ),
                  const SizedBox(height: 12),
                  _buildSliderRow(
                    label: 'PEDESTRIAN & COMMUTER RISK THRESHOLD',
                    val: _pedThreshold,
                    color: const Color(0xFFA855F7),
                    onChanged: (v) => setState(() => _pedThreshold = v),
                  ),
                  const SizedBox(height: 12),
                  _buildSliderRow(
                    label: 'WATERLOGGING & DRAINAGE SUBSIDENCE',
                    val: _waterlogThreshold,
                    color: const Color(0xFF10B981),
                    onChanged: (v) => setState(() => _waterlogThreshold = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Monitored Corridors Switches
            Container(
              padding: const EdgeInsets.all(20),
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
                      Text('ACTIVELY MONITORED TRANSIT CORRIDORS', style: monoTxt(11, color: Dp.ink, w: FontWeight.w800)),
                      const Spacer(),
                      Text('${_corridorsMonitored.values.where((v) => v).length} OF 8 ACTIVE', style: monoTxt(9, color: const Color(0xFF138808), w: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: _corridorsMonitored.keys.map((c) {
                      final active = _corridorsMonitored[c]!;
                      return Container(
                        width: 380,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Dp.field,
                          borderRadius: BorderRadius.circular(Dp.rSm),
                          border: Border.all(color: active ? Dp.accent.withValues(alpha: 0.5) : Dp.hairline),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(c, style: monoTxt(9.5, color: Dp.ink, w: FontWeight.w600))),
                            Switch(
                              value: active,
                              activeThumbColor: const Color(0xFF138808),
                              onChanged: (v) => setState(() => _corridorsMonitored[c] = v),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Auto-Dispatch Rules & Save Action
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Dp.card,
                      borderRadius: BorderRadius.circular(Dp.rSm),
                      border: Border.all(color: Dp.hairline),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, size: 20, color: Color(0xFFFF9933)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AUTOMATED AIS-140 DISPATCH RULE', style: monoTxt(10, color: Dp.ink, w: FontWeight.w800)),
                              Text('Auto-assign Critical severity defects to nearest corridor maintenance unit.', style: monoTxt(8.5, color: Dp.textMuted)),
                            ],
                          ),
                        ),
                        Switch(
                          value: cc.autoDispatch,
                          activeThumbColor: const Color(0xFFFF9933),
                          onChanged: (_) => cc.toggleAutoDispatch(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                TactileButton(
                  label: 'SAVE MUNICIPAL CONFIGURATION',
                  icon: DGlyph.check,
                  accent: const Color(0xFF10B981),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Text('Municipal Edge-AI parameters and corridor monitoring rules saved.', style: monoTxt(10.5, color: Colors.white, w: FontWeight.w700)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double val,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Text(label, style: monoTxt(9.5, color: Dp.inkSoft, w: FontWeight.w700)),
        ),
        Expanded(
          child: Slider(
            value: val,
            min: 0.50,
            max: 0.99,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text('${(val * 100).toInt()}%', style: monoTxt(11, color: color, w: FontWeight.w800), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
