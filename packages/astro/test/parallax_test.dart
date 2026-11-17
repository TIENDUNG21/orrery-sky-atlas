import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  test('parallax does not move an object at the zenith', () {
    expect(topocentricAltitudeDeg(90, 0.95), closeTo(90, 1e-9));
  });

  test('at the horizon the Moon drops by its full parallax', () {
    expect(topocentricAltitudeDeg(0, 0.95), closeTo(-0.95, 1e-3));
  });

  test('at 45° the shift is about π·cos h', () {
    expect(topocentricAltitudeDeg(45, 0.95), closeTo(45 - 0.95 * 0.7071, 0.01));
  });

  test('zero parallax changes nothing', () {
    expect(topocentricAltitudeDeg(-12.5, 0), closeTo(-12.5, 1e-12));
  });
}
