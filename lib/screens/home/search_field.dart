import 'package:flutter/material.dart';
import 'package:mixlists_project/screens/search/search_results_screen.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';

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
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search mixlists, artists, albums, songs',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
        ),
      ),
    );
  }
}
