import 'dart:io';

import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/sky/sky_scene.dart';

void main() {
  final catalog = decodeCatalog(
    File('assets/catalog/sky.bin').readAsBytesSync(),
  );
  final field = StarField(catalog);
  final hanoi = Observer(latitudeDeg: 21.0285, longitudeDeg: 105.8542);
  final time = AstroTime.fromDateTime(DateTime.utc(2026, 11, 17, 15));

  test('Polaris stands at about the observer latitude', () {
    final scene = computeScene(field, time, hanoi);
    final index = catalog.stars.indexWhere((s) => s.properName == 'Polaris');
    final h = Horizontal.fromVector(scene.starVector(index));
    expect(h.altDeg, closeTo(hanoi.latitudeDeg, 1.0));
  });

  test('star vectors match the step-by-step reduction', () {
    final scene = computeScene(field, time, hanoi);
    final index = catalog.stars.indexWhere((s) => s.hr == 2491);
    final sirius = catalog.stars[index];
    final years = (time.jdTt - j2000) / 365.25;
    final moved = applyProperMotion(
      sirius.j2000,
      pmRaCosDecMasPerYear: sirius.pmRaMas.toDouble(),
      pmDecMasPerYear: sirius.pmDecMas.toDouble(),
      years: years,
    );
    final ofDate = precessFromJ2000(moved, time.jdTt);
    final lst = localSiderealDegrees(
      greenwichApparentSiderealDegrees(time.jdUt, time.jdTt),
      hanoi.longitudeDeg,
    );
    final geometric = equatorialToHorizontal(
      ofDate,
      lstDeg: lst,
      latitudeDeg: hanoi.latitudeDeg,
    );
    final actual = Horizontal.fromVector(scene.starVector(index));
    expect(actual.azDeg, closeTo(geometric.azDeg, 1e-5));
    expect(actual.altDeg, closeTo(apparentAltitudeDeg(geometric.altDeg), 1e-5));
  });

  test('the Sun culminates near the zenith on the equator at the equinox', () {
    final noon = AstroTime.fromDateTime(DateTime.utc(2026, 3, 20, 12, 7));
    final scene = computeScene(
      field,
      noon,
      Observer(latitudeDeg: 0, longitudeDeg: 0),
    );
    expect(scene.body('sun').horizontal.altDeg, greaterThan(88));
  });

  test('scene lists the Sun, the Moon and seven planets', () {
    final scene = computeScene(field, time, hanoi);
    expect(scene.bodies.map((b) => b.id), [
      'sun',
      'moon',
      'planet:mercury',
      'planet:venus',
      'planet:mars',
      'planet:jupiter',
      'planet:saturn',
      'planet:uranus',
      'planet:neptune',
    ]);
    expect(scene.body('planet:venus').name, 'Venus');
    expect(scene.body('sun').magnitude, lessThan(-26));
  });

  test('the Moon is seen lower than from the centre of the Earth', () {
    final scene = computeScene(field, time, hanoi);
    final moon = scene.body('moon');
    final lst = localSiderealDegrees(
      greenwichApparentSiderealDegrees(time.jdUt, time.jdTt),
      hanoi.longitudeDeg,
    );
    final geocentric = equatorialToHorizontal(
      moon.apparent,
      lstDeg: lst,
      latitudeDeg: hanoi.latitudeDeg,
    );
    if (geocentric.altDeg > 5) {
      expect(
        moon.horizontal.altDeg,
        lessThan(apparentAltitudeDeg(geocentric.altDeg)),
      );
    }
    expect(moon.angularDiameterDeg, inInclusiveRange(0.48, 0.57));
  });

  test('object ids round-trip', () {
    expect(starId(2491), 'hr:2491');
    expect(hrFromId('hr:2491'), 2491);
    expect(hrFromId('planet:mars'), isNull);
    expect(hrFromId('hr:x'), isNull);
  });
}
