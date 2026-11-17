import 'package:material_ui/material_ui.dart';

import '../data/locations.dart';
import '../format/format.dart';
import '../state/sky_controller.dart';
import 'theme.dart';

/// Play speeds offered by the speed button, in simulated seconds per second.
const List<double> playSpeeds = [60, 600, 3600, 86400];

/// Time travel: the local date and time, steps of an hour or a day, a
/// time-of-day slider, a date picker and an accelerated clock.
class TimeBar extends StatefulWidget {
  const TimeBar({super.key, required this.controller});

  final SkyController controller;

  @override
  State<TimeBar> createState() => _TimeBarState();
}

class _TimeBarState extends State<TimeBar> {
  double _speed = playSpeeds[1];

  SkyController get _c => widget.controller;

  Future<void> _pickDate() async {
    final local = _c.location.localTime(_c.time);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(local.year, local.month, local.day),
      firstDate: DateTime(SkyController.minTime.year),
      lastDate: DateTime(SkyController.maxTime.year, 12, 31),
      helpText: 'Show the sky on',
    );
    if (picked == null) return;
    final newLocal = DateTime.utc(
      picked.year,
      picked.month,
      picked.day,
      local.hour,
      local.minute,
    );
    _c.setTime(newLocal.subtract(_c.location.utcOffset));
  }

  void _togglePlay() => _c.playSpeed = _c.playSpeed == 0 ? _speed : 0;

  void _nextSpeed() {
    final i = playSpeeds.indexOf(_speed);
    setState(() => _speed = playSpeeds[(i + 1) % playSpeeds.length]);
    if (_c.playSpeed != 0) _c.playSpeed = _speed;
  }

  @override
  Widget build(BuildContext context) {
    final local = _c.location.localTime(_c.time);
    final minute = local.hour * 60 + local.minute;
    final text = Theme.of(context).textTheme;
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final playback = <Widget>[
      IconButton(
        tooltip: _c.playSpeed == 0 ? 'Play' : 'Pause',
        icon: Icon(_c.playSpeed == 0 ? Icons.play_arrow : Icons.pause),
        onPressed: _togglePlay,
      ),
      TextButton(
        key: const Key('speed-button'),
        onPressed: _nextSpeed,
        child: Text(formatSpeed(_speed)),
      ),
    ];
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: narrow
                                  ? formatShortDate(local)
                                  : formatDate(local),
                              style: text.titleSmall,
                            ),
                            TextSpan(
                              text: '  ${formatClock(local)}',
                              style: text.titleSmall?.copyWith(
                                color: OrreryColors.accent,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (!narrow)
                              TextSpan(
                                text:
                                    '  ${formatUtcOffset(_c.location.utcOffset)}',
                                style: text.bodySmall?.copyWith(
                                  color: OrreryColors.muted,
                                ),
                              ),
                          ],
                        ),
                        key: const Key('time-label'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              // Phones move playback up so the slider keeps a usable width.
              if (narrow) ...playback,
              if (_c.isLive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'LIVE',
                    style: text.labelSmall?.copyWith(
                      color: OrreryColors.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
              else
                TextButton(onPressed: _c.resetToNow, child: const Text('Now')),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Back one day',
                icon: const Icon(Icons.keyboard_double_arrow_left),
                onPressed: () => _c.shiftTime(const Duration(days: -1)),
              ),
              IconButton(
                tooltip: 'Back one hour',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _c.shiftTime(const Duration(hours: -1)),
              ),
              Expanded(
                child: Slider(
                  key: const Key('time-of-day-slider'),
                  value: minute.toDouble(),
                  max: 1439,
                  label: formatClock(local),
                  semanticFormatterCallback: (v) =>
                      'Local time ${formatClock(DateTime.utc(2000, 1, 1, v ~/ 60, v.round() % 60))}',
                  onChanged: (v) => _c.setLocalMinuteOfDay(v.round()),
                ),
              ),
              IconButton(
                tooltip: 'Forward one hour',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _c.shiftTime(const Duration(hours: 1)),
              ),
              IconButton(
                tooltip: 'Forward one day',
                icon: const Icon(Icons.keyboard_double_arrow_right),
                onPressed: () => _c.shiftTime(const Duration(days: 1)),
              ),
              if (!narrow) ...playback,
            ],
          ),
        ],
      ),
    );
  }
}
