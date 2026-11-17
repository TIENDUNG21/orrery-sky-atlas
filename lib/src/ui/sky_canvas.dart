import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../sky/hit_test.dart';
import '../sky/sky_frame.dart';
import '../state/sky_controller.dart';
import 'sky_viewport.dart';

/// The interactive sky: drag to look around, pinch or scroll to zoom, tap
/// to pick an object, arrow keys and +/− on a keyboard.
class SkyCanvas extends StatefulWidget {
  const SkyCanvas({super.key, required this.controller, this.onPicked});

  final SkyController controller;

  /// Called with the tapped object's id, or null for empty sky.
  final ValueChanged<String?>? onPicked;

  @override
  State<SkyCanvas> createState() => _SkyCanvasState();
}

class _SkyCanvasState extends State<SkyCanvas> {
  SkyFrame? _frame;
  double _lastScale = 1;

  SkyController get _c => widget.controller;

  double get _degreesPerPixel => 1 / (_frame?.projection.pixelsPerDegree ?? 10);

  void _onScaleStart(ScaleStartDetails details) => _lastScale = 1;

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final d = details.focalPointDelta;
    if (d != Offset.zero) {
      // The sky follows the finger: dragging right turns the view west.
      _c.pan(-d.dx * _degreesPerPixel, d.dy * _degreesPerPixel);
    }
    if (details.pointerCount > 1 && details.scale > 0) {
      _c.zoomBy(details.scale / _lastScale);
      _lastScale = details.scale;
    }
  }

  void _onTapUp(TapUpDetails details) {
    final frame = _frame;
    if (frame == null) return;
    final p = details.localPosition;
    final id = pickObject(frame.hitCandidates, p.dx, p.dy);
    _c.select(id);
    widget.onPicked?.call(id);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _c.zoomBy(math.exp(-event.scrollDelta.dy / 400));
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = _c.view.fovDeg / 12;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _c.pan(-step, 0);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _c.pan(step, 0);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _c.pan(0, step);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _c.pan(0, -step);
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      _c.zoomBy(1.25);
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _c.zoomBy(0.8);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onTapUp: _onTapUp,
          child: SkyViewport(
            scene: _c.scene,
            field: _c.field,
            view: _c.view,
            layers: _c.layers,
            selectedId: _c.selectedId,
            onFrame: (frame) => _frame = frame,
          ),
        ),
      ),
    );
  }
}
