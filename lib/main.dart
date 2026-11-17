import 'package:material_ui/material_ui.dart';

import 'src/app.dart';
import 'src/data/sky_link.dart';

void main() {
  // On the web the page URL can carry a shared view (see SkyLink); on
  // Android and iOS Uri.base has no query and the link is empty.
  runApp(OrreryApp(link: SkyLink.parse(Uri.base)));
}
