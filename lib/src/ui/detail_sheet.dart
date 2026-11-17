import 'package:astro/catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../details/object_details.dart';
import '../state/sky_controller.dart';
import 'theme.dart';

/// Shows facts about the selected object. The sheet listens to the
/// controller, so its altitude and times follow time travel.
Future<void> showDetailSheet(
  BuildContext context,
  SkyController controller,
  SkyCatalog catalog,
  String id,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  barrierColor: const Color(0x33000000),
  builder: (_) => DetailSheet(controller: controller, catalog: catalog, id: id),
);

class DetailSheet extends StatelessWidget {
  const DetailSheet({
    super.key,
    required this.controller,
    required this.catalog,
    required this.id,
  });

  final SkyController controller;
  final SkyCatalog catalog;
  final String id;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final details = describeObject(
          id,
          scene: controller.scene,
          catalog: catalog,
          location: controller.location,
        );
        if (details == null) return const SizedBox.shrink();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
              maxWidth: 560,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(details.title, style: text.headlineSmall),
                          Text(
                            details.subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: OrreryColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => controller.focusOn(id),
                      icon: const Icon(Icons.center_focus_strong, size: 18),
                      label: const Text('Centre'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final row in details.rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            row.label,
                            style: text.bodyMedium?.copyWith(
                              color: OrreryColors.muted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.value,
                            style: text.bodyMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
