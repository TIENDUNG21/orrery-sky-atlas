import 'dart:math' as math;

import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';

import '../data/locations.dart';
import '../format/format.dart';
import '../search/search_index.dart';
import '../sky/sky_scene.dart';

class DetailRow {
  const DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class ObjectDetails {
  const ObjectDetails({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<DetailRow> rows;
}

/// Rise, transit and set within the observer's local calendar day.
class LocalEvents {
  const LocalEvents({
    this.rise,
    this.transit,
    this.set,
    this.alwaysAbove = false,
    this.alwaysBelow = false,
  });

  final DateTime? rise;
  final DateTime? transit;
  final DateTime? set;
  final bool alwaysAbove;
  final bool alwaysBelow;
}

/// Meeus's method works on UT days; a local day straddles two of them, so
/// both are computed and only the events inside the local day are kept.
LocalEvents eventsForLocalDay(
  Equatorial Function(double jdTt) position,
  Location location,
  DateTime instant,
  double h0Deg,
) {
  final local = location.localTime(instant);
  final start = DateTime.utc(
    local.year,
    local.month,
    local.day,
  ).subtract(location.utcOffset);
  final end = start.add(const Duration(days: 1));
  DateTime? rise;
  DateTime? transit;
  DateTime? set;
  var above = true;
  var below = true;

  DateTime? pick(DateTime? current, DateTime? candidate) {
    if (candidate == null ||
        candidate.isBefore(start) ||
        !candidate.isBefore(end)) {
      return current;
    }
    return current == null || candidate.isBefore(current) ? candidate : current;
  }

  for (final day in [start, start.add(const Duration(days: 1))]) {
    final r = riseTransitSetForDay(position, day, location.observer, h0Deg);
    above &= r.alwaysAbove;
    below &= r.alwaysBelow;
    rise = pick(rise, r.riseTime);
    transit = pick(transit, r.transitTime);
    set = pick(set, r.setTime);
  }
  return LocalEvents(
    rise: rise,
    transit: transit,
    set: set,
    alwaysAbove: above,
    alwaysBelow: below,
  );
}

String _signed(double v, int digits) {
  final text = v.abs().toStringAsFixed(digits);
  return v < 0 ? '−$text' : '+$text';
}

String _magnitude(double v) =>
    v < 0 ? '−${v.abs().toStringAsFixed(2)}' : v.toStringAsFixed(2);

List<DetailRow> _positionRows(Horizontal h) => [
  DetailRow('Altitude', '${_signed(h.altDeg, 1)}°'),
  DetailRow(
    'Azimuth',
    '${h.azDeg.toStringAsFixed(1)}° ${compassPoint(h.azDeg)}',
  ),
];

List<DetailRow> _eventRows(LocalEvents e, Location location) {
  String at(DateTime? t) =>
      t == null ? 'not today' : formatClock(location.localTime(t));
  if (e.alwaysAbove) {
    return [
      const DetailRow('Rise and set', 'Circumpolar'),
      DetailRow('Transits', at(e.transit)),
    ];
  }
  if (e.alwaysBelow) return const [DetailRow('Rise and set', 'Never rises')];
  return [
    DetailRow('Rises', at(e.rise)),
    DetailRow('Transits', at(e.transit)),
    DetailRow('Sets', at(e.set)),
  ];
}

DetailRow _equatorialRow(String label, Equatorial eq) =>
    DetailRow(label, '${formatHms(eq.raDeg)}  ${formatDms(eq.decDeg)}');

/// Rows for the object with [id] as seen in [scene], or null if unknown.
ObjectDetails? describeObject(
  String id, {
  required SkyScene scene,
  required SkyCatalog catalog,
  required Location location,
}) {
  final instant = scene.time.toDateTime();
  final hr = hrFromId(id);
  if (hr != null) {
    final star = catalog.starByHr(hr);
    return star == null ? null : _star(star, catalog, scene, location, instant);
  }
  final abbr = abbrFromId(id);
  if (abbr != null) {
    final c = catalog.constellation(abbr);
    return c == null ? null : _constellation(c, catalog);
  }
  final body = scene.bodies.where((b) => b.id == id).firstOrNull;
  if (body == null) return null;
  return switch (body.kind) {
    BodyKind.sun => _sun(body, scene, location, instant),
    BodyKind.moon => _moon(body, scene, location, instant),
    BodyKind.planet => _planet(body, scene, location, instant),
  };
}

ObjectDetails _star(
  Star s,
  SkyCatalog catalog,
  SkyScene scene,
  Location location,
  DateTime instant,
) {
  final d = s.designation;
  final constellation = d.constellation == null
      ? null
      : catalog.constellation(d.constellation!);
  final designations = [
    if (d.short.isNotEmpty) d.short,
    if (d.bayer != null && d.flamsteed != null)
      '${d.flamsteed} ${d.constellation}',
    'HR ${s.hr}',
  ];
  Equatorial position(double jdTt) => precessFromJ2000(
    applyProperMotion(
      s.j2000,
      pmRaCosDecMasPerYear: s.pmRaMas.toDouble(),
      pmDecMasPerYear: s.pmDecMas.toDouble(),
      years: (jdTt - j2000) / 365.25,
    ),
    jdTt,
  );
  final enu = scene.enuOfDate(position(scene.time.jdTt));
  final bv = s.bv;
  return ObjectDetails(
    title: s.displayName,
    subtitle: constellation == null ? 'Star' : 'Star in ${constellation.name}',
    rows: [
      DetailRow('Designation', designations.join(' · ')),
      DetailRow('Magnitude (V)', _magnitude(s.vmag)),
      if (bv != null) DetailRow('Colour index (B−V)', _signed(bv, 2)),
      if (s.spectralType.isNotEmpty) DetailRow('Spectral type', s.spectralType),
      if (s.parallaxMas case final p? when p > 0)
        DetailRow('Parallax', '$p mas'),
      _equatorialRow('RA, Dec (J2000)', s.j2000),
      ..._positionRows(Horizontal.fromVector(enu)),
      ..._eventRows(
        eventsForLocalDay(position, location, instant, h0Stars),
        location,
      ),
    ],
  );
}

ObjectDetails _planet(
  BodyState body,
  SkyScene scene,
  Location location,
  DateTime instant,
) {
  final planet = body.planet!;
  final p = planetPosition(planet, scene.time.jdTt);
  final lightMinutes = p.lightTimeDays * 24 * 60;
  return ObjectDetails(
    title: body.name,
    subtitle: 'Planet',
    rows: [
      DetailRow('Magnitude (V)', _magnitude(p.magnitude)),
      DetailRow(
        'Distance',
        '${p.distanceAu.toStringAsFixed(3)} AU '
            '(${lightMinutes.toStringAsFixed(1)} light-minutes)',
      ),
      DetailRow('Illuminated', '${(p.illuminatedFraction * 100).round()}%'),
      DetailRow(
        'Elongation',
        '${p.elongationDeg.toStringAsFixed(1)}° from the Sun',
      ),
      _equatorialRow('RA, Dec (of date)', p.apparent),
      ..._positionRows(body.horizontal),
      ..._eventRows(
        eventsForLocalDay(
          (jd) => planetPosition(planet, jd).apparent,
          location,
          instant,
          h0Stars,
        ),
        location,
      ),
    ],
  );
}

ObjectDetails _moon(
  BodyState body,
  SkyScene scene,
  Location location,
  DateTime instant,
) {
  final phase = scene.moonPhase;
  String next(LunarPhaseKind kind) => formatDateTime(
    location.localTime(
      AstroTime.fromJulianDayTt(findLunarPhase(scene.time.jdTt, kind))
          .toDateTime(),
    ),
  );
  final km = scene.moon.distanceKm.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return ObjectDetails(
    title: 'Moon',
    subtitle: phase.name.label,
    rows: [
      DetailRow('Phase', phase.name.label),
      DetailRow('Illuminated', '${(phase.illuminatedFraction * 100).round()}%'),
      DetailRow('Age', '${phase.ageDays.toStringAsFixed(1)} days'),
      DetailRow('Distance', '$km km'),
      DetailRow('Next new Moon', next(LunarPhaseKind.newMoon)),
      DetailRow('Next full Moon', next(LunarPhaseKind.fullMoon)),
      _equatorialRow('RA, Dec (of date)', body.apparent),
      ..._positionRows(body.horizontal),
      ..._eventRows(
        eventsForLocalDay(
          (jd) => moonPosition(jd).apparent,
          location,
          instant,
          h0Moon(scene.moon.parallaxDeg),
        ),
        location,
      ),
    ],
  );
}

ObjectDetails _sun(
  BodyState body,
  SkyScene scene,
  Location location,
  DateTime instant,
) {
  return ObjectDetails(
    title: 'Sun',
    subtitle: 'Star',
    rows: [
      DetailRow('Distance', '${scene.sun.distanceAu.toStringAsFixed(4)} AU'),
      _equatorialRow('RA, Dec (of date)', body.apparent),
      ..._positionRows(body.horizontal),
      ..._eventRows(
        eventsForLocalDay(
          (jd) => sunPosition(jd).apparent,
          location,
          instant,
          h0Sun,
        ),
        location,
      ),
    ],
  );
}

ObjectDetails _constellation(ConstellationInfo c, SkyCatalog catalog) {
  final members = {for (final line in c.polylines) ...line}
      .map(catalog.starByHr)
      .whereType<Star>()
      .toList();
  final brightest = members.isEmpty
      ? null
      : members.reduce((a, b) => a.vmag <= b.vmag ? a : b);
  return ObjectDetails(
    title: c.name,
    subtitle: 'Constellation',
    rows: [
      DetailRow('Abbreviation', c.abbr),
      DetailRow('Genitive', c.genitive),
      DetailRow('Stars in the figure', '${members.length}'),
      if (brightest != null)
        DetailRow(
          'Brightest star',
          '${brightest.displayName} (V ${_magnitude(brightest.vmag)})',
        ),
      DetailRow('Figure span', '${_span(members).toStringAsFixed(0)}° across'),
    ],
  );
}

/// Largest angular distance between two stars of a figure.
double _span(List<Star> stars) {
  var widest = 0.0;
  for (var i = 0; i < stars.length; i++) {
    for (var j = i + 1; j < stars.length; j++) {
      widest = math.max(
        widest,
        angularSeparationDeg(stars[i].j2000, stars[j].j2000),
      );
    }
  }
  return widest;
}
