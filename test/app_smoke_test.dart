import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/app.dart';

void main() {
  testWidgets('app starts and shows its name', (tester) async {
    await tester.pumpWidget(const OrreryApp());
    expect(find.text('Orrery Sky Atlas'), findsOneWidget);
  });
}
