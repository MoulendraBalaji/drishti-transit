import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
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
import '../ui/map_overlays.dart';

/// Central Command map — live fleet, incident pins landing in real time, a
/// togglable heat layer, arrival ripples, and the draggable OPS feed.
class CommandScreen extends StatefulWidget {
  const CommandScreen({super.key});

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  final MapController _map = MapController();
  bool _heat = true;
  bool _routes = true;
  String? _lastAlertId;

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
      color: Dp.bg,
      child: Stack(
        children: [
          _mapView(cc),
          _topHud(cc),
          _rightControls(),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: Tok.feedSnapMin,
              minChildSize: 0.12,
              maxChildSize: Tok.feedSnapMax,
              snap: true,
              snapSizes: const [0.14, 0.42, 0.64],
              builder: (context, scroll) => _FeedSheet(
                cc: cc,
                scroll: scroll,
                onSelect: (e) => _openDetail(e),
              ),
            ),
          ),
          const Positioned(left: 12, bottom: 8, child: _MapAttribution()),
        ],
      ),
    );
  }

  void _openDetail(DetectionEvent e) {
    HapticFeedback.mediumImpact();
    context.push('/incident/${e.id}');
  }

  Widget _mapView(CommandCenter cc) {
    final corridors = SimWorld.corridors();
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: const LatLng(SimWorld.cityLat, SimWorld.cityLng),
        initialZoom: 12.6,
        minZoom: 10,
        maxZoom: 17,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        backgroundColor: Dp.bg,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'in.drishti.transit',
          maxZoom: 19,
        ),
        if (_routes)
          PolylineLayer(
            polylines: [
              for (var i = 0; i < corridors.length; i++)
                Polyline(
                  points: [
                    for (final (lat, lng) in corridors[i].geo)
                      LatLng(lat, lng),
                  ],
                  color: Dp.signal.withValues(
                      alpha: 0.16 + (i % 3) * 0.03),
                  strokeWidth: 2,
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
                  onTap: () => _openDetail(cc.incidents[i]),
                  child: IncidentPin(
                    event: cc.incidents[i],
                    newest: i == 0,
                  ),
                ),
              ),
          ],
        ),
        if (_heat) HeatOverlay(points: cc.heatPoints),
        RippleLayer(ripples: cc.ripples),
      ],
    );
  }

  Widget _topHud(CommandCenter cc) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DRISHTI',
                        style: AppText.displayTitle.copyWith(fontSize: 22)),
                    Text('CITY OPS · PUNE GRID',
                        style: AppText.dataTiny.copyWith(color: Dp.saffron)),
                  ],
                ),
                const Spacer(),
                const LivePill(),
                const SizedBox(width: 8),
                const _ClockTick(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniStat('ALERTS', '${cc.total}'.padLeft(3, '0')),
                _MiniStat('BUSES', '${cc.busesOnline}'.padLeft(2, '0')),
                _MiniStat('COVER', '${cc.coveragePercent}%'),
                const Spacer(),
                const _MiniTag('GRID 42/42'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rightControls() {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LayerToggle(
                glyph: DGlyph.heat,
                active: _heat,
                label: 'HEAT',
                onTap: () => setState(() => _heat = !_heat),
              ),
              const SizedBox(height: 8),
              _LayerToggle(
                glyph: DGlyph.route,
                active: _routes,
                label: 'RTE',
                onTap: () => setState(() => _routes = !_routes),
              ),
              const SizedBox(height: 8),
              _LayerToggle(
                glyph: DGlyph.crosshair,
                active: false,
                label: 'FIT',
                onTap: () => _map.move(
                    const LatLng(SimWorld.cityLat, SimWorld.cityLng), 12.6),
              ),
            ],
          ),
        ),
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
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
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
      style: AppText.dataStrong.copyWith(color: Dp.ink),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Dp.raised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Dp.line),
      ),
      child: Row(
        children: [
          Text(value,
              style: monoTxt(11,
                  color: Dp.ink, w: FontWeight.w700, ls: 0.3)),
          const SizedBox(width: 6),
          Text(label,
              style: AppText.dataTiny.copyWith(color: Dp.fog, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.dataTiny.copyWith(color: Dp.dim));
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
    final col = active ? Dp.signal : Dp.fog;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeOutTech,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? Dp.signal.withValues(alpha: 0.14)
              : Dp.raised.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? Dp.signal.withValues(alpha: 0.5) : Dp.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Drishti.icon(glyph, size: 16, color: col),
            Text(label,
                style: AppText.dataTiny.copyWith(
                    color: col, fontSize: 6.5, letterSpacing: 0.4)),
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
    return const IgnorePointer(
      child: Text(
        '© OpenStreetMap · © CARTO',
        style: TextStyle(
          fontFamily: AppText.mono,
          fontSize: 7.5,
          letterSpacing: 0.5,
          color: Dp.dim,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The live OPS feed sheet — draggable, newest-first, auto-updating, sparse.
// ---------------------------------------------------------------------------

class _FeedSheet extends StatelessWidget {
  const _FeedSheet({
    required this.cc,
    required this.scroll,
    required this.onSelect,
  });

  final CommandCenter cc;
  final ScrollController scroll;
  final ValueChanged<DetectionEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    final sheetColor = Dp.surface.withValues(alpha: 0.94);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: Dp.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.zero,
          children: [
            _SheetHandle(),
            _SheetHeader(cc),
            const HairDivider(color: Dp.line, thickness: double.infinity),
            const SizedBox(height: 4),
            for (var i = 0; i < cc.incidents.length; i++)
              _Delayed(
                order: i,
                child: _FeedRow(
                  event: cc.incidents[i],
                  onTap: () => onSelect(cc.incidents[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      alignment: Alignment.center,
      child: Container(
        width: 34,
        height: 4,
        decoration: BoxDecoration(
          color: Dp.fog.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader(this.cc);
  final CommandCenter cc;

  @override
  Widget build(BuildContext context) {
    final latest = cc.latest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Drishti.icon(DGlyph.feed, size: 14, color: Dp.mist),
              const SizedBox(width: 8),
              const Text('OPS FEED',
                  style: TextStyle(
                      fontFamily: AppText.mono,
                      fontSize: 10,
                      letterSpacing: 1.6,
                      color: Dp.mist,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              const LivePill(dense: true, label: 'STREAMING'),
              const SizedBox(width: 8),
              Text('${cc.total}',
                  style: AppText.dataStrong.copyWith(color: Dp.ink)),
            ],
          ),
          if (latest != null) ...[
            const SizedBox(height: 8),
            _LatestStrip(event: latest),
          ],
        ],
      ),
    );
  }
}

class _LatestStrip extends StatelessWidget {
  const _LatestStrip({required this.event});
  final DetectionEvent event;

  @override
  Widget build(BuildContext context) {
    final col = Dp.severityColor(event.severity);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SeverityTag(event.severity, size: 9.5),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.kind.label.toUpperCase(),
                        style: AppText.dataStrong.copyWith(
                            color: Dp.ink, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(event.confLabel,
                        style: monoTxt(10,
                            color: col, w: FontWeight.w700, ls: 0.3)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.busId} · ${event.timeLabel} · ${event.gpsLabel}',
                  style: AppText.dataTiny.copyWith(color: Dp.mist),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Drishti.icon(DGlyph.chevronRight, size: 14, color: Dp.fog),
        ],
      ),
    );
  }
}

/// Enters with the designed slide/fade, staggered by list order.
class _Delayed extends StatelessWidget {
  const _Delayed({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Mo.standard + Duration(milliseconds: (order % 6) * 40),
      curve: Mo.easeOutTech,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(-(1 - t) * 22, (1 - t) * 10),
          child: Transform.scale(
            scale: 0.97 + t * 0.03,
            child: child,
          ),
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
    final col = Dp.severityColor(event.severity);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              child: Drishti.icon(_glyphFor(event.kind),
                  size: 16, color: col.withValues(alpha: 0.9)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(event.kind.label.toUpperCase(),
                        style: AppText.dataStrong.copyWith(
                            fontSize: 12, color: Dp.ink)),
                    const SizedBox(width: 8),
                    SeverityTag(event.severity, size: 8.5),
                  ],
                ),
                const SizedBox(height: 3),
Text(
                  '${event.busId} · ${event.timeLabel} · ${event.confLabel}'
                  '${event.plate != null ? ' · ${event.plate}' : ''}',
                  style: AppText.dataTiny.copyWith(color: Dp.mist),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: event.ageMinutes < 2
                    ? Dp.signal.withValues(alpha: 0.12)
                    : Dp.raised2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                event.ageMinutes < 2 ? 'NEW' : event.timeShort,
                style: monoTxt(8.5,
                    color: event.ageMinutes < 2 ? Dp.signal : Dp.fog,
                    w: FontWeight.w700,
                    ls: 0.5),
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