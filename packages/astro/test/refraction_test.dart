import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  test('Bennett formula gives about 34.5′ at the apparent horizon', () {
    expect(refractionBennettArcmin(0), closeTo(34.5, 0.1));
  });

  test('Saemundsson (16.4) inverts Bennett (16.3) to within 0.1′', () {
    for (var apparent = 0.0; apparent <= 89; apparent += 0.5) {
      final r = refractionBennettArcmin(apparent);
      final trueAltitude = apparent - r / 60;
      expect(
        refractionSaemundssonArcmin(trueAltitude),
        closeTo(r, 0.1),
        reason: 'apparent altitude $apparent°',
      );
    }
  });

  test('refraction vanishes at the zenith', () {
    expect(refractionSaemundssonArcmin(90), closeTo(0, 1e-6));
    expect(apparentAltitudeDeg(90), closeTo(90, 1e-6));
  });

  test('apparent altitude is finite and increasing from nadir to zenith', () {
    var previous = double.negativeInfinity;
    for (var h = -90.0; h <= 90.0; h += 0.05) {
      final a = apparentAltitudeDeg(h);
      expect(a.isFinite, isTrue, reason: 'h = $h');
      expect(a, greaterThan(previous), reason: 'h = $h');
      previous = a;
    }
  });

  test('objects well below the horizon are not refracted', () {
    expect(apparentAltitudeDeg(-12), -12);
  });
}
