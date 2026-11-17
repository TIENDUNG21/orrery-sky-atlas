# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-11-17

First release.

### Added

- `packages/astro`: Julian dates and calendar conversion, ΔT, mean and
  apparent sidereal time, four-term nutation, precession from J2000 and
  proper motion, equatorial, ecliptic and horizontal transforms, refraction,
  topocentric parallax, the Sun (Meeus 25), the Moon (Meeus 47, full tables
  47.A and 47.B), lunar illumination, bright-limb angle and phase search,
  Kepler's equation, planets from JPL approximate elements with magnitudes,
  and rise, transit and set (Meeus 15). Tested against the worked examples
  listed in `docs/ACCURACY.md`.
- Catalog pipeline: BSC5 parser, constellation-line reader, star-name
  resolution, and the checksummed binary format `ORSK` v1. `tool/fetch_data.dart`
  pins the raw downloads by SHA-256; `tool/build_catalog.dart` writes
  `assets/catalog/sky.bin` (9096 stars, 163 names, 88 constellations).
- Sky view: stereographic projection, stars sized by magnitude and coloured
  by B−V, constellation figures and names, the Sun, the Moon with its phase
  and bright-limb orientation, planets, horizon and ground, altitude-azimuth
  grid, compass points, labels that never overlap, twilight sky colour.
- Interaction: drag, pinch, mouse wheel and keyboard navigation, tap to
  identify, time travel (hour and day steps, time-of-day slider, date picker,
  playback up to 24 hours per second), 14 location presets and validated
  custom coordinates, search by name, Bayer, Flamsteed or HR number, detail
  sheets with local rise and set times, layer toggles, red night mode, credits.
- Web sky links (`?t=…&loc=…&az=…&alt=…&fov=…&night=1&select=…`).
- CI: format, analyzers, tests, web build with sub-path check, release APK
  artifact. GitHub Pages deployment of the web build.

[1.0.0]: https://github.com/TIENDUNG21/orrery-sky-atlas/releases/tag/v1.0.0
