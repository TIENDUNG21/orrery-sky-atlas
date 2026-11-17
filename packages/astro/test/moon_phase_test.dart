import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('Meeus example 48.a, 1992 Apr 12.0 TD', () {
    const jde = 2448724.5;
    final sun = sunPosition(jde);
    final moon = moonPosition(jde);

    test('illuminated fraction 0.6786', () {
      expect(moonIlluminatedFraction(sun, moon), closeTo(0.6786, 0.0005));
    });

    test('position angle of the bright limb 285.0°', () {
      expect(brightLimbAngleDeg(sun, moon), closeTo(285.0, 0.1));
    });

    test('phase summary is a waxing gibbous Moon', () {
      final phase = moonPhase(jde);
      expect(phase.name, MoonPhaseName.waxingGibbous);
      expect(phase.illuminatedFraction, closeTo(0.6786, 0.0005));
      expect(phase.ageDays, inInclusiveRange(9, 11));
    });
  });

  test('example 49.a: new Moon of 1977 Feb 18, 3h37m42s TD', () {
    final jde = findLunarPhase(2443184.5, LunarPhaseKind.newMoon);
    expect(jde, closeTo(2443192.65118, 0.0015));
  });

  test('phases follow each other in order a quarter of a month apart', () {
    const start = 2461041.5; // 2026 Jan 1
    final newMoon = findLunarPhase(start, LunarPhaseKind.newMoon);
    final firstQuarter = findLunarPhase(newMoon, LunarPhaseKind.firstQuarter);
    final full = findLunarPhase(firstQuarter, LunarPhaseKind.fullMoon);
    final lastQuarter = findLunarPhase(full, LunarPhaseKind.lastQuarter);
    final nextNew = findLunarPhase(lastQuarter, LunarPhaseKind.newMoon);
    for (final gap in [
      firstQuarter - newMoon,
      full - firstQuarter,
      lastQuarter - full,
      nextNew - lastQuarter,
    ]) {
      expect(gap, inInclusiveRange(6.5, 8.5));
    }
    expect(nextNew - newMoon, closeTo(29.53, 0.45));
    expect(moonPhase(full).illuminatedFraction, greaterThan(0.99));
    expect(moonPhase(newMoon).illuminatedFraction, lessThan(0.01));
  });

  test('phase names cover the whole cycle', () {
    expect(phaseNameForElongation(0), MoonPhaseName.newMoon);
    expect(phaseNameForElongation(45), MoonPhaseName.waxingCrescent);
    expect(phaseNameForElongation(90), MoonPhaseName.firstQuarter);
    expect(phaseNameForElongation(135), MoonPhaseName.waxingGibbous);
    expect(phaseNameForElongation(180), MoonPhaseName.fullMoon);
    expect(phaseNameForElongation(225), MoonPhaseName.waningGibbous);
    expect(phaseNameForElongation(270), MoonPhaseName.lastQuarter);
    expect(phaseNameForElongation(315), MoonPhaseName.waningCrescent);
    expect(phaseNameForElongation(359), MoonPhaseName.newMoon);
  });
}
