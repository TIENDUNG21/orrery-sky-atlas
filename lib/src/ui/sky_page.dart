import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../data/catalog_loader.dart';
import '../sky/projection.dart';
import '../sky/sky_frame.dart';
import '../sky/sky_scene.dart';
import 'sky_viewport.dart';

/// Loads the catalogue, then shows the sky.
class SkyPage extends StatefulWidget {
  const SkyPage({super.key, required this.loader});

  final CatalogLoader loader;

  @override
  State<SkyPage> createState() => _SkyPageState();
}

class _SkyPageState extends State<SkyPage> {
  late final Future<SkyCatalog> _catalog = widget.loader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<SkyCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CatalogError(error: snapshot.error!);
          }
          final catalog = snapshot.data;
          if (catalog == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _SkyScreen(catalog: catalog);
        },
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final detail = error is FormatException
        ? (error as FormatException).message
        : '$error';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load the star catalog',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SkyScreen extends StatefulWidget {
  const _SkyScreen({required this.catalog});

  final SkyCatalog catalog;

  @override
  State<_SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<_SkyScreen> {
  late final StarField _field = StarField(widget.catalog);
  final _observer = Observer(latitudeDeg: 21.0285, longitudeDeg: 105.8542);
  late final SkyScene _scene = computeScene(
    _field,
    AstroTime.fromDateTime(DateTime.now().toUtc()),
    _observer,
  );

  @override
  Widget build(BuildContext context) {
    return SkyViewport(
      scene: _scene,
      field: _field,
      view: const SkyView(centerAzDeg: 180, centerAltDeg: 40, fovDeg: 100),
      layers: SkyLayers.all,
    );
  }
}
