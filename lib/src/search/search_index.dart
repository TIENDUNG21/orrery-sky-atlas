import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';

import '../sky/sky_scene.dart';

enum SearchKind { sun, moon, planet, constellation, star }

class SearchResult {
  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.magnitude,
  });

  /// Object id as used by the sky (`hr:2061`, `planet:mars`, `con:Ori`).
  final String id;
  final String title;
  final String subtitle;
  final SearchKind kind;

  /// Visual magnitude used to rank equally good matches; 99 when unknown.
  final double magnitude;
}

/// Identifier of a constellation.
String constellationId(String abbr) => 'con:$abbr';

/// Abbreviation from a constellation id, or null for other objects.
String? abbrFromId(String id) => id.startsWith('con:') ? id.substring(4) : null;

class _Entry {
  _Entry(this.result, this.keys);

  final SearchResult result;

  /// Normalized search keys; the first is the title itself.
  final List<String> keys;
}

/// Finds stars, constellations and solar-system bodies by name, Bayer or
/// Flamsteed designation (in Greek letters, catalogue codes or Latin names)
/// and HR number. Matching is done on normalized text, so `α Ori`,
/// `alp ori` and `Alpha Orionis` all find Betelgeuse.
class SearchIndex {
  SearchIndex._(this._entries);

  factory SearchIndex.build(SkyCatalog catalog) {
    final entries = <_Entry>[
      _Entry(
        const SearchResult(
          id: 'sun',
          title: 'Sun',
          subtitle: 'Star',
          kind: SearchKind.sun,
          magnitude: -26.7,
        ),
        ['sun'],
      ),
      _Entry(
        const SearchResult(
          id: 'moon',
          title: 'Moon',
          subtitle: 'Natural satellite of Earth',
          kind: SearchKind.moon,
          magnitude: -12.7,
        ),
        ['moon'],
      ),
      for (final p in Planet.values)
        _Entry(
          SearchResult(
            id: planetId(p),
            title: p.label,
            subtitle: 'Planet',
            kind: SearchKind.planet,
            magnitude: -5,
          ),
          [normalizeQuery(p.label)],
        ),
      for (final c in catalog.constellations)
        _Entry(
          SearchResult(
            id: constellationId(c.abbr),
            title: c.name,
            subtitle: 'Constellation · ${c.abbr}',
            kind: SearchKind.constellation,
            magnitude: 0,
          ),
          [
            normalizeQuery(c.name),
            normalizeQuery(c.abbr),
            normalizeQuery(c.genitive),
          ],
        ),
      for (final s in catalog.stars) _starEntry(s, catalog),
    ];
    return SearchIndex._(entries);
  }

  final List<_Entry> _entries;

  /// Best matches for [query], at most [limit]. Exact matches beat prefix
  /// matches, which beat matches at a later word and then substrings; a hit
  /// on the title beats a hit on a designation; brighter objects win ties.
  List<SearchResult> search(String query, {int limit = 30}) {
    final q = normalizeQuery(query);
    if (q.isEmpty) return const [];
    final scored = <(int, _Entry)>[];
    for (final e in _entries) {
      var best = -1;
      for (var i = 0; i < e.keys.length; i++) {
        final type = _matchType(e.keys[i], q);
        if (type < 0) continue;
        final score = type * 2 + (i == 0 ? 0 : 1);
        if (best < 0 || score < best) best = score;
      }
      if (best >= 0) scored.add((best, e));
    }
    scored.sort((a, b) {
      final byScore = a.$1.compareTo(b.$1);
      if (byScore != 0) return byScore;
      final byKind = a.$2.result.kind.index.compareTo(b.$2.result.kind.index);
      if (byKind != 0) return byKind;
      return a.$2.result.magnitude.compareTo(b.$2.result.magnitude);
    });
    return [for (final (_, e) in scored.take(limit)) e.result];
  }
}

