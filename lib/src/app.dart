import 'package:material_ui/material_ui.dart';

import 'data/catalog_loader.dart';
import 'ui/sky_page.dart';

/// Brand colors shared by the whole app.
abstract final class OrreryColors {
  static const background = Color(0xFF0A0A0A);
  static const text = Color(0xFFEDEDED);
  static const accent = Color(0xFFE3B341);
}

/// Root widget of Orrery Sky Atlas.
class OrreryApp extends StatelessWidget {
  const OrreryApp({super.key, this.loader = loadBundledCatalog});

  /// Source of the star catalogue (the bundled asset by default).
  final CatalogLoader loader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orrery Sky Atlas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: OrreryColors.background,
        colorScheme: const ColorScheme.dark(
          primary: OrreryColors.accent,
          surface: OrreryColors.background,
          onSurface: OrreryColors.text,
        ),
      ),
      home: SkyPage(loader: loader),
    );
  }
}
