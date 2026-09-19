import 'dart:math' as math;

import '../app/palette.dart';
import 'models.dart' as m;

/// Static simulation world for the Pune metro network: corridors, zones,
/// bus rests, plate pool. Everything else is derived live from streams.
class SimWorld {
  SimWorld._();

  static const double cityLat = 18.5204;
  static const double cityLng = 73.8567;

  static List<m.Corridor> corridors() => [
        m.Corridor(
          id: 'C1',
          name: 'JM ROAD',
          geo: [
            (18.5486, 73.8720),
            (18.5450, 73.8620),
            (18.5390, 73.8500),
            (18.5330, 73.8400),
            (18.5260, 73.8360),
          ],
          score: 79,
        ),
        m.Corridor(
          id: 'C2',
          name: 'SATARA ROAD',
          geo: [
            (18.5020, 73.8620),
            (18.5110, 73.8580),
            (18.5204, 73.8567),
            (18.5320, 73.8580),
            (18.5420, 73.8610),
          ],
          score: 64,
        ),
        m.Corridor(
          id: 'C3',
          name: 'UNIVERSITY ROAD',
          geo: [
            (18.5520, 73.8700),
            (18.5400, 73.8680),
            (18.5280, 73.8630),
            (18.5204, 73.8567),
          ],
          score: 88,
        ),
        m.Corridor(
          id: 'C4',
          name: 'NAGAR ROAD',
          geo: [
            (18.5204, 73.8567),
            (18.5330, 73.8660),
            (18.5450, 73.8740),
            (18.5600, 73.8820),
          ],
          score: 71,
        ),
        m.Corridor(
          id: 'C5',
          name: 'FB ROAD',
          geo: [
            (18.5110, 73.8460),
            (18.5150, 73.8570),
            (18.5204, 73.8670),
            (18.5270, 73.8780),
          ],
          score: 82,
        ),
        m.Corridor(
          id: 'C6',
          name: 'GH ROAD',
          geo: [
            (18.5320, 73.8840),
            (18.5260, 73.8740),
            (18.5204, 73.8670),
            (18.5120, 73.8590),
          ],
          score: 58,
        ),
      ];

  static List<String> corridorIds() =>
      corridors().map((c) => c.id).toList();

  static List<(String, String)> platePool() => [
        ('MH-12','AB 3456'),
        ('MH-14','CD 7082'),
        ('MH-12','EF 1029'),
        ('MH-14','GH 5561'),
        ('MH-12','JK 8840'),
      ];

  static String randomPlate(Rand r) {
    final p = platePool()[r.intRange(0, platePool().length)];
    final letters = _letters(r);
    return '${p.$1} ${p.$2.substring(0, 2)} $letters ${p.$2.substring(4)}';
  }

  static String _letters(Rand r) {
    const alphabet = 'ABCDEFGHJKLMNPRSTUVWXYZ';
    final buf = StringBuffer();
    for (var i = 0; i < 2; i++) {
      buf.write(alphabet[r.intRange(0, alphabet.length)]);
    }
    return buf.toString();
  }

  /// Zone layout for the O–D sketch.
  static List<m.Zone> zones() => const [
        m.Zone(0, 'KOTHRUD', 0.18, 0.72),
        m.Zone(1, 'DECCAN', 0.44, 0.82),
        m.Zone(2, 'CANTONMENT', 0.7, 0.72),
        m.Zone(3, 'HADAPSAR', 0.82, 0.4),
        m.Zone(4, 'AKURDI', 0.32, 0.16),
      ];

  static const Map<(int, int), double> odPrior = {
    (4, 1): 0.20, (4, 2): 0.12, (4, 3): 0.08,
    (0, 1): 0.16, (0, 2): 0.10,
    (2, 3): 0.14, (1, 3): 0.08,
    (3, 2): 0.10, (3, 4): 0.06, (2, 4): 0.08,
  };

  static (int, int) sampleOD(Rand r, DateTime now) {
    final hour = now.hour;
    final lists = odPrior.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peak = hour >= 8 && hour <= 10 || hour >= 17 && hour <= 20;
    var acc = 0.0;
    final roll = r.next();
    for (final e in lists) {
      acc += e.value * (peak ? 1.35 : 1.0);
      if (roll <= acc) return e.key;
    }
    return lists.first.key;
  }

  static const List<String> busIds = [
    'PB-01', 'PB-02', 'PB-03', 'PB-04', 'PB-05', 'PB-06',
    'PB-07', 'PB-08', 'PB-09', 'PB-10', 'PB-11', 'PB-12',
  ];

  static const String heroBusId = 'PB-01';

  static List<m.Bus> spawnBuses() {
    final cs = corridors();
    final buses = <m.Bus>[];
    var i = 0;
    for (var cIdx = 0; cIdx < cs.length; cIdx++) {
      final c = cs[cIdx];
      final count = cIdx % 3 == 0 ? 2 : 1; // denser on key corridors
      for (var k = 0; k < count && i < busIds.length; k++) {
        final geo = c.geo;
        final seg = i % (geo.length - 1);
        final t = k == 0 ? 0.25 : 0.6;
        final lat = geo[seg].$1 + (geo[seg + 1].$1 - geo[seg].$1) * t;
        final lng = geo[seg].$2 + (geo[seg + 1].$2 - geo[seg].$2) * t;
        final hero = i == 0;
        buses.add(m.Bus(
          id: busIds[i],
          route: '${c.id} · ${c.name}',
          routeId: c.id,
          corridorId: c.id,
          lat: lat,
          lng: lng,
          heading: _heading(geo[seg], geo[seg + 1]),
          speed: 14 + (i % 3) * 4.0,
          hero: hero,
          pathPos: seg * 250.0,
        ));
        i++;
      }
    }
    return buses;
  }

  static double _heading((double, double) a, (double, double) b) {
    final dLat = b.$1 - a.$1;
    final dLng = b.$2 - a.$2;
    return math.atan2(dLng, dLat) * 180 / math.pi;
  }

  /// One plausible 24h congestion baseline (index = hour).
  static List<double> congestionBaseline() => [
        0.30, 0.25, 0.22, 0.20, 0.22, 0.38,
        0.62, 0.86, 0.92, 0.74, 0.55, 0.52,
        0.58, 0.62, 0.60, 0.66, 0.78, 0.95,
        0.98, 0.88, 0.68, 0.50, 0.38, 0.30,
      ];
}