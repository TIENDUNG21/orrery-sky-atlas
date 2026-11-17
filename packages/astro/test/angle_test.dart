import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeDegrees', () {
    test('wraps negative angles into [0, 360)', () {
      expect(normalizeDegrees(-30), 330);
    });

    test('wraps angles above one turn', () {
      expect(normalizeDegrees(720.5), closeTo(0.5, 1e-12));
    });
  });
}
