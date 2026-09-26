import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../app/motion.dart';
import '../app/palette.dart';
import '../app/typography.dart';
import '../core/command_center.dart';
import '../core/models.dart';
import '../core/sim.dart';
import '../ui/chrome.dart';
import '../ui/glyphs.dart';
import '../ui/gov_masthead.dart';
import '../ui/map_overlays.dart';
import '../ui/tactile.dart';

/// Screen C: Command Map
///
/// Central Command operations map:
/// - Real-time fleet tracking & moving bus markers
/// - Live incident pins landing dynamically
/// - Designed GPS pulse/ripple on arrival (CustomPainter + ticker)
/// - Toggleable congestion heatmap layer
/// - Corridors toggle
/// - Draggable bottom sheet operations feed with staggered slide-in rows
/// - In-place incident inspector modal
class CommandScreen extends StatefulWidget {
  const CommandScreen({super.key});

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  final MapController _map = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  String? _lastAlertId;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onAlertChanged(CommandCenter cc) {
    final id = cc.latest?.id;
    if (id != null && id != _lastAlertId) {
      _lastAlertId = id;
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cc = context.watch<CommandCenter>();
    _onAlertChanged(cc);

    return ColoredBox(
      color: Dp.canvas,
      child: Stack(
        children: [
          _buildMapView(cc),
          Positioned.fill(
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.20,
              minChildSize: 0.12,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.20, 0.48, 0.82],
              builder: (context, scroll) => _FeedSheet(
                cc: cc,
                scroll: scroll,
                controller: _sheetController,
                onSelect: (e) => _inspectIncident(context, e),
              ),
            ),
          ),
          _buildTopHud(cc),
          _buildRightControls(cc),
          const Positioned(left: 14, bottom: 84, child: _MapAttribution()),
        ],
      ),
    );
  }

  void _inspectIncident(BuildContext context, DetectionEvent e) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _IncidentInspectorSheet(event: e),
    );
  }

  Widget _buildMapView(CommandCenter cc) {
    final corridors = SimWorld.corridors();
    final isDark = cc.isDarkMode;

    return FlutterMap(
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
        // OpenStreetMap Basemap — Natural, live street grid with zero watermark/API key text
        TileLayer(
          key: ValueKey(isDark ? 'osm_dark' : 'osm_light'),
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
                      ? Dp.accent.withValues(alpha: 0.40 + (i % 3) * 0.10)
                      : const Color(0xFF0284C7).withValues(alpha: 0.50 + (i % 3) * 0.10),
                  strokeWidth: 3.0,
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
                  onTap: () => _inspectIncident(context, cc.incidents[i]),
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
    );
  }

  Widget _buildTopHud(CommandCenter cc) {
    final isDark = cc.isDarkMode;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0D1526).withValues(alpha: 0.95)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF64748B))
                        .withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Dp.accent.withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? Dp.accent.withValues(alpha: 0.4)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AshokaChakra(size: 13, color: Color(0xFF000080)),
                        const SizedBox(width: 6),
                        Text(
                          'COMMAND RADAR',
                          style: monoTxt(
                            10.5,
                            color: isDark ? Dp.accent : const Color(0xFF0F172A),
                            w: FontWeight.w700,
                            ls: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'पुणे महानगर • PMPML TRANSIT GRID',
                      style: monoTxt(
                        10,
                        color: isDark ? Dp.textMuted : const Color(0xFF475569),
                        w: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const GovBadge(label: 'NIC-AIS140', dense: true),
                  const SizedBox(width: 8),
                  const _ClockTick(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MiniStat('LIVE ALERTS', '${cc.total}'.padLeft(3, '0'), Dp.accent),
                  _MiniStat('BUSES ONLINE', '${cc.busesOnline}'.padLeft(2, '0'), Dp.ink),
                  _MiniStat('GRID SURVEYED', '${cc.coveragePercent}%', Dp.note),
                  _MiniStat('CORRIDORS', '8/8 MONITORED', Dp.saffron),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightControls(CommandCenter cc) {
    return Positioned(
      top: 136,
      right: 14,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayerToggle(
            glyph: DGlyph.heat,
            active: cc.showHeatmap,
            label: 'HEAT',
            onTap: () {
              HapticFeedback.selectionClick();
              cc.toggleHeatmap();
            },
          ),
          const SizedBox(height: 10),
          _LayerToggle(
            glyph: DGlyph.route,
            active: cc.showCorridors,
            label: 'CORRIDOR',
            onTap: () {
              HapticFeedback.selectionClick();
              cc.toggleCorridors();
            },
          ),
          const SizedBox(height: 10),
          _LayerToggle(
            glyph: DGlyph.crosshair,
            active: false,
            label: 'CENTER',
            onTap: () {
              HapticFeedback.mediumImpact();
              _map.move(
                const LatLng(SimWorld.cityLat, SimWorld.cityLng),
                12.8,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClockTick extends StatefulWidget {
  const _ClockTick();

  @override
  State<_ClockTick> createState() => _ClockTickState();
}

class _ClockTickState extends State<_ClockTick> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    return Text(
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}',
      style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w700),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CommandCenter>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1526).withValues(alpha: 0.92)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF64748B))
                .withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: monoTxt(10.5, color: color, w: FontWeight.w700, ls: 0.3),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: monoTxt(
              8.5,
              color: isDark ? Dp.textMuted : const Color(0xFF475569),
              w: FontWeight.w600,
              ls: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({
    required this.glyph,
    required this.active,
    required this.label,
    required this.onTap,
  });

  final DGlyph glyph;
  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<CommandCenter>().isDarkMode;
    final bgCol = active
        ? (isDark ? Dp.accent : const Color(0xFF0F172A))
        : (isDark ? const Color(0xFF0D1526) : const Color(0xFFFFFFFF));
    final borderCol = active
        ? (isDark ? Dp.accent : const Color(0xFF0F172A))
        : (isDark ? const Color(0xFF1E2F4C) : const Color(0xFFCBD5E1));
    final fgCol = active
        ? (isDark ? const Color(0xFF090E17) : const Color(0xFFFFFFFF))
        : (isDark ? Dp.ink : const Color(0xFF0F172A));

    return Tactile(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeTech,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: (active
                      ? (isDark ? Dp.accent : const Color(0xFF0F172A))
                      : (isDark ? Colors.black : const Color(0xFF64748B)))
                  .withValues(alpha: active ? (isDark ? 0.35 : 0.22) : (isDark ? 0.4 : 0.15)),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Drishti.icon(glyph, size: 17, color: fgCol),
            const SizedBox(height: 3),
            Text(
              label,
              style: monoTxt(7.5, color: fgCol, w: FontWeight.w800, ls: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF0D1526) : const Color(0xFFFFFFFF))
              .withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? Dp.hairline : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          '© OpenStreetMap contributors',
          style: monoTxt(8, color: Dp.textFaint),
        ),
      ),
    );
  }
}

/// The live operations feed bottom sheet with staggered slide-in rows.
class _FeedSheet extends StatelessWidget {
  const _FeedSheet({
    required this.cc,
    required this.scroll,
    required this.controller,
    required this.onSelect,
  });

  final CommandCenter cc;
  final ScrollController scroll;
  final DraggableScrollableController controller;
  final ValueChanged<DetectionEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A101E) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dp.rMd)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF64748B))
                .withValues(alpha: isDark ? 0.5 : 0.2),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.zero,
          children: [
            _SheetHandle(controller: controller),
            _SheetHeader(cc: cc, controller: controller),
            HairDivider(
              color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFE2E8F0),
              thickness: double.infinity,
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < cc.incidents.length; i++)
              _StaggeredSlideIn(
                order: i,
                child: _FeedRow(
                  event: cc.incidents[i],
                  onTap: () => onSelect(cc.incidents[i]),
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.controller});
  final DraggableScrollableController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return Container(
      height: 24,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Container(
        width: 44,
        height: 4.5,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C3E5E) : const Color(0xFF94A3B8),
          borderRadius: BorderRadius.circular(Dp.rFull),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.cc, required this.controller});
  final CommandCenter cc;
  final DraggableScrollableController controller;

  void _snap(double target) {
    if (!controller.isAttached) return;
    HapticFeedback.selectionClick();
    controller.animateTo(
      target,
      duration: Mo.standard,
      curve: Mo.easeTech,
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = cc.latest;
    final isDark = Dp.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Drishti.icon(DGlyph.feed, size: 15, color: Dp.accent),
              const SizedBox(width: 8),
              Text(
                'LIVE INCIDENT FEED',
                style: monoTxt(11, color: Dp.ink, w: FontWeight.w700, ls: 1.0),
              ),
              const SizedBox(width: 10),
              _ResizePill(label: 'MIN', onTap: () => _snap(0.20)),
              const SizedBox(width: 4),
              _ResizePill(label: 'MID', onTap: () => _snap(0.48)),
              const SizedBox(width: 4),
              _ResizePill(label: 'MAX', onTap: () => _snap(0.82)),
              const Spacer(),
              const LivePill(dense: true, label: 'INGESTING'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162238) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(Dp.rFull),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  '${cc.total}',
                  style: monoTxt(
                    10.5,
                    color: isDark ? Dp.accent : const Color(0xFF0F172A),
                    w: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (latest != null) ...[
            const SizedBox(height: 8),
            _LatestFeedAlertBar(event: latest),
          ],
        ],
      ),
    );
  }
}

