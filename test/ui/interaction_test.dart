import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orrery_sky_atlas/src/app.dart';
import 'package:orrery_sky_atlas/src/data/sky_link.dart';
import 'package:orrery_sky_atlas/src/ui/sky_canvas.dart';

import '../support/fixtures.dart';

final _now = DateTime.utc(2026, 11, 17, 14, 30); // 21:30 in Hanoi

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

String _timeLabel(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('time-label')))
    .textSpan!
    .toPlainText();

String _viewInfo(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((s) => s.startsWith('Facing'));

void main() {
  testWidgets('shows local time and place and steps a day forward', (
    tester,
  ) async {
    await _pumpApp(tester);
    expect(_timeLabel(tester), contains('Tue 17 Nov 2026'));
    expect(_timeLabel(tester), contains('21:30'));
    expect(find.text('Hanoi'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);

    await tester.tap(find.byTooltip('Forward one day'));
    await tester.pump();
    expect(_timeLabel(tester), contains('Wed 18 Nov 2026'));
    expect(find.text('LIVE'), findsNothing);

    await tester.tap(find.text('Now'));
    await tester.pump();
    expect(_timeLabel(tester), contains('Tue 17 Nov 2026'));
  });

  testWidgets('dragging the sky turns the view and the wheel zooms', (
    tester,
  ) async {
    await _pumpApp(tester);
    expect(_viewInfo(tester), contains('Facing S 180°'));
    await tester.drag(find.byType(SkyCanvas), const Offset(-200, 0));
    await tester.pump();
    expect(_viewInfo(tester), isNot(contains('Facing S 180°')));

    final before = _viewInfo(tester);
    final center = tester.getCenter(find.byType(SkyCanvas));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -300)));
    await tester.pump();
    expect(_viewInfo(tester), isNot(before));
  });

  testWidgets('zoom buttons change the field of view', (tester) async {
    await _pumpApp(tester);
    expect(_viewInfo(tester), contains('field 100°'));
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(_viewInfo(tester), contains('field 80°'));
  });

  testWidgets('a sky link sets place, time and view', (tester) async {
    await _pumpApp(
      tester,
      link: SkyLink.parse(
        Uri.parse('/?loc=sydney&t=2026-12-15T12:00Z&az=90&alt=20&fov=60'),
      ),
    );
    expect(find.text('Sydney'), findsOneWidget);
    expect(_timeLabel(tester), contains('22:00'));
    expect(_viewInfo(tester), contains('Facing E 90°'));
    expect(_viewInfo(tester), contains('field 60°'));
  });

  testWidgets('custom coordinates are validated before use', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('location-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('apply-custom-location')),
      200,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.enterText(find.byKey(const Key('latitude-field')), '91');
    await tester.tap(find.byKey(const Key('apply-custom-location')));
    await tester.pump();
    expect(find.textContaining('Latitude must be between'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('latitude-field')), '12,5 S');
    await tester.enterText(
      find.byKey(const Key('longitude-field')),
      '130.84 E',
    );
    await tester.enterText(find.byKey(const Key('utc-offset-field')), '+9:30');
    await tester.tap(find.byKey(const Key('apply-custom-location')));
    await tester.pumpAndSettle();
    expect(find.text('12.50° S, 130.84° E'), findsOneWidget);
  });

  testWidgets('a preset location can be picked from the sheet', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('location-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Da Lat'));
    await tester.pumpAndSettle();
    expect(find.text('Da Lat'), findsOneWidget);
  });
}
