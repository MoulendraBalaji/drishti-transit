import 'dart:async';

import '../app/palette.dart';
import 'fleet_service.dart';
import 'models.dart';
import 'sim.dart';

/// The simulated edge-AI. Emits [DetectionEvent]s on a broadcast stream at
/// believable intervals, taking turns between the hero bus (the one the Edge
/// camera tab watches) and the rest of the fleet. Every emitted event drives
/// the map, the feed and the analytics — one causal stream.
class DetectionService {
  DetectionService(this._fleet) {
    _controller = StreamController<DetectionEvent>.broadcast(
      onListen: _schedule,
    );
    _rand = Rand(DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);
  }

  final FleetService _fleet;
  late Rand _rand;
  late final StreamController<DetectionEvent> _controller;
  Timer? _timer;
  int _emitCount = 0;
  bool _disposed = false;

  Stream<DetectionEvent> get events => _controller.stream;

  static const double _rangeLat = 0.0014;
  static const double _rangeLng = 0.0016;

  void _schedule() {
    _timer?.cancel();
    if (_disposed) return;
    final delay = Duration(milliseconds: 3400 + _rand.intRange(0, 3600));
    _timer = Timer(delay, _emitOne);
  }

  void _emitOne() {
    if (_disposed) return;
    // Alternate: ~half of events come from the hero bus so the Edge camera
    // tab is causally linked to map/feed/analytics within seconds.
    final buses = _fleet.positions.value;
    if (buses.isEmpty) {
      _schedule();
      return;
    }
    final hero = _fleet.busById(SimWorld.heroBusId);
    final useHero = _emitCount % 2 == 0 && hero != null;
    final bus =
        hero != null && useHero ? hero : buses[_rand.intRange(0, buses.length)];

    final kind = _sampleKind();
    final confidence = _rand.range(0.86, 0.98);
    final severity = kind.baseSeverity;
    final scale = kind == DetectionKind.plateCapture ? 1.4 : 1.0;

    // Jitter GPS near the bus; plate capture pulls toward a crossing point.
    final lat = bus.lat + _rand.range(-_rangeLat, _rangeLat) * scale;
    final lng = bus.lng + _rand.range(-_rangeLng, _rangeLng) * scale;

    final now = DateTime.now();
    final sceneSeed =
        (bus.id.hashCode * 31 + _emitCount * 7919 + now.minute) & 0x7FFFFFFF;
    final sceneTime = _rand.range(2.0, 14.0);

    final event = DetectionEvent(
      id: 'dt-${now.millisecondsSinceEpoch}-$_emitCount',
      kind: kind,
      severity: severity,
      confidence: confidence,
      lat: lat,
      lng: lng,
      ts: now,
      busId: bus.id,
      busRoute: bus.route,
      corridorId: bus.corridorId,
      sceneSeed: sceneSeed,
      sceneTime: sceneTime,
      plate:
          kind == DetectionKind.plateCapture ? SimWorld.randomPlate(_rand) : null,
    );

    _emitCount++;
    _controller.add(event);
    _schedule();
  }

  DetectionKind _sampleKind() {
    final roll = _rand.next();
    if (roll < 0.20) return DetectionKind.pothole;
    if (roll < 0.38) return DetectionKind.roadFracture;
    if (roll < 0.55) return DetectionKind.signLoss;
    if (roll < 0.74) return DetectionKind.congestion;
    if (roll < 0.90) return DetectionKind.pedRisk;
    return DetectionKind.plateCapture;
  }

  /// A short arc of plausible history so maps/charts are never empty at launch.
  List<DetectionEvent> seedHistory() {
    final out = <DetectionEvent>[];
    final corridors = SimWorld.corridors();
    final now = DateTime.now();
    for (var i = 0; i < 34; i++) {
      final minutesAgo = Rand(now.millisecondsSinceEpoch + i)
          .intRange(0, 13);
      final c = corridors[i % corridors.length];
      final geo = c.geo;
      final seg = i % (geo.length - 1);
      final t = ((i * 37) % 90) / 100.0;
      final lat = geo[seg].$1 + (geo[seg + 1].$1 - geo[seg].$1) * t;
      final lng = geo[seg].$2 + (geo[seg + 1].$2 - geo[seg].$2) * t;
      final kind = _sampleKind();
      out.add(DetectionEvent(
        id: 'seed-$i',
        kind: kind,
        severity: kind.baseSeverity,
        confidence: _rand.range(0.84, 0.97),
        lat: lat + _rand.range(-0.0008, 0.0008),
        lng: lng + _rand.range(-0.0008, 0.0008),
        ts: now.subtract(Duration(minutes: minutesAgo, seconds: _rand.intRange(0, 59))),
        busId: SimWorld.busIds[_rand.intRange(0, SimWorld.busIds.length)],
        busRoute: '${c.id} · ${c.name}',
        corridorId: c.id,
        sceneSeed: i * 4243 + 7,
        sceneTime: _rand.range(2, 14),
        plate:
            kind == DetectionKind.plateCapture ? SimWorld.randomPlate(_rand) : null,
      ));
    }
    return out;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _controller.close();
  }
}