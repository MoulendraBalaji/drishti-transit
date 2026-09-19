import '../app/palette.dart';

/// Detection types the edge-AI recognises on a moving bus.
enum DetectionKind {
  pothole,
  roadFracture,
  signLoss,
  congestion,
  pedRisk,
  plateCapture,
}

extension DetectionKindX on DetectionKind {
  String get label {
    switch (this) {
      case DetectionKind.pothole:
        return 'Pothole';
      case DetectionKind.roadFracture:
        return 'Damaged road';
      case DetectionKind.signLoss:
        return 'Missing signage';
      case DetectionKind.congestion:
        return 'Vehicle density';
      case DetectionKind.pedRisk:
        return 'Pedestrian risk';
      case DetectionKind.plateCapture:
        return 'Hit-and-run plate';
    }
  }

  String get code {
    switch (this) {
      case DetectionKind.pothole:
        return 'POT';
      case DetectionKind.roadFracture:
        return 'RAD';
      case DetectionKind.signLoss:
        return 'SGN';
      case DetectionKind.congestion:
        return 'DEN';
      case DetectionKind.pedRisk:
        return 'PED';
      case DetectionKind.plateCapture:
        return 'HRP';
    }
  }

  String get detail {
    switch (this) {
      case DetectionKind.pothole:
        return 'Impact crater in carriageway, 34×22 cm, on bus lane.';
      case DetectionKind.roadFracture:
        return 'Surface fracture / sinkage across travel lane.';
      case DetectionKind.signLoss:
        return 'Expected regulatory sign missing from mast.';
      case DetectionKind.congestion:
        return 'Queue density above threshold for this hour.';
      case DetectionKind.pedRisk:
        return 'Pedestrian crossing path without protected signal.';
      case DetectionKind.plateCapture:
        return 'Vehicle left scene at speed; plate captured.';
    }
  }

  String get unit => 'type/$code';

  SeverityClass get baseSeverity {
    switch (this) {
      case DetectionKind.pothole:
        return SeverityClass.watch;
      case DetectionKind.roadFracture:
        return SeverityClass.elevated;
      case DetectionKind.signLoss:
        return SeverityClass.note;
      case DetectionKind.congestion:
        return SeverityClass.note;
      case DetectionKind.pedRisk:
        return SeverityClass.elevated;
      case DetectionKind.plateCapture:
        return SeverityClass.critical;
    }
  }
}

/// A single detection emitted by the simulated edge-AI, carrying everything the
/// rest of the product needs (map pin, feed row, analytics, evidence frame).
class DetectionEvent {
  const DetectionEvent({
    required this.id,
    required this.kind,
    required this.severity,
    required this.confidence,
    required this.lat,
    required this.lng,
    required this.ts,
    required this.busId,
    required this.busRoute,
    required this.corridorId,
    required this.sceneSeed,
    required this.sceneTime,
    this.plate,
  });

  final String id;
  final DetectionKind kind;
  final SeverityClass severity;
  final double confidence;
  final double lat;
  final double lng;
  final DateTime ts;
  final String busId;
  final String busRoute;
  final String corridorId;

  /// Seed + frozen scene time so the evidence frame is deterministic.
  final int sceneSeed;
  final double sceneTime;
  final String? plate;

  String get gpsLabel => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(ts.hour)}:${two(ts.minute)}:${two(ts.second)}';
  }

  String get timeShort {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(ts.hour)}:${two(ts.minute)}';
  }

  int get ageMinutes => DateTime.now().difference(ts).inMinutes;

  String get confLabel => '${(confidence * 100).toStringAsFixed(0)}%';

  String get summary =>
      '${kind.label} ${plate != null ? '· $plate' : ''}';
}

/// A connected bus acting as an edge sensor.
class Bus {
  Bus({
    required this.id,
    required this.route,
    required this.routeId,
    required this.corridorId,
    required this.lat,
    required this.lng,
    this.heading = 0,
    this.speed = 18,
    this.hero = false,
    this.pathPos = 0,
    this.dir = 1,
  });

  final String id;
  final String route;
  final String routeId;
  final String corridorId;
  double lat;
  double lng;
  double heading;
  double speed;
  final bool hero;

  /// Distance (m) along the corridor polyline for ping-pong movement.
  double pathPos;
  int dir;

  String get gpsLabel => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

/// A weighted heat sample on the map.
class HeatPoint {
  HeatPoint({required this.lat, required this.lng, required this.weight, required this.at});
  final double lat;
  final double lng;
  final double weight;
  final DateTime at;
}

/// One live map ripple (an alert that just arrived).
class Ripple {
  Ripple(this.event, this.born);
  final DetectionEvent event;
  final DateTime born;
}

/// A corridor polyline with live condition score.
class Corridor {
  Corridor({required this.id, required this.name, required this.geo, this.score = 84});
  final String id;
  final String name;
  final List<(double, double)> geo; // lat,lng waypoints
  double score; // 0..100
}

/// A zone used by the origin–destination sketch.
class Zone {
  const Zone(this.id, this.name, this.x, this.y);
  final int id;
  final String name;
  final double x; // layout 0..1
  final double y;
}