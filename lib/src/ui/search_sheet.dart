import 'package:material_ui/material_ui.dart';

import '../search/search_index.dart';
import 'theme.dart';

/// Opens the search sheet; completes with the chosen object id or null.
Future<String?> showSearchSheet(BuildContext context, SearchIndex index) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SearchSheet(index: index),
    );

IconData _icon(SearchKind kind) => switch (kind) {
  SearchKind.sun => Icons.wb_sunny_outlined,
  SearchKind.moon => Icons.brightness_3_outlined,
  SearchKind.planet => Icons.public,
  SearchKind.constellation => Icons.timeline,
  SearchKind.star => Icons.star_border,
};

class SearchSheet extends StatefulWidget {
  const SearchSheet({super.key, required this.index});

  final SearchIndex index;

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  List<SearchResult> _results = const [];
  String _query = '';

  void _onChanged(String text) => setState(() {
    _query = text;
    _results = widget.index.search(text);
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * 0.8, maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const Key('search-field'),
                  autofocus: true,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (_results.isNotEmpty) {
                      Navigator.of(context).pop(_results.first.id);
                    }
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Sirius, α Ori, 61 Cyg, HR 7001, Orion, Mars',
                  ),
                ),
              ),
              if (_query.trim().isNotEmpty && _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nothing found',
                    style: TextStyle(color: OrreryColors.muted),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(_icon(r.kind), color: OrreryColors.accent),
                      title: Text(r.title),
                      subtitle: Text(r.subtitle),
                      onTap: () => Navigator.of(context).pop(r.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
