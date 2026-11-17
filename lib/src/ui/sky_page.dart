import 'dart:async';

import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../data/catalog_loader.dart';
import '../data/sky_link.dart';
import '../format/format.dart';
import '../sky/projection.dart';
import '../sky/sky_scene.dart';
import '../state/sky_controller.dart';
import 'location_sheet.dart';
import 'night_mode.dart';
import 'sky_canvas.dart';
import 'theme.dart';
import 'time_bar.dart';

/// Loads the catalogue, then shows the interactive sky.
class SkyPage extends StatefulWidget {
  const SkyPage({
    super.key,
    required this.loader,
    this.clock,
    this.link = const SkyLink(),
  });

  final CatalogLoader loader;
  final DateTime Function()? clock;
  final SkyLink link;

  @override
  State<SkyPage> createState() => _SkyPageState();
}

class _SkyPageState extends State<SkyPage> {
  late final Future<SkyCatalog> _catalog = widget.loader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<SkyCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CatalogError(error: snapshot.error!);
          }
          final catalog = snapshot.data;
          if (catalog == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SkyScreen(
            catalog: catalog,
            clock: widget.clock,
            link: widget.link,
          );
        },
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final detail = e is FormatException ? e.message : '$e';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load the star catalog',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// The sky with its overlays, once the catalogue is available.
class SkyScreen extends StatefulWidget {
  const SkyScreen({
    super.key,
    required this.catalog,
    this.clock,
    this.link = const SkyLink(),
  });

  final SkyCatalog catalog;
  final DateTime Function()? clock;
  final SkyLink link;

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen>
    with SingleTickerProviderStateMixin {
  late final SkyController _controller;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    final link = widget.link;
    _controller = SkyController(
      field: StarField(widget.catalog),
      clock: widget.clock,
      location: link.location,
      view: SkyView(
        centerAzDeg: link.azDeg ?? 180,
        centerAltDeg: link.altDeg ?? 40,
        fovDeg: link.fovDeg ?? 100,
      ),
    );
    final time = link.time;
    if (time != null) _controller.setTime(time);
    if (link.select != null) _controller.select(link.select);
    if (link.night == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) NightModeScope.of(context).value = true;
      });
    }
    _ticker = createTicker(_onTick);
    _controller.addListener(_syncTicker);
    _liveTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _controller.tick(),
    );
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    _controller.advance(delta);
  }

  void _syncTicker() {
    final playing = _controller.playSpeed != 0;
    if (playing && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!playing && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(child: SkyCanvas(controller: _controller)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _TopBar(controller: _controller),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ViewInfo(controller: _controller),
                        const SizedBox(height: 8),
                        TimeBar(controller: _controller),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final SkyController controller;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 560;
    return Row(
      children: [
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OrreryMark(size: 24),
              if (wide) ...[
                const SizedBox(width: 10),
                Text(
                  'Orrery Sky Atlas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Panel(
            padding: EdgeInsets.zero,
            child: TextButton.icon(
              key: const Key('location-button'),
              onPressed: () => showLocationSheet(context, controller),
              icon: const Icon(Icons.place_outlined, size: 18),
              label: Text(
                controller.location.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewInfo extends StatelessWidget {
  const _ViewInfo({required this.controller});

  final SkyController controller;

  @override
  Widget build(BuildContext context) {
    final v = controller.view;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: OrreryColors.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Panel(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Facing ${compassPoint(v.centerAzDeg)} '
            '${normalizeDegrees(v.centerAzDeg).round()}°  ·  '
            'altitude ${v.centerAltDeg.round()}°  ·  '
            'field ${v.fovDeg.round()}°',
            style: style,
          ),
          IconButton(
            tooltip: 'Zoom out',
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => controller.zoomBy(0.8),
          ),
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => controller.zoomBy(1.25),
          ),
        ],
      ),
    );
  }
}
