/// Compact binary form of a [SkyCatalog] (format "ORSK", version 1).
///
/// Little-endian layout:
///
///     'ORSK' u16 version u16 flags
///     u16 n, then n × { 3-byte abbreviation, str name, str genitive }
///     u32 m, then m × { u16 hr, u32 ra (0.1 s), i32 dec (arcsec),
///                       i16 pmRa, i16 pmDec (mas/yr), i16 V×100,
///                       i16 (B−V)×100, i16 parallax (mas),
///                       u8 flamsteed, u8 bayer, u8 bayerIndex,
///                       u8 constellation index, str spectral type,
///                       str proper name }
///     n × { u16 k, then k × { u16 count, count × u16 hr } }
///     u32 CRC-32 of everything before it
///
/// `str` is a u8 byte length followed by UTF-8. Missing values are −32768
/// for i16 fields, 0 for u8 fields and 255 for the constellation index.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'crc32.dart';
import 'designation.dart';
import 'model.dart';

const List<int> _magic = [0x4F, 0x52, 0x53, 0x4B]; // ORSK
const int _version = 1;
const int _none16 = -32768;
const int _noConstellation = 255;

/// Serializes [catalog]. Throws [ArgumentError] for values the format
/// cannot hold or for figure lines that name stars not in the catalogue.
Uint8List encodeCatalog(SkyCatalog catalog) {
  final w = _Writer();
  w.bytes(_magic);
  w.u16(_version);
  w.u16(0);

  final constellationIndex = <String, int>{};
  w.u16(catalog.constellations.length);
  for (final c in catalog.constellations) {
    if (c.abbr.length != 3) {
      throw ArgumentError.value(c.abbr, 'abbr', 'must have three letters');
    }
    constellationIndex[c.abbr] = constellationIndex.length;
    w.bytes(ascii.encode(c.abbr));
    w.str(c.name);
    w.str(c.genitive);
  }

  w.u32(catalog.stars.length);
  for (final s in catalog.stars) {
    final d = s.designation;
    final abbr = d.constellation;
    final cIndex = abbr == null ? _noConstellation : constellationIndex[abbr];
    if (cIndex == null) {
      throw ArgumentError('HR ${s.hr}: unknown constellation $abbr');
    }
    w.u16(s.hr);
    w.u32(s.raTenthsOfSecond);
    w.i32(s.decArcsec);
    w.i16(s.pmRaMas);
    w.i16(s.pmDecMas);
    w.i16((s.vmag * 100).round());
    w.i16(s.bv == null ? _none16 : (s.bv! * 100).round());
    w.i16(s.parallaxMas ?? _none16);
    w.u8(d.flamsteed ?? 0);
    w.u8(d.bayer == null ? 0 : d.bayer!.index + 1);
    w.u8(d.bayerIndex ?? 0);
    w.u8(cIndex);
    w.str(s.spectralType);
    w.str(s.properName ?? '');
  }

  for (final c in catalog.constellations) {
    w.u16(c.polylines.length);
    for (final line in c.polylines) {
      w.u16(line.length);
      for (final hr in line) {
        if (catalog.starByHr(hr) == null) {
          throw ArgumentError('${c.abbr}: figure names unknown star HR $hr');
        }
        w.u16(hr);
      }
    }
  }

  final body = w.toBytes();
  final out = _Writer()
    ..bytes(body)
    ..u32(crc32(body));
  return out.toBytes();
}

