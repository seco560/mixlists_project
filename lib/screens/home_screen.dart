import 'package:flutter/material.dart';
import 'package:mixlists_project/screens/all_albums_screen.dart';
import 'package:mixlists_project/screens/all_artists_screen.dart';
import 'package:mixlists_project/screens/all_mixlists_screen.dart';
import 'package:mixlists_project/screens/search_results_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .spaceEvenly,
          children: [
            Text(
              "The Mixlists Project",
              style: TextStyle(
                fontSize: 48,
                fontWeight: .bold,
                color: Colors.blueGrey,
              ),
            ),
            const _SearchField(),
            Row(
              mainAxisAlignment: .spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllMixlistsScreen(),
                      ),
                    );
                  },
                  child: Text("View All Mixlists"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllArtistsScreen(),
                      ),
                    );
                  },
                  child: Text("View All Artists"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllAlbumsScreen(),
                      ),
                    );
                  },
                  child: Text("View All Albums"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
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
      MaterialPageRoute(
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
