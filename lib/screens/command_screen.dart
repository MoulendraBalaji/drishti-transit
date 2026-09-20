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

/// Central Command map — Mobbin Gallery-White design language.
/// Live fleet tracking, incident pins with crystal clarity, a togglable
/// heat layer, arrival ripples, and the draggable operations feed sheet.
class CommandScreen extends StatefulWidget {
  const CommandScreen({super.key});

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  final MapController _map = MapController();
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
      color: Dp.canvas,
      child: Stack(
        children: [
          _mapView(cc),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: Tok.feedSnapMin,
              minChildSize: 0.12,
              maxChildSize: Tok.feedSnapMax,
              snap: true,
              snapSizes: const [0.16, 0.42, 0.65],
              builder: (context, scroll) => _FeedSheet(
                cc: cc,
                scroll: scroll,
                onSelect: (e) => _openDetail(e),
              ),
            ),
          ),
          _topHud(cc),
          _rightControls(cc),
          const Positioned(left: 14, bottom: 84, child: _MapAttribution()),
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
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        backgroundColor: Dp.canvasSoft,
      ),
      children: [
        // Smooth Carto Voyager (light) base layer with caching
        TileLayer(
          key: const ValueKey('carto_voyager'),
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'in.drishti.transit',
          maxZoom: 19,
        ),
        if (cc.isDarkMode)
          TileLayer(
            key: const ValueKey('carto_dark'),
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
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
                  color: Dp.accent.withValues(
                      alpha: 0.35 + (i % 3) * 0.08),
                  strokeWidth: 2.8,
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
        if (cc.showHeatmap) HeatOverlay(points: cc.heatPoints),
        RippleLayer(ripples: cc.ripples),
      ],
    );
  }

  Widget _topHud(CommandCenter cc) {
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
                color: Dp.canvas.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(color: Dp.hairline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: const ValueKey('command_settings_button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/settings');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Dp.hairline, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/dristhi.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Drishti.icon(DGlyph.bus, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'DRISHTI',
                                      style: AppText.label.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Drishti.icon(DGlyph.settings, size: 11, color: Dp.textFaint),
                                  ],
                                ),
                                Text(
                                  'LIVE OPERATIONS',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.dataTiny.copyWith(
                                    color: Dp.textMuted,
                                    fontSize: 8.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const LivePill(dense: true),
                  const SizedBox(width: 6),
                  const _ClockTick(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MiniStat('ALERTS', '${cc.total}'.padLeft(3, '0')),
                  _MiniStat('FLEET', '${cc.busesOnline}'.padLeft(2, '0')),
                  _MiniStat('COVERAGE', '${cc.coveragePercent}%'),
                  _MiniStat('NODES', '42/42'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rightControls(CommandCenter cc) {
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
            label: 'ROUTE',
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
                12.6,
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
      style: AppText.dataStrong.copyWith(color: Dp.ink, fontSize: 11),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Dp.canvas.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(Dp.rFull),
        border: Border.all(color: Dp.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            style: monoTxt(11, color: Dp.ink, w: FontWeight.w700, ls: 0.2),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.dataTiny.copyWith(
              color: Dp.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 9,
              letterSpacing: 0.6,
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
    final isDark = Dp.isDark;

    // High-contrast background and border in both light and dark mode
    final Color bgCol;
    final Color borderCol;
    final Color fgCol;
    final List<BoxShadow> shadows;

    if (active) {
      bgCol = Dp.accent; // Electric blue #0066FF
      borderCol = isDark ? const Color(0xFF3385FF) : const Color(0xFF0052CC);
      fgCol = Colors.white;
      shadows = [
        BoxShadow(
          color: const Color(0xFF0066FF).withValues(alpha: isDark ? 0.45 : 0.35),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    } else {
      bgCol = isDark ? const Color(0xFF1E242C) : Colors.white;
      borderCol = isDark ? const Color(0xFF38444D) : const Color(0xFFC0C6CF);
      fgCol = isDark ? const Color(0xFFF0F6FC) : const Color(0xFF141414);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.16),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Mo.fast,
        curve: Mo.easeOutTech,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderCol, width: 1.5),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Drishti.icon(glyph, size: 18, color: fgCol),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppText.dataTiny.copyWith(
                color: fgCol,
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
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
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Dp.canvas.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Dp.hairline),
        ),
        child: Text(
          '© OpenStreetMap · © CARTO · Google API',
          style: TextStyle(
            fontFamily: AppText.mono,
            fontSize: 8,
            letterSpacing: 0.4,
            color: Dp.textMuted,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// The live OPS feed sheet — Mobbin gallery-white sheet with 24px corner geometry.
/// ---------------------------------------------------------------------------
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Dp.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dp.rMd)),
        border: Border(
          top: BorderSide(color: Dp.hairline, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.zero,
          children: [
            _SheetHandle(),
            _SheetHeader(cc),
            HairDivider(color: Dp.hairline, thickness: double.infinity),
            const SizedBox(height: 4),
            for (var i = 0; i < cc.incidents.length; i++)
              _Delayed(
                order: i,
                child: _FeedRow(
                  event: cc.incidents[i],
                  onTap: () => onSelect(cc.incidents[i]),
                ),
              ),
            const SizedBox(height: 96),
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
      height: 24,
      alignment: Alignment.center,
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Dp.hairline,
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
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Drishti.icon(DGlyph.feed, size: 15, color: Dp.ink),
              const SizedBox(width: 8),
              Text(
                'OPS FEED',
                style: TextStyle(
                  fontFamily: AppText.mono,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: Dp.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const LivePill(dense: true, label: 'STREAMING'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Dp.canvasSoft,
                  borderRadius: BorderRadius.circular(Dp.rFull),
                  border: Border.all(color: Dp.hairline),
                ),
                child: Text(
                  '${cc.total}',
                  style: AppText.dataStrong.copyWith(color: Dp.ink, fontSize: 11),
                ),
              ),
            ],
          ),
          if (latest != null) ...[
            const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Dp.canvasSoft,
        borderRadius: BorderRadius.circular(Dp.rSm),
        border: Border.all(color: Dp.hairline),
      ),
      child: Row(
        children: [
          SeverityTag(event.severity, size: 9.5),
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
                        style: AppText.dataStrong.copyWith(
                          color: Dp.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dp.rFull),
                      ),
                      child: Text(
                        event.confLabel,
                        style: monoTxt(9.5, color: col, w: FontWeight.w700, ls: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.busId} · ${event.timeLabel} · ${event.gpsLabel}',
                  style: AppText.dataTiny.copyWith(color: Dp.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Drishti.icon(DGlyph.chevronRight, size: 14, color: Dp.textFaint),
        ],
      ),
    );
  }
}

class _Delayed extends StatelessWidget {
  const _Delayed({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Mo.standard + Duration(milliseconds: (order % 6) * 30),
      curve: Mo.easeOutTech,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: child,
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Dp.canvas,
          borderRadius: BorderRadius.circular(Dp.rSm),
          border: Border.all(color: Dp.hairlineSoft),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Dp.canvasSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Dp.hairline),
              ),
              alignment: Alignment.center,
              child: Drishti.icon(
                _glyphFor(event.kind),
                size: 17,
                color: col,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.kind.label.toUpperCase(),
                        style: AppText.dataStrong.copyWith(
                          fontSize: 12,
                          color: Dp.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SeverityTag(event.severity, size: 8.5),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${event.busId} · ${event.timeLabel} · ${event.confLabel}'
                    '${event.plate != null ? ' · ${event.plate}' : ''}',
                    style: AppText.dataTiny.copyWith(color: Dp.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: event.ageMinutes < 2
                    ? Dp.accent.withValues(alpha: 0.1)
                    : Dp.canvasSoft,
                borderRadius: BorderRadius.circular(Dp.rFull),
                border: Border.all(
                  color: event.ageMinutes < 2
                      ? Dp.accent.withValues(alpha: 0.3)
                      : Dp.hairline,
                ),
              ),
              child: Text(
                event.ageMinutes < 2 ? 'NEW' : event.timeShort,
                style: monoTxt(
                  8.5,
                  color: event.ageMinutes < 2 ? Dp.accent : Dp.textMuted,
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