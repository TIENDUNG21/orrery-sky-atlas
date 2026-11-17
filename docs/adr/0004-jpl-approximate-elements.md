# 4. Planets from JPL's approximate Keplerian elements

Status: accepted, November 2026

## Context

Meeus computes planetary positions with a truncated VSOP87 series: several
thousand coefficients for the eight planets. A full ephemeris (DE440) is far
larger. The app shows planets as dots on a sky where one pixel is a few
arcminutes at typical zoom levels.

## Decision

Use the element table of E. M. Standish, "Keplerian Elements for Approximate
Positions of the Major Planets" (JPL Solar System Dynamics), table 1, valid
1800 to 2050: six elements and their rates per century for each planet and
the Earth-Moon barycentre. Positions are reduced to apparent geocentric
coordinates following Meeus: light-time iteration, precession from J2000,
nutation in longitude and annual aberration. Earth is recovered from the
barycentre with the Moon's position and the Earth/Moon mass ratio.

## Consequences

- The whole planetary theory is 8 rows of 12 numbers. Against Meeus's
  example 33.a (Venus, VSOP87) the result differs by 6.2″ in right ascension
  and 2.0″ in declination; the 2003 close approach of Mars comes out on the
  right day at 0.3727 AU.
- The app clamps time travel to 1800–2050. Extending the range would need
  JPL's table 2 (3000 BC to 3000 AD) with its extra terms for the outer
  planets, at a few times the error.
- Planetary magnitudes use the Astronomical Almanac expressions quoted by
  Meeus (chapter 41), including Saturn's ring tilt from chapter 45.
