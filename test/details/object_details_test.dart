import 'dart:io';

import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/data/locations.dart';
import 'package:orrery_sky_atlas/src/details/object_details.dart';
import 'package:orrery_sky_atlas/src/sky/sky_scene.dart';

void main() {
  final catalog = decodeCatalog(
    File('assets/catalog/sky.bin').readAsBytesSync(),
  );
  final field = StarField(catalog);
  final hanoi = locationPresets.first;
  final scene = computeScene(
    field,
    AstroTime.fromDateTime(DateTime.utc(2026, 12, 15, 14)),
    hanoi.observer,
  );

  ObjectDetails describe(String id) =>
      describeObject(id, scene: scene, catalog: catalog, location: hanoi)!;

  String? row(ObjectDetails d, String label) {
    for (final r in d.rows) {
      if (r.label == label) return r.value;
    }
    return null;
  }

  final clock = RegExp(r'^\d\d:\d\d$');

  test('a star shows its catalogue data and local rise and set', () {
    final d = describe('hr:2061');
    expect(d.title, 'Betelgeuse');
    expect(d.subtitle, 'Star in Orion');
    expect(
      row(d, 'Designation'),
      allOf(contains('α Ori'), contains('HR 2061')),
    );
    expect(row(d, 'Magnitude (V)'), '0.50');
    expect(row(d, 'Colour index (B−V)'), '+1.85');
    expect(row(d, 'Spectral type'), 'M1-2Ia-Iab');
    expect(row(d, 'Rises'), matches(clock));
    expect(row(d, 'Sets'), matches(clock));
    expect(row(d, 'Altitude'), endsWith('°'));
  });

  test('Polaris never sets as seen from Hanoi', () {
    final polaris = catalog.stars.firstWhere((s) => s.properName == 'Polaris');
    final d = describe(starId(polaris.hr));
    expect(row(d, 'Rises'), isNull);
    expect(row(d, 'Rise and set'), 'Circumpolar');
  });

  test('planets show distance, phase and elongation', () {
    final d = describe('planet:mars');
    expect(d.subtitle, 'Planet');
    expect(row(d, 'Distance'), contains('AU'));
    expect(row(d, 'Illuminated'), endsWith('%'));
    expect(row(d, 'Elongation'), contains('from the Sun'));
  });

  test('the Moon shows its phase and the next principal phases', () {
    final d = describe('moon');
    expect(row(d, 'Phase'), isNotNull);
    expect(row(d, 'Illuminated'), endsWith('%'));
    expect(row(d, 'Distance'), endsWith('km'));
    expect(row(d, 'Next full Moon'), contains('2026'));
  });

  test('sunrise and sunset in Hanoi at the June solstice', () {
    final june = computeScene(
      field,
      AstroTime.fromDateTime(DateTime.utc(2026, 6, 21, 5)),
      hanoi.observer,
    );
    final d = describeObject(
      'sun',
      scene: june,
      catalog: catalog,
      location: hanoi,
    )!;
    int minutes(String hhmm) =>
        int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3));
    // Expected from the hour angle at h0 = −0.833°: 05:16 and 18:40.
    expect(minutes(row(d, 'Rises')!), closeTo(5 * 60 + 16, 6));
    expect(minutes(row(d, 'Sets')!), closeTo(18 * 60 + 40, 6));
  });

  test('a constellation names its brightest star', () {
    final d = describe('con:Ori');
    expect(d.title, 'Orion');
    expect(row(d, 'Brightest star'), contains('Rigel'));
    expect(row(d, 'Genitive'), 'Orionis');
  });

  test('unknown ids describe nothing', () {
    expect(
      describeObject(
        'hr:99999',
        scene: scene,
        catalog: catalog,
        location: hanoi,
      ),
      isNull,
    );
    expect(
      describeObject('banana', scene: scene, catalog: catalog, location: hanoi),
      isNull,
    );
  });
}
