import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../app/palette.dart';
import 'detection_service.dart';
import 'fleet_service.dart';
import 'models.dart';
import 'sim.dart';

/// The single source of truth for the whole demo pipeline:
///
///   edge-AI stream  ->  incidents  ->  map pins / feed rows
///                     ->  analytics (heat, corridor conditions, congestion,
///                        defect breakdown, origin–destination)
///
/// Everything a screen displays is derived from [DetectionEvent]s that flow
/// through here, so the judge can trace one detection end to end.
class CommandCenter extends ChangeNotifier {
  CommandCenter({bool simulate = true}) {
    _fleet = FleetService();
    _svc = DetectionService(_fleet);
    _seed();
    _listen();
    if (simulate) {
      _decay = Timer.periodic(const Duration(seconds: 5), (_) => _decayTick());
    }
  }

  late final FleetService _fleet;
  late final DetectionService _svc;
  Timer? _decay;
  StreamSubscription<DetectionEvent>? _sub;

  final List<DetectionEvent> _incidents = [];
  final Map<DetectionKind, int> _kindCounts = {
    for (final k in DetectionKind.values) k: 0,
  };
  final Map<SeverityClass, int> _severityCounts = {
    for (final s in SeverityClass.values) s: 0,
  };
  final List<HeatPoint> _heat = [];
  final List<Ripple> _ripples = [];
  late final List<double> _congestion;
  late final List<Corridor> _corridors;
  final Map<(int, int), int> _od = {};

  int _total = 0;
  DetectionEvent? _latest;

  String get heroBusId => SimWorld.heroBusId;
  List<DetectionEvent> get incidents => List.unmodifiable(_incidents);
  int get total => _total;

  List<DetectionEvent> get recentHistory => List.unmodifiable(_incidents);
  DetectionEvent? get latest => _latest;
  List<Ripple> get ripples => List.unmodifiable(_ripples);
  List<HeatPoint> get heatPoints => List.unmodifiable(_heat);
  List<Bus> get buses => _fleet.positions.value;
  ValueNotifier<List<Bus>> get busPositions => _fleet.positions;
  List<Corridor> get corridors => _corridors;
  List<double> get congestionSeries => List.unmodifiable(_congestion);
  Map<(int, int), int> get odCounts => Map.of(_od);
  int get busesOnline => _fleet.positions.value.length;

  int countOf(DetectionKind k) => _kindCounts[k] ?? 0;
  int countOfSeverity(SeverityClass s) => _severityCounts[s] ?? 0;

  DetectionEvent? byId(String id) {
    for (final e in _incidents) {
      if (e.id == id) return e;
    }
    return null;
  }

  bool get isLive => _total > 0;

  int get coveragePercent {
    // Coverage tracks how much of the corridor grid has been surveyed recently.
    final surveyed = _corridors.where((c) => c.score < 96).length;
    return (70 + surveyed * 4).clamp(0, 96);
  }

  void _seed() {
    _congestion = SimWorld.congestionBaseline();
    _corridors = SimWorld.corridors();

    // Seed recent history so pins/heat/feed/charts feel alive on first frame.
    final history = _svc.seedHistory();
    for (final e in history) {
      _ingest(e, seed: true);
    }
  }

  void _listen() {
    _sub = _svc.events.listen(_onEvent);
  }

  void _onEvent(DetectionEvent e) {
    _ingest(e);
    notifyListeners();
  }

  void _ingest(DetectionEvent e, {bool seed = false}) {
    _incidents.insert(0, e);
    if (_incidents.length > 80) _incidents.removeLast();

    _kindCounts[e.kind] = (_kindCounts[e.kind] ?? 0) + 1;
    _severityCounts[e.severity] = (_severityCounts[e.severity] ?? 0) + 1;
    _total++;

    if (!seed) {
      _latest = e;
      _ripples.add(Ripple(e, DateTime.now()));
    }

    // Heat — a live weighted layer, not a static image.
    final heatWeight = switch (e.kind) {
      DetectionKind.congestion => 0.95,
      DetectionKind.plateCapture => 0.85,
      DetectionKind.roadFracture => 0.75,
      DetectionKind.pothole => 0.65,
      DetectionKind.pedRisk => 0.6,
      DetectionKind.signLoss => 0.45,
    };
    _heat.add(HeatPoint(
      lat: e.lat,
      lng: e.lng,
      weight: heatWeight,
      at: e.ts,
    ));
    if (_heat.length > 140) _heat.removeAt(0);

    // Congestion — bump the current hour bucket.
    final hour = e.ts.hour.clamp(0, 23);
    final bump = seed
        ? 0.02
        : switch (e.kind) {
            DetectionKind.congestion => 0.09,
            DetectionKind.pedRisk => 0.05,
            DetectionKind.roadFracture => 0.04,
            DetectionKind.pothole => 0.03,
            _ => 0.02,
          };
    _congestion[hour] = (_congestion[hour] + bump).clamp(0.0, 1.0);

    // Corridor condition decays when defects are sighted there.
    for (final c in _corridors) {
      if (c.id == e.corridorId) {
        c.score = math
            .max(38, c.score - _degrade(e.kind))
            .clamp(0.0, 100.0)
            .toDouble();
      }
    }

    // Origin–destination counts for the trip sketch.
    final od = SimWorld.sampleOD(Rand(e.sceneSeed + e.ts.minute), e.ts);
    _od[od] = (_od[od] ?? 0) + 1;

    // Keep ripple pulse short.
    _ripples.removeWhere((r) =>
        DateTime.now().difference(r.born).inMilliseconds > 2000);
    _heat.removeWhere((h) =>
        DateTime.now().difference(h.at).inSeconds > 900);
  }

  double _degrade(DetectionKind k) {
    switch (k) {
      case DetectionKind.roadFracture:
        return 2.6;
      case DetectionKind.pothole:
        return 1.9;
      case DetectionKind.pedRisk:
        return 1.2;
      case DetectionKind.signLoss:
        return 0.9;
      case DetectionKind.congestion:
        return 0.5;
      case DetectionKind.plateCapture:
        return 0.8;
    }
  }

  void _decayTick() {
    // Slow recovery for corridor condition (survey cadence).
    for (final c in _corridors) {
      if (c.score < 96) c.score = math.min(96, c.score + 0.15);
    }
    _ripples.removeWhere((r) =>
        DateTime.now().difference(r.born).inMilliseconds > 2000);
    _heat.removeWhere((h) =>
        DateTime.now().difference(h.at).inSeconds > 900);
    notifyListeners();
  }

  /// Keeps screens from rebuilding holdovers after disposal.
  String get nowClock {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  void dispose() {
    _decay?.cancel();
    _sub?.cancel();
    _fleet.dispose();
    _svc.dispose();
    super.dispose();
  }
}