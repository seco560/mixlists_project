import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/search/search_results_screen.dart';
import 'package:mixlists_project/widgets/shared/quick_style_page_route.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return;
    _controller.clear();
    Navigator.push(
      context,
      QuickStylePageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ValueListenableBuilder<MixlistFilter>(
          valueListenable: getIt<MixlistFilterController>(),
          builder: (context, filter, _) => TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText:
                  'Search ${filter.playlistNounPluralLower}, artists, albums, songs',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
          ),
        ),
      ),
    );
  }
}
