import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/app.dart';
import 'package:orrery_sky_atlas/src/sky/sky_painter.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('loads the catalogue and paints the sky', (tester) async {
    await tester.pumpWidget(OrreryApp(loader: () async => tinyCatalog()));
    await tester.pump();
    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(paints.any((p) => p.painter is SkyPainter), isTrue);
  });

  testWidgets('a damaged catalogue shows an error instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      OrreryApp(
        loader: () async =>
            throw const FormatException('Catalog checksum mismatch'),
      ),
    );
    await tester.pump();
    expect(find.text('Could not load the star catalog'), findsOneWidget);
    expect(find.text('Catalog checksum mismatch'), findsOneWidget);
  });
}