/// 0 exact, 1 prefix, 2 prefix of a later word, 3 substring, −1 no match.
int _matchType(String key, String q) {
  if (key == q) return 0;
  if (key.startsWith(q)) return 1;
  if (key.contains(' $q')) return 2;
  if (q.length >= 3 && key.contains(q)) return 3;
  return -1;
}

_Entry _starEntry(Star s, SkyCatalog catalog) {
  final d = s.designation;
  final keys = <String>[normalizeQuery(s.displayName)];
  final abbr = d.constellation;
  final genitive = abbr == null ? null : catalog.constellation(abbr)?.genitive;
  final c = abbr?.toLowerCase();
  final g = genitive == null ? null : normalizeQuery(genitive);
  final bayer = d.bayer;
  if (bayer != null && c != null) {
    final name = bayer.label.toLowerCase();
    final code = bayer.bscCode.toLowerCase();
    final suffixes = [if (d.bayerIndex != null) '${d.bayerIndex}', ''];
    for (final i in suffixes) {
      keys.add('$name$i $c');
      keys.add('$code$i $c');
      if (g != null) keys.add('$name$i $g');
    }
  }
  final flamsteed = d.flamsteed;
  if (flamsteed != null && c != null) {
    keys.add('$flamsteed $c');
    if (g != null) keys.add('$flamsteed $g');
  }
  keys.add('hr ${s.hr}');
  final parts = [
    if (s.properName != null && d.short.isNotEmpty) d.short,
    'HR ${s.hr}',
    'V ${s.vmag.toStringAsFixed(2)}',
  ];
  return _Entry(
    SearchResult(
      id: starId(s.hr),
      title: s.displayName,
      subtitle: parts.join(' · '),
      kind: SearchKind.star,
      magnitude: s.vmag,
    ),
    keys,
  );
}

final Map<int, String> _greek = {
  for (final g in GreekLetter.values)
    g.symbol.runes.first: g.label.toLowerCase(),
  'ς'.runes.first: 'sigma',
  'ϑ'.runes.first: 'theta',
  'ϕ'.runes.first: 'phi',
};

final Map<int, String> _latin = () {
  const groups = {
    'a': 'àáâãäåāăą',
    'c': 'çćč',
    'd': 'ďđ',
    'e': 'èéêëēėęě',
    'i': 'ìíîïīį',
    'n': 'ñńň',
    'o': 'òóôõöøōő',
    'r': 'ŕř',
    's': 'śšş',
    't': 'ťţ',
    'u': 'ùúûüūůű',
    'y': 'ýÿ',
    'z': 'źżž',
    'ss': 'ß',
    'ae': 'æ',
    'oe': 'œ',
  };
  return {
    for (final MapEntry(:key, :value) in groups.entries)
      for (final r in value.runes) r: key,
  };
}();

const _superscriptDigits = '⁰¹²³⁴⁵⁶⁷⁸⁹';
final _hrNumber = RegExp(r'\bhr(\d+)');

/// Lower-case ASCII form of a query or key: accents and combining marks
/// removed, Greek letters spelled out (`α` → `alpha`), superscripts made
/// digits, punctuation turned into spaces, anything else (emoji, zero-width
/// characters) dropped.
String normalizeQuery(String input) {
  final out = StringBuffer();
  for (final r in input.toLowerCase().runes) {
    if (r >= 0x300 && r <= 0x36F) continue;
    final greek = _greek[r];
    if (greek != null) {
      out.write(greek);
      continue;
    }
    final sup = _superscriptDigits.indexOf(String.fromCharCode(r));
    if (sup >= 0) {
      out.write(sup);
      continue;
    }
    final latin = _latin[r];
    if (latin != null) {
      out.write(latin);
      continue;
    }
    if ((r >= 0x61 && r <= 0x7A) || (r >= 0x30 && r <= 0x39)) {
      out.writeCharCode(r);
    } else if (r < 0x80 || r == 0xA0) {
      out.write(' ');
    }
  }
  return out
      .toString()
      .trim()
      .split(RegExp(r'\s+'))
      .join(' ')
      .replaceAllMapped(_hrNumber, (m) => 'hr ${m[1]}');
}
