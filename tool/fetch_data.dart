// Downloads the raw third-party data into .cache/downloads/ and verifies
// each file against a pinned SHA-256 digest.
//
// Usage: dart run tool/fetch_data.dart
//
// The Harvard CfA server only answers over plain HTTP; the pinned digests
// make the download tamper-evident regardless of transport.

import 'dart:io';

import 'package:crypto/crypto.dart';

const _sources = [
  (
    url: 'http://tdc-www.harvard.edu/catalogs/ybsc5.gz',
    path: 'bsc5/ybsc5.gz',
    sha256: '3dc44b1e90be8fbe5bcc7656032560f51275f985c7e3f783c9028e1838ec7bed',
  ),
  (
    url: 'http://tdc-www.harvard.edu/catalogs/ybsc5.readme',
    path: 'bsc5/ybsc5.readme',
    sha256: '6d2409d4cd36895fee43186fa1cd53fa4c8a512bb52e3dc864aef1c72543716e',
  ),
  (
    url:
        'https://raw.githubusercontent.com/MarcvdSluys/ConstellationLines/'
        '158ea7c588dd78a295dc977326e72ad29004d8eb/ConstellationLines.dat',
    path: 'lines/ConstellationLines.dat',
    sha256: '8115433215be8cff8f5edec763d808ce21bad9704bcd5202be19b205d09cb4f1',
  ),
  (
    url:
        'https://raw.githubusercontent.com/MarcvdSluys/ConstellationLines/'
        '158ea7c588dd78a295dc977326e72ad29004d8eb/LICENSE',
    path: 'lines/LICENSE',
    sha256: '631f47b6144cc028e1440488e5562efefbf28b267063fce37b51292a85dad4e0',
  ),
];

Future<void> main() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    for (final source in _sources) {
      final file = File('.cache/downloads/${source.path}');
      if (file.existsSync() && _digest(file) == source.sha256) {
        stdout.writeln('ok      ${source.path} (cached)');
        continue;
      }
      file.parent.createSync(recursive: true);
      final request = await client.getUrl(Uri.parse(source.url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode} for ${source.url}');
      }
      await response.pipe(file.openWrite());
      final digest = _digest(file);
      if (digest != source.sha256) {
        file.deleteSync();
        throw StateError(
          '${source.path}: SHA-256 $digest does not match ${source.sha256}',
        );
      }
      stdout.writeln('fetched ${source.path}');
    }
  } finally {
    client.close();
  }
}

String _digest(File file) => sha256.convert(file.readAsBytesSync()).toString();
