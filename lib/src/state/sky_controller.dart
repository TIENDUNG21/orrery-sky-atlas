import 'package:astro/astro.dart';
import 'package:flutter/foundation.dart';

import '../data/locations.dart';
import '../sky/projection.dart';
import '../sky/sky_frame.dart';
import '../sky/sky_scene.dart';

/// The app's state: when and where the sky is seen, how it is viewed, and
/// what is selected. Widgets listen to it; the scene is recomputed only when
/// the instant or the place changes.
class SkyController extends ChangeNotifier {
  SkyController({
    required this.field,
    DateTime Function()? clock,
    Location? location,
    SkyView? view,
  }) : _clock = clock ?? DateTime.now,
       _location = location ?? locationPresets.first,
       _view =
           view ??
           const SkyView(centerAzDeg: 180, centerAltDeg: 40, fovDeg: 100) {
    _time = _clamp(_clock().toUtc());
  }

  /// First and last instants covered by the planetary elements.
  static final DateTime minTime = DateTime.utc(1800);
  static final DateTime maxTime = DateTime.utc(2050, 12, 31, 23, 59);
  static const double minFovDeg = 5;
  static const double maxFovDeg = 200;

  final StarField field;
  final DateTime Function() _clock;

  late DateTime _time;
  bool _live = true;
  Location _location;
  SkyView _view;
  SkyLayers _layers = SkyLayers.all;
  String? _selectedId;
  SkyScene? _scene;

  double _playSpeed = 0;

  /// Simulated seconds per real second while playing; 0 when paused.
  double get playSpeed => _playSpeed;
  set playSpeed(double value) {
    _playSpeed = value;
    notifyListeners();
  }

  DateTime get time => _time;

  /// Whether the sky follows the real clock.
  bool get isLive => _live;
  Location get location => _location;
  SkyView get view => _view;
  SkyLayers get layers => _layers;
  String? get selectedId => _selectedId;

  SkyScene get scene => _scene ??= computeScene(
    field,
    AstroTime.fromDateTime(_time),
    _location.observer,
  );

  DateTime _clamp(DateTime t) {
    if (t.isBefore(minTime)) return minTime;
    if (t.isAfter(maxTime)) return maxTime;
    return t;
  }

  void _setTime(DateTime t, {required bool live}) {
    _time = _clamp(t.toUtc());
    _live = live;
    _scene = null;
    notifyListeners();
  }

  void setTime(DateTime t) => _setTime(t, live: false);

  void shiftTime(Duration d) => _setTime(_time.add(d), live: false);

  void resetToNow() {
    _playSpeed = 0;
    _setTime(_clock(), live: true);
  }

  /// Follows the real clock while live (called periodically by the UI).
  void tick() {
    if (_live) _setTime(_clock(), live: true);
  }

  /// Advances simulated time by [realElapsed] × [playSpeed].
  void advance(Duration realElapsed) {
    if (_playSpeed == 0) return;
    final ms = (realElapsed.inMicroseconds * _playSpeed / 1000).round();
    _setTime(_time.add(Duration(milliseconds: ms)), live: false);
  }

  /// Moves to [minute] after local midnight on the current local date.
  void setLocalMinuteOfDay(int minute) {
    final local = _location.localTime(_time);
    final midnight = DateTime.utc(local.year, local.month, local.day);
    _setTime(
      midnight.add(Duration(minutes: minute)).subtract(_location.utcOffset),
      live: false,
    );
  }

  void setLocation(Location location) {
    _location = location;
    _scene = null;
    notifyListeners();
  }

  /// Turns the view; positive [dAzDeg] looks further east, positive
  /// [dAltDeg] looks higher.
  void pan(double dAzDeg, double dAltDeg) {
    _view = _view.copyWith(
      centerAzDeg: normalizeDegrees(_view.centerAzDeg + dAzDeg),
      centerAltDeg: (_view.centerAltDeg + dAltDeg).clamp(-90.0, 90.0),
    );
    notifyListeners();
  }

  /// Zooms in by [factor] (values above 1 narrow the field).
  void zoomBy(double factor) {
    if (!(factor > 0)) return;
    _view = _view.copyWith(
      fovDeg: (_view.fovDeg / factor).clamp(minFovDeg, maxFovDeg),
    );
    notifyListeners();
  }

  /// Centres the view on [target], optionally changing the field of view.
  void lookAt(Horizontal target, {double? fovDeg}) {
    _view = SkyView(
      centerAzDeg: target.azDeg,
      centerAltDeg: target.altDeg.clamp(-90.0, 90.0),
      fovDeg: (fovDeg ?? _view.fovDeg).clamp(minFovDeg, maxFovDeg),
    );
    notifyListeners();
  }

  void select(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  void setLayers(SkyLayers layers) {
    _layers = layers;
    notifyListeners();
  }
}
