import 'package:material_ui/material_ui.dart';

import '../data/coordinate_input.dart';
import '../data/locations.dart';
import '../state/sky_controller.dart';
import 'theme.dart';

/// Opens the place picker.
Future<void> showLocationSheet(
  BuildContext context,
  SkyController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => LocationSheet(controller: controller),
);

String _coordinates(Location l) {
  final ns = l.latitudeDeg < 0 ? 'S' : 'N';
  final ew = l.longitudeDeg < 0 ? 'W' : 'E';
  return '${l.latitudeDeg.abs().toStringAsFixed(2)}° $ns, '
      '${l.longitudeDeg.abs().toStringAsFixed(2)}° $ew · '
      '${formatUtcOffset(l.utcOffset)}';
}

/// Presets plus a form for any coordinates.
class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key, required this.controller});

  final SkyController controller;

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  late final _lat = TextEditingController(
    text: widget.controller.location.latitudeDeg.toStringAsFixed(4),
  );
  late final _lon = TextEditingController(
    text: widget.controller.location.longitudeDeg.toStringAsFixed(4),
  );
  late final _tz = TextEditingController(
    text: formatUtcOffset(widget.controller.location.utcOffset)
        .replaceFirst('UTC', '')
        .replaceAll('−', '-'),
  );
  String? _latError;
  String? _lonError;
  String? _tzError;

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    _tz.dispose();
    super.dispose();
  }

  String? _check(void Function() parse) {
    try {
      parse();
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  void _apply() {
    setState(() {
      _latError = _check(() => parseCoordinate(_lat.text, latitude: true));
      _lonError = _check(() => parseCoordinate(_lon.text, latitude: false));
      _tzError = _tz.text.trim().isEmpty
          ? null
          : _check(() => parseUtcOffset(_tz.text));
    });
    if (_latError != null || _lonError != null || _tzError != null) return;
    widget.controller.setLocation(
      Location.custom(
        latitudeDeg: parseCoordinate(_lat.text, latitude: true),
        longitudeDeg: parseCoordinate(_lon.text, latitude: false),
        utcOffset: _tz.text.trim().isEmpty
            ? Duration.zero
            : parseUtcOffset(_tz.text),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.location;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            maxWidth: 560,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text('Location', style: text.titleLarge),
              const SizedBox(height: 8),
              for (final place in locationPresets)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(place.name),
                  subtitle: Text(_coordinates(place)),
                  trailing: place.slug == current.slug
                      ? const Icon(Icons.check, color: OrreryColors.accent)
                      : null,
                  onTap: () {
                    widget.controller.setLocation(place);
                    Navigator.of(context).pop();
                  },
                ),
              const Divider(height: 32),
              Text('Custom coordinates', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Decimal degrees or degrees minutes seconds, e.g. 21.0285 N '
                'or 105°51′15″ E. The offset is standard time (no daylight '
                'saving).',
                style: text.bodySmall?.copyWith(color: OrreryColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('latitude-field'),
                controller: _lat,
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  errorText: _latError,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('longitude-field'),
                controller: _lon,
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  errorText: _lonError,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('utc-offset-field'),
                controller: _tz,
                decoration: InputDecoration(
                  labelText: 'UTC offset (hours)',
                  errorText: _tzError,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const Key('apply-custom-location'),
                  onPressed: _apply,
                  child: const Text('Use these coordinates'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
