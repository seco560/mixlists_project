import 'package:flutter/material.dart';
import 'package:mixlists_project/screens/albums/albums_grid_screen.dart';
import 'package:mixlists_project/screens/artists/all_artists_screen.dart';
import 'package:mixlists_project/screens/home/home_nav_card.dart';
import 'package:mixlists_project/screens/home/search_field.dart';
import 'package:mixlists_project/screens/mixlists/all_mixlists_screen.dart';
import 'package:mixlists_project/screens/songs/all_songs_screen.dart';
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: .center,
                mainAxisAlignment: .center,
                children: [
                  const Text(
                    "The Mixlists Project",
                    textAlign: .center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: .bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const MixlistFilterToggle(),
                  const SizedBox(height: 8),
                  const Text(
                    'Show all playlists, only ones marked as mixlists, or '
                    'only the ones that aren\'t.',
                    textAlign: .center,
                    style: metaTextStyle,
                  ),
                  const SizedBox(height: 24),
                  const SearchField(),
                  const SizedBox(height: 32),
                  HomeNavCard(
                    icon: Icons.queue_music,
                    label: 'Mixlists',
                    onTap: () {
                      Navigator.push(
                        context,
                        QuickStylePageRoute(
                          builder: (context) => AllMixlistsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  HomeNavCard(
                    icon: Icons.person,
                    label: 'Artists',
                    onTap: () {
                      Navigator.push(
                        context,
                        QuickStylePageRoute(
                          builder: (context) => AllArtistsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  HomeNavCard(
                    icon: Icons.album,
                    label: 'Albums',
                    onTap: () {
                      Navigator.push(
                        context,
                        QuickStylePageRoute(
                          builder: (context) => AlbumsGridScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  HomeNavCard(
                    icon: Icons.music_note,
                    label: 'Songs',
                    onTap: () {
                      Navigator.push(
                        context,
                        QuickStylePageRoute(
                          builder: (context) => AllSongsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