class _ResizePill extends StatelessWidget {
  const _ResizePill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;

    return Tactile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141F33) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(Dp.rFull),
          border: Border.all(
            color: isDark ? const Color(0xFF223554) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: monoTxt(
            8,
            color: isDark ? Dp.textMuted : const Color(0xFF475569),
            w: FontWeight.w700,
            ls: 0.5,
          ),
        ),
      ),
    );
  }
}

class _LatestFeedAlertBar extends StatelessWidget {
  const _LatestFeedAlertBar({required this.event});
  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;
    final col = Dp.severityColor(event.severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(Dp.rSm),
        border: Border.all(color: col.withValues(alpha: isDark ? 0.4 : 0.35)),
      ),
      child: Row(
        children: [
          SeverityTag(event.severity, size: 9),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'NEW INGEST: ${event.kind.label.toUpperCase()} · ${event.confLabel}',
              style: monoTxt(10.5, color: Dp.ink, w: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            event.timeLabel,
            style: monoTxt(9.5, color: Dp.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Staggered slide-in animation for arriving incident feed rows.
class _StaggeredSlideIn extends StatelessWidget {
  const _StaggeredSlideIn({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Mo.standard + Duration(milliseconds: (order % 6) * 35),
      curve: Mo.easeTech,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14.0 * (1.0 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.event, required this.onTap});
  final DetectionEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;
    final col = Dp.severityColor(event.severity);

    return Tactile(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1526) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(Dp.rSm),
          border: Border.all(
            color: isDark ? const Color(0xFF1B283F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: col.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: Drishti.icon(_glyphFor(event.kind), size: 16, color: col),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          event.kind.label.toUpperCase(),
                          style: monoTxt(11.5, color: Dp.ink, w: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SeverityTag(event.severity, size: 8),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${event.busId} · ${event.timeLabel} · ${event.confLabel}',
                    style: monoTxt(9, color: Dp.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: event.ageMinutes < 2
                    ? Dp.accent.withValues(alpha: isDark ? 0.14 : 0.10)
                    : (isDark ? const Color(0xFF141F33) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(
                  color: event.ageMinutes < 2
                      ? (isDark ? Dp.accent.withValues(alpha: 0.5) : const Color(0xFF0284C7))
                      : (isDark ? const Color(0xFF1E2D47) : const Color(0xFFCBD5E1)),
                ),
              ),
              child: Text(
                event.ageMinutes < 2 ? 'NEW' : event.timeShort,
                style: monoTxt(
                  8.5,
                  color: event.ageMinutes < 2
                      ? (isDark ? Dp.accent : const Color(0xFF0284C7))
                      : (isDark ? Dp.textMuted : const Color(0xFF64748B)),
                  w: FontWeight.w700,
                  ls: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DGlyph _glyphFor(DetectionKind k) => switch (k) {
        DetectionKind.pothole => DGlyph.target,
        DetectionKind.roadFracture => DGlyph.route,
        DetectionKind.signLoss => DGlyph.info,
        DetectionKind.congestion => DGlyph.stacks,
        DetectionKind.pedRisk => DGlyph.pin,
        DetectionKind.plateCapture => DGlyph.plate,
      };
}

/// Incident Inspector modal bottom sheet — pops up when any incident is tapped.
class _IncidentInspectorSheet extends StatelessWidget {
  const _IncidentInspectorSheet({required this.event});
  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final isDark = Dp.isDark;
    final col = Dp.severityColor(event.severity);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090E17) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dp.rLg)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFCBD5E1),
            width: 1.4,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Dp.rSm),
                  border: Border.all(color: col.withValues(alpha: 0.6)),
                ),
                child: Text(
                  event.kind.label.toUpperCase(),
                  style: monoTxt(12, color: col, w: FontWeight.w800, ls: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              SeverityTag(event.severity, size: 10),
              const Spacer(),
              Text(
                'INCIDENT #${event.id}',
                style: monoTxt(10, color: Dp.textMuted, w: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(Dp.rMd),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2F4C) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildInspectRow('DETECTION GPS', event.gpsLabel),
                _buildInspectRow('REPORTING BUS', event.busId),
                _buildInspectRow('CONFIDENCE SCORE', event.confLabel, valueColor: Dp.accent),
                _buildInspectRow('CORRIDOR ID', event.corridorId),
                _buildInspectRow('TIMESTAMP', event.timeLabel),
                _buildInspectRow('RECOMMENDED WORK ORDER', _workOrderFor(event.kind)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TactileButton(
            label: 'DISPATCH MUNICIPAL PWD REPAIR CREW',
            icon: DGlyph.check,
            accent: isDark ? Dp.accent : const Color(0xFF0F172A),
            expanded: true,
            onTap: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                  content: Text(
                    'Work order dispatched for incident #${event.id} (${event.kind.label}). PWD notified.',
                    style: monoTxt(11, color: isDark ? Dp.accent : Colors.white, w: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInspectRow(String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: monoTxt(9.5, color: Dp.textMuted)),
          Text(v, style: monoTxt(10.5, color: valueColor ?? Dp.ink, w: FontWeight.w600)),
        ],
      ),
    );
  }

  String _workOrderFor(DetectionKind k) => switch (k) {
        DetectionKind.pothole => 'Cold-mix asphalt patch within 24h',
        DetectionKind.roadFracture => 'Bitumen crack-sealing scheduled',
        DetectionKind.congestion => 'Signal timing optimization signal sent',
        DetectionKind.pedRisk => 'Pedestrian crossing visibility audit',
        DetectionKind.signLoss => 'Transit signage replacement order',
        DetectionKind.plateCapture => 'VLTD lane compliance log verified',
      };
}