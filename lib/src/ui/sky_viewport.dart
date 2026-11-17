import 'package:flutter/widgets.dart';

import '../sky/projection.dart';
import '../sky/sky_frame.dart';
import '../sky/sky_painter.dart';
import '../sky/sky_scene.dart';

/// Lays out and paints the sky for the space it is given.
class SkyViewport extends StatelessWidget {
  const SkyViewport({
    super.key,
    required this.scene,
    required this.field,
    required this.view,
    required this.layers,
    this.selectedId,
    this.onFrame,
  });

  final SkyScene scene;
  final StarField field;
  final SkyView view;
  final SkyLayers layers;
  final String? selectedId;

  /// Receives each laid-out frame, e.g. for hit-testing taps.
  final ValueChanged<SkyFrame>? onFrame;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = layoutFrame(
          scene: scene,
          field: field,
          view: view,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          layers: layers,
        );
        onFrame?.call(frame);
        return CustomPaint(
          size: constraints.biggest,
          painter: SkyPainter(
            scene: scene,
            frame: frame,
            layers: layers,
            selectedId: selectedId,
          ),
        );
      },
    );
  }
}
