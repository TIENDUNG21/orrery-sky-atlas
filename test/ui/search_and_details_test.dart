import 'package:astro/astro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orrery_sky_atlas/src/app.dart';
import 'package:orrery_sky_atlas/src/data/locations.dart';
import 'package:orrery_sky_atlas/src/data/sky_link.dart';
import 'package:orrery_sky_atlas/src/sky/sky_painter.dart';
import 'package:orrery_sky_atlas/src/sky/sky_scene.dart';
import 'package:orrery_sky_atlas/src/ui/night_mode.dart';
import 'package:orrery_sky_atlas/src/ui/sky_canvas.dart';

import '../support/fixtures.dart';

final _now = DateTime.utc(2026, 12, 15, 14); // 21:00 in Hanoi

Future<void> _pumpApp(
  WidgetTester tester, {
  SkyLink link = const SkyLink(),
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    OrreryApp(loader: () async => tinyCatalog(), clock: () => _now, link: link),
  );
  await tester.pump();
}

SkyPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<SkyPainter>()
    .single;

void main() {
  testWidgets('searching for Sirius selects it and shows its details', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-field')), 'alpha cma');
    await tester.pump();
    await tester.tap(find.text('Sirius'));
    await tester.pumpAndSettle();

    expect(find.text('Star in Canis Major'), findsOneWidget);
    expect(find.text('Magnitude (V)'), findsOneWidget);
    expect(find.text('−1.46'), findsOneWidget);
    expect(_painter(tester).selectedId, 'hr:2491');
  });

  testWidgets('an unknown search shows that nothing was found', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-field')), '🌍 qqq');
    await tester.pump();
    expect(find.text('Nothing found'), findsOneWidget);
  });

  testWidgets('tapping a star in the sky opens its details', (tester) async {
    final scene = computeScene(
      StarField(tinyCatalog()),
      AstroTime.fromDateTime(_now),
      locationPresets.first.observer,
    );
    final sirius = Horizontal.fromVector(scene.starVector(4));
    await _pumpApp(
      tester,
      link: SkyLink(azDeg: sirius.azDeg, altDeg: sirius.altDeg, fovDeg: 60),
    );
    await tester.tapAt(tester.getCenter(find.byType(SkyCanvas)));
    await tester.pumpAndSettle();
    expect(find.text('Star in Canis Major'), findsOneWidget);
  });

  testWidgets('night mode turns the whole app red', (tester) async {
    await _pumpApp(tester);
    bool isNight() => tester
        .widgetList<ColorFiltered>(find.byType(ColorFiltered))
        .any((w) => w.colorFilter == const ColorFilter.matrix(nightModeMatrix));
    expect(isNight(), isFalse);
    await tester.tap(find.byTooltip('Night mode'));
    await tester.pump();
    expect(isNight(), isTrue);
  });

  testWidgets('the layers menu hides the grid', (tester) async {
    await _pumpApp(tester);
    expect(_painter(tester).layers.grid, isTrue);
    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Altitude-azimuth grid'));
    await tester.pumpAndSettle();
    expect(_painter(tester).layers.grid, isFalse);
  });

  testWidgets('the about dialog credits the data sources', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('About and data credits'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bright Star Catalogue'), findsOneWidget);
    expect(find.textContaining('CC BY 4.0'), findsOneWidget);
  });
}
