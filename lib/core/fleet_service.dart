import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'sim.dart';

/// Advances the bus fleet along corridor polylines at ~8 fps using a clean
/// ping-pong path parameterization, and exposes positions on a [ValueNotifier]
/// so only the map marker layer rebuilds.
class FleetService {
  FleetService() {
    _buses = SimWorld.spawnBuses();
    _segments = _buildSegments();
    _ticker = Timer.periodic(const Duration(milliseconds: 120), (_) => _tick());
  }

  static const double _latMeters = 111132.0;

  late final List<Bus> _buses;
  late final Timer _ticker;

  /// corridorId -> list of (segStartCumM, segLenM, from, to)
  late final Map<String, List<_Seg>> _segments;

  final ValueNotifier<List<Bus>> _positions = ValueNotifier(const []);
  ValueNotifier<List<Bus>> get positions => _positions;

  Bus? busById(String id) {
    for (final b in _buses) {
      if (b.id == id) return b;
    }
    return null;
  }

  Map<String, List<_Seg>> _buildSegments() {
    final map = <String, List<_Seg>>{};
    for (final c in SimWorld.corridors()) {
      final segs = <_Seg>[];
      var cum = 0.0;
      for (var i = 0; i < c.geo.length - 1; i++) {
        final a = c.geo[i];
        final b = c.geo[i + 1];
        final cosLat = math.cos(a.$1 * math.pi / 180);
        final dLat = (b.$1 - a.$1) * _latMeters;
        final dLng = (b.$2 - a.$2) * _latMeters * cosLat;
        final len = math.sqrt(dLat * dLat + dLng * dLng);
        segs.add(_Seg(cum, len, a, b));
        cum += len;
      }
      map[c.id] = segs;
    }
    return map;
  }

  double _totalMeters(String corridorId) {
    final segs = _segments[corridorId]!;
    return segs.isEmpty ? 0 : segs.last.cum + segs.last.len;
  }

  void _tick() {
    for (final bus in _buses) {
      final total = _totalMeters(bus.corridorId);
      if (total <= 0) continue;
      final step = (bus.speed / 3.6) * 0.12 * bus.dir;
      bus.pathPos += step;
      if (bus.pathPos >= total) {
        bus.pathPos = total;
        bus.dir = -1;
      } else if (bus.pathPos <= 0) {
        bus.pathPos = 0;
        bus.dir = 1;
      }
      _place(bus);
    }
    _positions.value = List.of(_buses);
  }

  void _place(Bus bus) {
    final segs = _segments[bus.corridorId]!;
    if (segs.isEmpty) return;
    for (final s in segs) {
      if (bus.pathPos >= s.cum && bus.pathPos <= s.cum + s.len) {
        final t = s.len == 0 ? 0.0 : (bus.pathPos - s.cum) / s.len;
        final lat = s.a.$1 + (s.b.$1 - s.a.$1) * t;
        final lng = s.a.$2 + (s.b.$2 - s.a.$2) * t;
        bus.lat = lat;
        bus.lng = lng;
        bus.heading =
            math.atan2(s.b.$2 - s.a.$2, s.b.$1 - s.a.$1) * 180 / math.pi;
        break;
      }
    }
  }

  void dispose() {
    _ticker.cancel();
    _positions.dispose();
  }
}

class _Seg {
  _Seg(this.cum, this.len, this.a, this.b);
  final double cum;
  final double len;
  final (double, double) a;
  final (double, double) b;
}