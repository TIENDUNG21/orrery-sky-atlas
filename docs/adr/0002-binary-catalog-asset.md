# 2. Ship the star catalog as a checksummed binary asset

Status: accepted, November 2026

## Context

The Yale Bright Star Catalogue (BSC5) is a 197-byte fixed-width record per
star, about 1.8 MB uncompressed for 9110 entries, most of which the app never
reads (B1900 positions, galactic coordinates, multiplicity codes). The
constellation figures come from a separate file keyed by HR number, and star
names from a list written for this project. The app needs all three joined,
loaded on a phone and in a browser, and must not crash on a damaged download.

## Decision

`tool/build_catalog.dart` parses the raw files once and writes
`assets/catalog/sky.bin` (format "ORSK", version 1, documented in
`packages/astro/lib/src/catalog/codec.dart`):

- positions as integers at catalog precision (right ascension in 0.1 s of
  time, declination in arcseconds), so decoding reproduces the source exactly;
- proper motion and parallax in milliarcseconds, magnitudes and B−V in
  hundredths, as 16-bit integers with an explicit "missing" value;
- designations as small integers (Flamsteed number, Bayer letter index,
  superscript, constellation index) instead of strings;
- the constellation table and the figure polylines in the same file;
- a CRC-32 over everything, checked before parsing.

The raw downloads stay in `.cache/downloads/` (gitignored) and
`tool/fetch_data.dart` verifies them against pinned SHA-256 digests.

## Consequences

- 286,143 bytes for 9096 stars, 163 names, 88 constellations and 750 figure
  segments; decoding takes 1.65 ms on the Dart VM (see
  `tool/bench_scene.dart`).
- A truncated or altered file fails with a `FormatException` naming the
  problem (bad magic, unsupported version, truncation, checksum), and the app
  shows that message instead of an empty sky.
- Changing the format means bumping the version and rebuilding the asset.
  The asset is committed, so a fresh clone does not need network access to
  run.
