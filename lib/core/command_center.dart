import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
class CommandCenter extends ChangeNotifier with WidgetsBindingObserver {
  CommandCenter({bool simulate = true}) {
    WidgetsBinding.instance.addObserver(this);
    final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    Dp.isDark = systemBrightness == Brightness.dark;
    _fleet = FleetService();
    _svc = DetectionService(_fleet);
    _seed();
    _listen();
    if (simulate) {
      _decay = Timer.periodic(const Duration(seconds: 5), (_) => _decayTick());
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == ThemeMode.system) {
      Dp.isDark = isDarkMode;
      notifyListeners();
    }
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => switch (_themeMode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
  };

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    Dp.isDark = isDarkMode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      setThemeMode(Dp.isDark ? ThemeMode.light : ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.system);
    }
  }

  // Configurable System Settings
  bool _showCorridors = true;
  bool get showCorridors => _showCorridors;
  void toggleCorridors() {
    _showCorridors = !_showCorridors;
    notifyListeners();
  }

  bool _showHeatmap = true;
  bool get showHeatmap => _showHeatmap;
  void toggleHeatmap() {
    _showHeatmap = !_showHeatmap;
    notifyListeners();
  }

  double _confidenceThreshold = 0.92;
  double get confidenceThreshold => _confidenceThreshold;
  void setConfidenceThreshold(double v) {
    _confidenceThreshold = v;
    notifyListeners();
  }

  bool _autoDispatch = true;
  bool get autoDispatch => _autoDispatch;
  void toggleAutoDispatch() {
    _autoDispatch = !_autoDispatch;
    notifyListeners();
  }

  bool _plateOcrEnabled = true;
  bool get plateOcrEnabled => _plateOcrEnabled;
  void togglePlateOcr() {
    _plateOcrEnabled = !_plateOcrEnabled;
    notifyListeners();
  }

  void clearTelemetryCache() {
    _incidents.clear();
    for (final k in DetectionKind.values) {
      _kindCounts[k] = 0;
    }
    for (final s in SeverityClass.values) {
      _severityCounts[s] = 0;
    }
    _seed();
    notifyListeners();
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

  // --- Mobile Field Operations & Route Scope ---
  String _mobileAssignedRoute = 'ROUTE 12';
  String get mobileAssignedRoute => _mobileAssignedRoute;
  void setMobileAssignedRoute(String route) {
    _mobileAssignedRoute = route;
    notifyListeners();
  }

  List<String> get availableRoutes => const [
    'ROUTE 12',
    'ROUTE 08',
    'ROUTE 04',
    'ROUTE 19',
    'ROUTE 27',
  ];

  /// Mobile only sees alerts on their assigned route/zone — never the whole city fleet!
  List<DetectionEvent> get mobileRouteIncidents => _incidents
      .where((e) => e.busRoute.toUpperCase() == _mobileAssignedRoute.toUpperCase())
      .toList();

  /// Personal activity log for field worker
  List<DetectionEvent> get myResolvedToday => _incidents
      .where((e) => e.status == IncidentStatus.resolved)
      .toList();

  // --- Offline Tolerance & Queue ---
  bool _isFieldOffline = false;
  bool get isFieldOffline => _isFieldOffline;
  final List<VoidCallback> _offlineQueue = [];
  int get pendingSyncCount => _offlineQueue.length;

  void toggleFieldOffline() {
    _isFieldOffline = !_isFieldOffline;
    if (!_isFieldOffline && _offlineQueue.isNotEmpty) {
      syncOfflineQueue();
    }
    notifyListeners();
  }

  void syncOfflineQueue() {
    final actions = List<VoidCallback>.from(_offlineQueue);
    _offlineQueue.clear();
    for (final act in actions) {
      act();
    }
    notifyListeners();
  }

  // --- Web Assign Action (Web ASSIGNS to maintenance crew) ---
  void assignIncident(String id, String crewName) {
    final index = _incidents.indexWhere((e) => e.id == id);
    if (index != -1) {
      _incidents[index] = _incidents[index].copyWith(
        status: IncidentStatus.assigned,
        assignedCrew: crewName,
      );
      notifyListeners();
    }
  }

  // --- Mobile Verify Action (Field crew confirms/rejects on-site) ---
  void verifyIncident(String id, {required bool confirmed}) {
    if (_isFieldOffline) {
      _offlineQueue.add(() => verifyIncident(id, confirmed: confirmed));
      notifyListeners();
      return;
    }
    final index = _incidents.indexWhere((e) => e.id == id);
    if (index != -1) {
      _incidents[index] = _incidents[index].copyWith(
        status: IncidentStatus.verified,
        verifyVerdict: confirmed ? 'Confirmed road defect on-site' : 'False positive / Surface debris',
      );
      notifyListeners();
    }
  }

  // --- Mobile Resolve Action (Field crew marks repaired & closed) ---
  void resolveIncident(String id, {String? remark}) {
    if (_isFieldOffline) {
      _offlineQueue.add(() => resolveIncident(id, remark: remark));
      notifyListeners();
      return;
    }
    final index = _incidents.indexWhere((e) => e.id == id);
    if (index != -1) {
      _incidents[index] = _incidents[index].copyWith(
        status: IncidentStatus.resolved,
        resolutionNote: remark ?? 'Cold-mix asphalt patched & sealed',
        resolvedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // --- Mobile Human-in-the-Loop Manual Flag ---
  void addManualFlag({
    required DetectionKind kind,
    required String note,
    required double lat,
    required double lng,
    required String route,
  }) {
    if (_isFieldOffline) {
      _offlineQueue.add(() => addManualFlag(
            kind: kind,
            note: note,
            lat: lat,
            lng: lng,
            route: route,
          ));
      notifyListeners();
      return;
    }

    final manualEvent = DetectionEvent(
      id: 'MAN-${DateTime.now().millisecondsSinceEpoch % 10000}',
      kind: kind,
      severity: kind.baseSeverity,
      confidence: 1.0,
      lat: lat,
      lng: lng,
      ts: DateTime.now(),
      busId: 'FIELD-CREW-04',
      busRoute: route,
      corridorId: 'CORR-01',
      sceneSeed: 8888,
      sceneTime: 0,
      status: IncidentStatus.verified,
      verifyVerdict: 'Manual field observation: $note',
      isManualFlag: true,
      assignedCrew: 'Field Crew 04 (You)',
    );

    _ingest(manualEvent);
    notifyListeners();
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
    for (var i = 0; i < history.length; i++) {
      var e = history[i];
      if (i == 1) {
        e = e.copyWith(
          status: IncidentStatus.assigned,
          assignedCrew: 'PWD Field Crew 04 (You)',
        );
      } else if (i == 2) {
        e = e.copyWith(
          status: IncidentStatus.verified,
          assignedCrew: 'PWD Field Crew 04 (You)',
          verifyVerdict: 'Confirmed on-site defect',
        );
      } else if (i == 4) {
        e = e.copyWith(
          status: IncidentStatus.resolved,
          assignedCrew: 'PWD Field Crew 04 (You)',
          resolutionNote: 'Cold-mix asphalt patch applied',
          resolvedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
      }
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
    WidgetsBinding.instance.removeObserver(this);
    _decay?.cancel();
    _sub?.cancel();
    _fleet.dispose();
    _svc.dispose();
    super.dispose();
  }
}