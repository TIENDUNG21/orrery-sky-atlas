import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/sky/star_style.dart';

int _r(int argb) => (argb >> 16) & 0xFF;
int _b(int argb) => argb & 0xFF;

void main() {
  test('brighter stars are drawn larger, within limits', () {
    const lim = 6.0;
    final sirius = starRadiusPx(-1.46, lim);
    final vega = starRadiusPx(0.03, lim);
    final faint = starRadiusPx(5.9, lim);
    expect(sirius, greaterThan(vega));
    expect(vega, greaterThan(faint));
    expect(sirius, lessThanOrEqualTo(7));
    expect(faint, greaterThanOrEqualTo(0.5));
  });

  test('faint stars fade instead of popping', () {
    expect(starOpacity(6.0, 6.0), lessThan(starOpacity(3.0, 6.0)));
    expect(starOpacity(-1, 6.0), 1.0);
  });

  test('zooming in reveals fainter stars; daylight hides them', () {
    expect(
      limitingMagnitude(30, -30),
      greaterThan(limitingMagnitude(120, -30)),
    );
    expect(limitingMagnitude(90, -30), closeTo(6.0, 0.01));
    expect(limitingMagnitude(1, -30), lessThanOrEqualTo(8.0));
    expect(limitingMagnitude(90, 10), lessThan(-0.5));
    expect(limitingMagnitude(90, -9), inExclusiveRange(-1, 6));
  });

  test('B−V 0.65 gives the solar temperature (Ballesteros 2012)', () {
    expect(bvToTemperatureK(0.65), closeTo(5778, 30));
  });

  test('hot stars are blue-white, cool stars orange, unknown white', () {
    final hot = starColorArgb(-0.3);
    final cool = starColorArgb(1.8);
    expect(_b(hot), greaterThan(_r(hot)));
    expect(_r(cool), greaterThan(_b(cool)));
    final unknown = starColorArgb(null);
    expect(_r(unknown), greaterThan(230));
    expect(_b(unknown), greaterThan(230));
    expect(unknown >> 24, 0xFF);
  });
}
