/// A place on Earth from which the sky is observed.
library;

/// Geographic position of an observer. Longitude is east-positive.
class Observer {
  /// Creates an observer; throws [ArgumentError] outside the globe or for NaN.
  Observer({required this.latitudeDeg, required this.longitudeDeg}) {
    if (!(latitudeDeg >= -90 && latitudeDeg <= 90)) {
      throw ArgumentError.value(
        latitudeDeg,
        'latitudeDeg',
        'must be in [-90, 90]',
      );
    }
    if (!(longitudeDeg >= -180 && longitudeDeg <= 180)) {
      throw ArgumentError.value(
        longitudeDeg,
        'longitudeDeg',
        'must be in [-180, 180]',
      );
    }
  }

  /// Geodetic latitude in degrees, north positive.
  final double latitudeDeg;

  /// Longitude in degrees, east positive.
  final double longitudeDeg;

  @override
  String toString() => 'Observer($latitudeDeg, $longitudeDeg)';
}
