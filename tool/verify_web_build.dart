// Checks a web build before it is published under a sub-path on GitHub
// Pages: the base href, relative asset references and a decodable catalog.
//
// Usage: dart run tool/verify_web_build.dart [build/web] [/orrery-sky-atlas/]

import 'dart:io';

import 'package:astro/catalog.dart';

void main(List<String> args) {
  final root = args.isNotEmpty ? args[0] : 'build/web';
  final base = args.length > 1 ? args[1] : '/orrery-sky-atlas/';
  final problems = <String>[];

  final index = File('$root/index.html');
  if (!index.existsSync()) {
    stderr.writeln('missing $root/index.html');
    exit(1);
  }
  final html = index.readAsStringSync();
  if (!html.contains('<base href="$base">')) {
    problems.add('index.html does not set <base href="$base">');
  }
  // Absolute paths would bypass the base href and 404 under the sub-path.
  final withoutBase = html.replaceAll(RegExp(r'<base [^>]*>'), '');
  final absolute = RegExp(r'''(?:src|href)="/(?!/)''').allMatches(withoutBase);
  if (absolute.isNotEmpty) {
    problems.add(
      'index.html has ${absolute.length} root-relative reference(s)',
    );
  }
  for (final required in ['flutter_bootstrap.js', 'main.dart.js']) {
    if (!File('$root/$required').existsSync()) {
      problems.add('missing $required');
    }
  }

  final asset = File('$root/assets/assets/catalog/sky.bin');
  if (!asset.existsSync()) {
    problems.add('missing the catalog asset');
  } else {
    try {
      final catalog = decodeCatalog(asset.readAsBytesSync());
      stdout.writeln(
        'catalog: ${catalog.stars.length} stars, '
        '${catalog.constellations.length} constellations',
      );
    } on FormatException catch (e) {
      problems.add('catalog asset does not decode: ${e.message}');
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('web build OK for base $base');
    return;
  }
  problems.forEach(stderr.writeln);
  exit(1);
}
