# 3. Draw the sky with a stereographic projection

Status: accepted, November 2026

## Context

A planetarium view maps directions on the celestial sphere to a flat screen
whose field of view ranges from a few degrees to more than a hemisphere. The
gnomonic (rectilinear) projection keeps great circles straight but stretches
without bound towards 90° from the centre, so it cannot show the whole sky.
The equidistant azimuthal projection handles wide fields but distorts shapes
near the edge, which makes familiar constellations hard to recognise.

## Decision

`lib/src/sky/projection.dart` uses the stereographic projection centred on
the view direction: a direction at angle θ from the centre lands at radius
2·tan(θ/2), scaled so that half the field of view reaches the edge of the
shorter screen side. The view is seen from inside the sphere, so east is to
the right when facing north.

## Consequences

- The projection is conformal: Orion keeps its shape at the edge of a 120°
  view, and it handles fields up to 200° (the app's limit).
- Every circle on the sphere projects to a circle. The horizon is therefore
  drawn as one exact circle (or, when it passes through the centre, a line),
  and the ground is the inside or the outside of that circle depending on
  whether the view centre is below the horizon. No polygon sampling is needed.
- The inverse is closed-form, so taps and drags map back to directions
  exactly; a seeded property test checks round trips for 500 random points.
- Area is not preserved: stars near the edge of a very wide view sit further
  apart than at the centre. Star sizes depend on magnitude only, not position.
