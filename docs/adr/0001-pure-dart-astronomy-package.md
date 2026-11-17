# 1. Astronomy lives in a pure-Dart package

Status: accepted, November 2026

## Context

The app needs time scales, coordinate transforms, solar, lunar and planetary
positions and rise/set times. These are numerical algorithms with published
reference values (Meeus's worked examples). Flutter widget tests run inside a
fake binding and are slower to iterate on than plain Dart tests, and Flutter
types (`Offset`, `Color`) would leak into code that has nothing to do with
drawing.

## Decision

All astronomy and the catalog codec live in `packages/astro`, a Dart package
with no Flutter dependency, its own lint set (including
`public_member_api_docs`) and its own tests run with `dart test`. The app
depends on it by path. Inside the app, the code that turns a scene into screen
geometry (`lib/src/sky/projection.dart`, `sky_scene.dart`, `sky_frame.dart`)
also avoids Flutter types, so only the painter and widgets touch `dart:ui`.

## Consequences

- The Meeus examples run as ordinary unit tests in about a second, and the
  accuracy report (`tool/accuracy_report.dart`) uses the same functions.
- The catalog build tool runs with `dart run` on any machine without a
  Flutter device.
- Two analyzers and two test commands in CI instead of one.
- Geometry that the painter needs (label boxes, segments) is defined twice
  in spirit: as plain Dart classes in `sky_frame.dart` and as Flutter calls
  in `sky_painter.dart`. The duplication is small and keeps layout testable
  without rendering.
