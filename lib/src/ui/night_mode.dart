import 'package:flutter/widgets.dart';

/// Whether the red night mode is on. Lives above the navigator so that the
/// filter also covers sheets and dialogs.
class NightModeController extends ValueNotifier<bool> {
  NightModeController([super.value = false]);

  void toggle() => value = !value;
}

/// Makes the [NightModeController] available to the widget tree.
class NightModeScope extends InheritedNotifier<NightModeController> {
  const NightModeScope({
    super.key,
    required NightModeController controller,
    required super.child,
  }) : super(notifier: controller);

  static NightModeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NightModeScope>()!.notifier!;
}

/// Maps every colour to its luminance in the red channel only. Red light
/// keeps the eye dark-adapted at the telescope.
const List<double> nightModeMatrix = [
  0.299, 0.587, 0.114, 0, 0, //
  0, 0, 0, 0, 0,
  0, 0, 0, 0, 0,
  0, 0, 0, 1, 0,
];

/// Applies [nightModeMatrix] to [child] while night mode is on.
class NightFilter extends StatelessWidget {
  const NightFilter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final night = NightModeScope.of(context).value;
    return ColorFiltered(
      colorFilter: night
          ? const ColorFilter.matrix(nightModeMatrix)
          : const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
      child: child,
    );
  }
}
