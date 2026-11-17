// Times the per-frame work of the sky view on the Dart VM: decoding the
// catalog asset, computing a scene (9096 stars, Sun, Moon, seven planets)
// and laying out one 1440 x 900 frame. Reports the median of repeated runs.
//
// Usage: dart run tool/bench_scene.dart
//
// The web build runs the same code compiled to JavaScript, so its timings
// differ; these numbers are for comparing changes, not for the browser.

import 'dart:io';

import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';
import 'package:orrery_sky_atlas/src/sky/projection.dart';
import 'package:orrery_sky_atlas/src/sky/sky_frame.dart';
import 'package:orrery_sky_atlas/src/sky/sky_scene.dart';

double _medianMicros(int runs, void Function(int i) body) {
  for (var i = 0; i < 20; i++) {
    body(i);
  }
  final samples = <int>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    body(i);
    samples.add(sw.elapsedMicroseconds);
  }
  samples.sort();
  return samples[runs ~/ 2].toDouble();
}

void main() {
  final bytes = File('assets/catalog/sky.bin').readAsBytesSync();
  final decode = _medianMicros(50, (_) => decodeCatalog(bytes));

  final catalog = decodeCatalog(bytes);
  final field = StarField(catalog);
  final hanoi = Observer(latitudeDeg: 21.0285, longitudeDeg: 105.8542);
  final start = DateTime.utc(2026, 12, 15, 14);

  // A different minute each run, as during time-lapse playback.
  final scene = _medianMicros(
    200,
    (i) => computeScene(
      field,
      AstroTime.fromDateTime(start.add(Duration(minutes: i))),
      hanoi,
    ),
  );

  final fixed = computeScene(field, AstroTime.fromDateTime(start), hanoi);
  late SkyFrame frame;
  final layout = _medianMicros(
    200,
    (i) => frame = layoutFrame(
      scene: fixed,
      field: field,
      view: SkyView(centerAzDeg: 110 + i % 10, centerAltDeg: 40, fovDeg: 110),
      width: 1440,
      height: 900,
      layers: SkyLayers.all,
    ),
  );

  String ms(double micros) => (micros / 1000).toStringAsFixed(2);
  stdout
    ..writeln('catalog bytes:        ${bytes.length}')
    ..writeln('decode catalog:       ${ms(decode)} ms')
    ..writeln('compute scene:        ${ms(scene)} ms')
    ..writeln(
      'layout 1440x900 frame: ${ms(layout)} ms '
      '(${frame.stars.length} stars, ${frame.segments.length} segments, '
      '${frame.labels.length} labels)',
    )
    ..writeln(
      'Dart ${Platform.version.split(' ').first}, ${Platform.operatingSystem}',
    );
}