/// Parses bytes written by [encodeCatalog].
///
/// Throws [FormatException] naming the problem: wrong magic, unsupported
/// version, truncated data or a checksum mismatch.
SkyCatalog decodeCatalog(Uint8List bytes) {
  const headerLength = 8;
  if (bytes.length < headerLength + 4) {
    throw FormatException(
      'Catalog truncated: ${bytes.length} bytes is shorter than the header',
    );
  }
  for (var i = 0; i < _magic.length; i++) {
    if (bytes[i] != _magic[i]) {
      throw const FormatException('Not an Orrery sky catalog (bad magic)');
    }
  }
  final r = _Reader(bytes, bytes.length - 4)..skip(4);
  final version = r.u16('version');
  if (version != _version) {
    throw FormatException('Unsupported catalog version $version');
  }
  final stored = ByteData.sublistView(
    bytes,
    bytes.length - 4,
  ).getUint32(0, Endian.little);
  if (stored != crc32(Uint8List.sublistView(bytes, 0, bytes.length - 4))) {
    throw const FormatException('Catalog checksum mismatch (damaged file)');
  }
  r.u16('flags');

  final count = r.u16('constellation count');
  final names = <(String, String, String)>[];
  for (var i = 0; i < count; i++) {
    names.add((
      ascii.decode(r.bytes(3, 'abbreviation')),
      r.str('name'),
      r.str('genitive'),
    ));
  }

  final stars = <Star>[];
  final starCount = r.u32('star count');
  for (var i = 0; i < starCount; i++) {
    final hr = r.u16('hr');
    final ra = r.u32('ra');
    final dec = r.i32('dec');
    final pmRa = r.i16('pmRa');
    final pmDec = r.i16('pmDec');
    final vmag = r.i16('vmag');
    final bv = r.i16('bv');
    final parallax = r.i16('parallax');
    final flamsteed = r.u8('flamsteed');
    final bayer = r.u8('bayer');
    final bayerIndex = r.u8('bayerIndex');
    final cIndex = r.u8('constellation');
    if (bayer > GreekLetter.values.length) {
      throw FormatException('HR $hr: Bayer letter $bayer out of range');
    }
    if (cIndex != _noConstellation && cIndex >= names.length) {
      throw FormatException('HR $hr: constellation index $cIndex out of range');
    }
    final spectral = r.str('spectral type');
    final proper = r.str('proper name');
    stars.add(
      Star(
        hr: hr,
        raTenthsOfSecond: ra,
        decArcsec: dec,
        pmRaMas: pmRa,
        pmDecMas: pmDec,
        vmag: vmag / 100,
        bv: bv == _none16 ? null : bv / 100,
        parallaxMas: parallax == _none16 ? null : parallax,
        designation: StarDesignation(
          flamsteed: flamsteed == 0 ? null : flamsteed,
          bayer: bayer == 0 ? null : GreekLetter.values[bayer - 1],
          bayerIndex: bayerIndex == 0 ? null : bayerIndex,
          constellation: cIndex == _noConstellation ? null : names[cIndex].$1,
        ),
        spectralType: spectral,
        properName: proper.isEmpty ? null : proper,
      ),
    );
  }

  final constellations = <ConstellationInfo>[];
  for (final (abbr, name, genitive) in names) {
    final polylines = <List<int>>[];
    final lineCount = r.u16('polyline count');
    for (var j = 0; j < lineCount; j++) {
      final n = r.u16('polyline length');
      polylines.add([for (var k = 0; k < n; k++) r.u16('figure star')]);
    }
    constellations.add(
      ConstellationInfo(
        abbr: abbr,
        name: name,
        genitive: genitive,
        polylines: polylines,
      ),
    );
  }
  if (!r.atEnd) {
    throw FormatException('Catalog has ${r.remaining} unexpected extra bytes');
  }
  return SkyCatalog(stars: stars, constellations: constellations);
}

class _Writer {
  final _builder = BytesBuilder(copy: false);
  final _scratch = ByteData(4);

  void bytes(List<int> b) => _builder.add(b);

  void u8(int v) {
    if (v < 0 || v > 0xFF) throw ArgumentError.value(v, 'u8');
    _builder.addByte(v);
  }

  void u16(int v) {
    if (v < 0 || v > 0xFFFF) throw ArgumentError.value(v, 'u16');
    _scratch.setUint16(0, v, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 2).toList());
  }

  void i16(int v) {
    if (v < -32768 || v > 32767) throw ArgumentError.value(v, 'i16');
    _scratch.setInt16(0, v, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 2).toList());
  }

  void u32(int v) {
    if (v < 0 || v > 0xFFFFFFFF) throw ArgumentError.value(v, 'u32');
    _scratch.setUint32(0, v, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 4).toList());
  }

  void i32(int v) {
    _scratch.setInt32(0, v, Endian.little);
    _builder.add(_scratch.buffer.asUint8List(0, 4).toList());
  }

  void str(String s) {
    final encoded = utf8.encode(s);
    u8(encoded.length);
    _builder.add(encoded);
  }

  Uint8List toBytes() => _builder.toBytes();
}

class _Reader {
  _Reader(Uint8List bytes, this._end)
    : _bytes = bytes,
      _data = ByteData.sublistView(bytes);

  final Uint8List _bytes;
  final ByteData _data;
  final int _end;
  int _pos = 0;

  bool get atEnd => _pos == _end;
  int get remaining => _end - _pos;

  void _need(int n, String what) {
    if (_pos + n > _end) {
      throw FormatException('Catalog truncated at byte $_pos reading $what');
    }
  }

  void skip(int n) => _pos += n;

  Uint8List bytes(int n, String what) {
    _need(n, what);
    final out = Uint8List.sublistView(_bytes, _pos, _pos + n);
    _pos += n;
    return out;
  }

  int u8(String what) {
    _need(1, what);
    return _data.getUint8(_pos++);
  }

  int u16(String what) {
    _need(2, what);
    final v = _data.getUint16(_pos, Endian.little);
    _pos += 2;
    return v;
  }

  int i16(String what) {
    _need(2, what);
    final v = _data.getInt16(_pos, Endian.little);
    _pos += 2;
    return v;
  }

  int u32(String what) {
    _need(4, what);
    final v = _data.getUint32(_pos, Endian.little);
    _pos += 4;
    return v;
  }

  int i32(String what) {
    _need(4, what);
    final v = _data.getInt32(_pos, Endian.little);
    _pos += 4;
    return v;
  }

  String str(String what) {
    final n = u8('$what length');
    return utf8.decode(bytes(n, what));
  }
}
