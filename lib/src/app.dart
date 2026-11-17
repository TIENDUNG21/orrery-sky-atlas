import 'package:material_ui/material_ui.dart';

import 'data/catalog_loader.dart';
import 'data/sky_link.dart';
import 'ui/night_mode.dart';
import 'ui/sky_page.dart';
import 'ui/theme.dart';

/// Root widget of Orrery Sky Atlas.
class OrreryApp extends StatefulWidget {
  const OrreryApp({
    super.key,
    this.loader = loadBundledCatalog,
    this.clock,
    this.link = const SkyLink(),
  });

  /// Source of the star catalogue (the bundled asset by default).
  final CatalogLoader loader;

  /// Clock for "now"; injectable for tests.
  final DateTime Function()? clock;

  /// Initial state from the page URL on the web.
  final SkyLink link;

  @override
  State<OrreryApp> createState() => _OrreryAppState();
}

class _OrreryAppState extends State<OrreryApp> {
  final _night = NightModeController();

  @override
  void dispose() {
    _night.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NightModeScope(
      controller: _night,
      child: MaterialApp(
        title: 'Orrery Sky Atlas',
        debugShowCheckedModeBanner: false,
        theme: buildOrreryTheme(),
        builder: (context, child) => NightFilter(child: child!),
        home: SkyPage(
          loader: widget.loader,
          clock: widget.clock,
          link: widget.link,
        ),
      ),
    );
  }
}
