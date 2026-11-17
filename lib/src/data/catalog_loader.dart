import 'package:astro/catalog.dart';
import 'package:flutter/services.dart';

/// Loads the star catalogue; injectable so tests can supply their own.
typedef CatalogLoader = Future<SkyCatalog> Function();

/// Path of the bundled catalogue built by `tool/build_catalog.dart`.
const String catalogAssetPath = 'assets/catalog/sky.bin';

/// Reads and decodes the bundled catalogue.
Future<SkyCatalog> loadBundledCatalog() async {
  final data = await rootBundle.load(catalogAssetPath);
  return decodeCatalog(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}
